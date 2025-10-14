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
