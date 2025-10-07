import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:docu_site/utils/utils.dart';

class FirestoreChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? get user => _auth.currentUser;

  // Check and request permissions based on source
  Future<bool> _requestPermission(ImageSource source) async {
    Permission permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      Utils.snackBar('Error', 'Permission permanently denied. Please enable it in settings.');
      await openAppSettings();
      return false;
    } else {
      Utils.snackBar('Error', 'Permission denied.');
      return false;
    }
  }

  // Pick and upload an image or video
  Future<String?> pickAndUploadMedia(String projectId, {required ImageSource source, bool isVideo = false}) async {
    try {
      // Request appropriate permission
      final hasPermission = await _requestPermission(source);
      if (!hasPermission) return null;

      // Pick image or video
      final pickedFile = isVideo
          ? await _imagePicker.pickVideo(source: source)
          : await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        Utils.snackBar('Info', 'No ${isVideo ? 'video' : 'image'} selected.');
        return null;
      }

      final file = File(pickedFile.path);
      final fileSizeMB = (await file.length()) / (1024 * 1024);
      if (fileSizeMB > 100) {
        Utils.snackBar('Error', '${isVideo ? 'Video' : 'Image'} size exceeds 100 MB limit.');
        return null;
      }

      // Upload file
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storageRef = _storage
          .ref()
          .child('project_chats')
          .child(projectId)
          .child(fileName);

      final contentType = isVideo
          ? 'video/${path.extension(fileName).replaceFirst('.', '')}'
          : 'image/${path.extension(fileName).replaceFirst('.', '')}';

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error in pickAndUploadMedia: $e'); // Log for debugging
      Utils.snackBar('Error', 'Failed to upload ${isVideo ? 'video' : 'image'}: $e');
      return null;
    }
  }

  // Check if group chat metadata exists
  Future<bool> groupChatExists(String projectId) async {
    final groupChatRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata');
    final snapshot = await groupChatRef.get();
    return snapshot.exists;
  }

  // Initialize group chat for a project
  Future<void> initializeGroupChat(String projectId, List<String> collaboratorIds, List<String> collaboratorEmails) async {
    if (user == null) throw Exception('User not authenticated');

    final groupChatRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata');

    // Check if group chat already exists
    final groupChatDoc = await groupChatRef.get();
    if (!groupChatDoc.exists) {
      await groupChatRef.set({
        'projectId': projectId,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user!.uid, ...collaboratorIds],
        'memberEmails': [user!.email, ...collaboratorEmails],
        'creatorId': user!.uid,
      });

      // Update users' project group chat references
      for (var email in collaboratorEmails) {
        final userDoc = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (userDoc.docs.isNotEmpty) {
          await _firestore.collection('users').doc(userDoc.docs.first.id).update({
            'groupChats.$projectId': projectId,
          });
        }
      }
    }
  }

  Stream<QuerySnapshot> getMessages(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots();
  }

  // Send a message
  Future<void> sendMessage(
      String projectId,
      String message, {
        String? mediaUrl,
        String? messageType,
        Map<String, dynamic>? replyTo,
      }) async {
    if (user == null) throw Exception('User not authenticated');

    final messageData = {
      'message': message,
      'sentBy': user!.email,
      'sentAt': FieldValue.serverTimestamp(),
      'userId': user!.uid,
      'status': 'sent',
      'readBy': [user!.uid],
      'type': messageType ?? 'text',
      'mediaUrl': mediaUrl,
      'replyTo': replyTo,
      'photoUrl': user!.photoURL,
    };

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .add(messageData);
  }

  // Add emoji reaction to a message
  Future<void> addReaction(String projectId, String messageId, String emoji) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$emoji': FieldValue.arrayUnion([user!.uid]),
    });
  }

  // Remove emoji reaction from a message
  Future<void> removeReaction(String projectId, String messageId, String emoji) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.$emoji': FieldValue.arrayRemove([user!.uid]),
    });
  }

  // Set typing status
  Future<void> setTypingStatus(String projectId, bool isTyping) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('typing')
        .doc(user!.uid)
        .set({
      'isTyping': isTyping,
      'userName': user!.email,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get typing status
  Stream<QuerySnapshot> getTypingStatus(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('typing')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Delete a message
  Future<void> deleteMessage(String projectId, String messageId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  // Get group chat details
  Stream<DocumentSnapshot> getGroupChatDetails(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .snapshots();
  }
}