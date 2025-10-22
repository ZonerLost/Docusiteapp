import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();
const db = getFirestore();
const messaging = getMessaging();

/* =========================================
   🔔 1. Send Project Invitation Notification
========================================= */
export const sendProjectInviteNotification = onDocumentCreated(
  "pending_requests/{inviteeEmail}/requests/{inviteId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const inviteData = snap.data();
    const inviteeEmail = event.params.inviteeEmail;
    const projectId = inviteData.projectId;
    const inviterUid = inviteData.invitedBy;
    const role = inviteData.role || "Member";

    try {
      const projectDoc = await db.collection("projects").doc(projectId).get();
      if (!projectDoc.exists) return;
      const projectTitle = projectDoc.data().title || "a project";

      const inviterDoc = await db.collection("users").doc(inviterUid).get();
      if (!inviterDoc.exists) return;
      const inviterName =
        inviterDoc.data().displayName ||
        inviterDoc.data().email ||
        "Someone";

      const inviteeQuery = await db
        .collection("users")
        .where("email", "==", inviteeEmail)
        .limit(1)
        .get();
      if (inviteeQuery.empty) return;
      const inviteeDoc = inviteeQuery.docs[0];
      const fcmToken = inviteeDoc.data().fcmToken;

      const notificationRef = db
        .collection("notifications")
        .doc(inviteeEmail)
        .collection("items")
        .doc();

      await notificationRef.set({
        title: "New Project Invitation",
        subTitle: `${inviterName} is inviting you to collaborate in "${projectTitle}" as ${role}. Tap to view.`,
        time: FieldValue.serverTimestamp(),
        unread: true,
        type: "project_invite",
        projectId: projectId,
        inviteId: event.params.inviteId,
      });

      if (fcmToken) {
        const message = {
          notification: {
            title: "New Project Invitation",
            body: `${inviterName} invited you to "${projectTitle}" as ${role}.`,
          },
          data: {
            type: "project_invite",
            projectId,
            inviteId: event.params.inviteId,
            inviterName,
            projectTitle,
          },
          token: fcmToken,
        };

        await messaging.send(message);
        console.log(`✅ Notification sent to ${inviteeEmail}`);
      } else {
        console.log(`⚠️ No FCM token for ${inviteeEmail}`);
      }
    } catch (error) {
      console.error("🔥 Error processing invite notification:", error);
    }
  }
);

/* =========================================
   📁 2. Send Notification When New PDF Added
========================================= */
export const sendNewPdfNotification = onDocumentUpdated(
  "projects/{projectId}",
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();
    if (!beforeData || !afterData) return;

    const beforeFiles = beforeData.files || [];
    const afterFiles = afterData.files || [];
    if (afterFiles.length <= beforeFiles.length) return;

    // Find newly added file
    const newFile = afterFiles.find(
      (file) => !beforeFiles.some((f) => f.fileUrl === file.fileUrl)
    );
    if (!newFile) return;

    const projectId = event.params.projectId;
    const projectTitle = afterData.title || "Project";
    const collaborators = afterData.collaborators || [];

    try {
      const tokens = [];
      for (const c of collaborators) {
        const userDoc = await db.collection("users").doc(c.uid).get();
        const token = userDoc.data()?.fcmToken;
        if (token) tokens.push(token);
      }

      if (tokens.length === 0) {
        console.log("⚠️ No FCM tokens found for collaborators.");
        return null;
      }

      const message = {
        notification: {
          title: "New PDF Added",
          body: `${newFile.fileName} was added to "${projectTitle}"`,
        },
        data: {
          type: "pdf_added",
          projectId,
          fileName: newFile.fileName,
        },
        tokens,
      };

      await messaging.sendEachForMulticast(message);
      console.log(`✅ Notification sent for new file: ${newFile.fileName}`);
    } catch (error) {
      console.error("🔥 Error sending PDF notification:", error);
    }
  }
);


export const sendProjectUpdateNotification = onDocumentUpdated(
  "projects/{projectId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const projectId = event.params.projectId;
    const projectTitle = after.title || "Project";
    const collaborators = after.collaborators || [];

    // Ignore updates that are only related to project invitations
    // (because handled in sendProjectInviteNotification)
    if (JSON.stringify(before.pending_requests) !== JSON.stringify(after.pending_requests)) {
      console.log("⚠️ Skipping invite-related update.");
      return;
    }

    // --- CASE 1: New PDF Added ---
    const beforeFiles = before.files || [];
    const afterFiles = after.files || [];
    if (afterFiles.length > beforeFiles.length) {
      const newFile = afterFiles.find(
        (file) => !beforeFiles.some((f) => f.fileUrl === file.fileUrl)
      );
      if (newFile) {
        await sendNotificationToCollaborators({
          tokens: await getCollaboratorTokens(collaborators),
          title: "New PDF Added",
          body: `${newFile.fileName} was added to "${projectTitle}"`,
          data: {
            type: "pdf_added",
            projectId,
            fileName: newFile.fileName,
          },
        });
        return;
      }
    }

    // --- CASE 2: Other Project Field Changes ---
    const changedFields = Object.keys(after).filter(
      (key) =>
        !["files", "lastUpdates", "updatedAt"].includes(key) &&
        JSON.stringify(before[key]) !== JSON.stringify(after[key])
    );

    if (changedFields.length === 0) {
      console.log("ℹ️ No significant changes detected.");
      return;
    }

    const tokens = await getCollaboratorTokens(collaborators);
    if (tokens.length === 0) {
      console.log("⚠️ No collaborator FCM tokens found.");
      return;
    }

    // Make human-readable change summary
    const readableChanges =
      changedFields.length > 3
        ? `${changedFields.length} fields`
        : changedFields.join(", ");

    await sendNotificationToCollaborators({
      tokens,
      title: "Project Updated",
      body: `Changes made in "${projectTitle}" (${readableChanges})`,
      data: {
        type: "project_updated",
        projectId,
        changedFields: JSON.stringify(changedFields),
      },
    });

    console.log(`✅ Update notification sent for ${projectTitle}`);
  }
);

// Utility: Get collaborator FCM tokens (respects notificationsEnabled)
async function getCollaboratorTokens(collaborators) {
  const tokens = [];
  for (const c of collaborators) {
    if (!c || !c.uid) continue;
    const userDoc = await db.collection("users").doc(c.uid).get();
    if (!userDoc.exists) continue;
    const u = userDoc.data() || {};
    if (u.notificationsEnabled === false) continue; // opted out
    const t = u.fcmToken;
    if (t && typeof t === "string" && t.length > 0) tokens.push(t);
  }
  return tokens;
}


// Utility: Send FCM multicast message
async function sendNotificationToCollaborators({ tokens, title, body, data }) {
  if (!tokens || tokens.length === 0) return;
  const message = {
    notification: { title, body },
    data,
    tokens,
  };
  await messaging.sendEachForMulticast(message);
}


/* =========================================
   💬 4. Send Notification on New Chat Message
========================================= */
export const sendChatMessageNotification = onDocumentCreated(
  "projects/{projectId}/group_chat/metadata/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const msg = snap.data() || {};
    const projectId = event.params.projectId;
    const messageId = event.params.messageId;

    const senderUid = msg.userId;
    const senderName = msg.userName || msg.sentBy || "Someone";
    const rawText = (msg.message || "").toString();
    const preview = rawText.length > 80 ? rawText.slice(0, 77) + "..." : rawText;

    try {
      // 1) Get project (title + collaborators)
      const projectDoc = await db.collection("projects").doc(projectId).get();
      if (!projectDoc.exists) return;
      const projectData = projectDoc.data() || {};
      const projectTitle = projectData.title || "Project";
      const collaborators = projectData.collaborators || [];

      // 2) Recipients (exclude sender)
      const recipients = collaborators.filter(function (c) {
        return c && c.uid && c.uid !== senderUid;
      });

      if (recipients.length === 0) {
        console.log("ℹ️ No recipients (only sender or none).");
        return;
      }

      // 3) Collect tokens and recipient emails
      const tokens = [];
      const recipientInfos = []; // { uid, email }

      for (const r of recipients) {
        const uid = r.uid;
        let email = r.email;

        const userDoc = await db.collection("users").doc(uid).get();
        const udata = userDoc.data() || {};
        const tkn = udata.fcmToken;
        if (!email) email = udata.email;

        if (email) recipientInfos.push({ uid: uid, email: email });
        if (tkn) tokens.push(tkn);
      }

      // 4) Write in-app notifications
      const batch = db.batch();
      for (const r of recipientInfos) {
        const notifRef = db
          .collection("notifications")
          .doc(r.email)
          .collection("items")
          .doc();

        batch.set(notifRef, {
          title: "New message in \"" + projectTitle + "\"",
          subTitle: senderName + ": " + (preview || "(attachment)"),
          time: FieldValue.serverTimestamp(),
          unread: true,
          type: "chat_message",
          projectId: projectId,
          messageId: messageId,
          senderUid: senderUid,
        });
      }
      await batch.commit();

      // 5) Push notifications
      if (tokens.length > 0) {
        await messaging.sendEachForMulticast({
          notification: {
            title: "New message in \"" + projectTitle + "\"",
            body: senderName + ": " + (preview || "(attachment)"),
          },
          data: {
            type: "chat_message",
            projectId: projectId,
            messageId: messageId,
            senderUid: senderUid,
            projectTitle: projectTitle,
          },
          tokens: tokens,
        });
        console.log(
          "✅ Chat notification sent to " +
            String(recipientInfos.length) +
            " collaborators."
        );
      } else {
        console.log("⚠️ No FCM tokens for chat recipients.");
      }
    } catch (error) {
      console.error("🔥 Error sending chat message notification:", error);
    }
  }
);
