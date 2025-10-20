import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:docu_site/utils/utils.dart';

class FirestoreChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  User? get user => _auth.currentUser;

  Future<bool> _requestPermission(ImageSource source) async {
    try {
      if (source == ImageSource.camera) {
        // For camera, request camera permission
        final status = await Permission.camera.request();
        return status.isGranted;
      } else {
        // For gallery, request photos permission on iOS, storage on Android
        if (Platform.isIOS) {
          final status = await Permission.photos.request();
          return status.isGranted;
        } else {
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }
    } catch (e) {
      print('Permission error: $e');
      // If permission request fails, try to pick image anyway
      return true;
    }
  }

  // Enhanced media picker with better error handling
  Future<String?> pickAndUploadMedia(String projectId, {required ImageSource source, bool isVideo = false}) async {
    try {
      final hasPermission = await _requestPermission(source);
      if (!hasPermission) return null;

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

      // Set reasonable file size limits
      final maxSize = isVideo ? 100 : 20; // 100MB for videos, 20MB for images
      if (fileSizeMB > maxSize) {
        Utils.snackBar('Error', '${isVideo ? 'Video' : 'Image'} size exceeds ${maxSize} MB limit.');
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(file.path)}';
      final storageRef = _storage
          .ref()
          .child('project_chats')
          .child(projectId)
          .child('media')
          .child(fileName);

      final contentType = isVideo
          ? 'video/${path.extension(fileName).replaceFirst('.', '')}'
          : 'image/${path.extension(fileName).replaceFirst('.', '')}';

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      // Show upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error in pickAndUploadMedia: $e');
      Utils.snackBar('Error', 'Failed to upload ${isVideo ? 'video' : 'image'}: ${e.toString()}');
      return null;
    }
  }

  // NEW: File attachment upload method
  Future<String?> uploadFileAttachment(String projectId, PlatformFile platformFile) async {
    try {
      final file = File(platformFile.path!);
      final fileSizeMB = (await file.length()) / (1024 * 1024);

      // Set file size limit (50MB for files)
      if (fileSizeMB > 50) {
        Utils.snackBar('Error', 'File size exceeds 50 MB limit.');
        return null;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';
      final storageRef = _storage
          .ref()
          .child('project_chats')
          .child(projectId)
          .child('attachments')
          .child(fileName);

      // Determine content type based on file extension
      final extension = path.extension(platformFile.name).toLowerCase();
      final contentType = _getContentType(extension);

      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: contentType),
      );

      // Show upload progress
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('File upload progress: ${progress.toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error in uploadFileAttachment: $e');
      Utils.snackBar('Error', 'Failed to upload file: ${e.toString()}');
      return null;
    }
  }

  // Helper method to determine content type
  String _getContentType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      case '.ppt':
      case '.pptx':
        return 'application/vnd.ms-powerpoint';
      case '.zip':
        return 'application/zip';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  // NEW: Pick files using file_picker
  Future<List<PlatformFile>?> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
          'txt', 'zip', 'jpg', 'jpeg', 'png', 'gif'
        ],
      );

      if (result == null || result.files.isEmpty) return null;

      return result.files;
    } catch (e) {
      print('Error picking files: $e');
      Utils.snackBar('Error', 'Failed to pick files: ${e.toString()}');
      return null;
    }
  }

  // Rest of your existing methods remain the same...
  Future<bool> groupChatExists(String projectId) async {
    final groupChatRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata');
    final snapshot = await groupChatRef.get();
    return snapshot.exists;
  }

  Future<void> initializeGroupChat(
      String projectId,
      List<String> collaboratorIds,
      List<String> collaboratorEmails,
      Map<String, String> collaboratorNames,
      ) async {
    if (user == null) throw Exception('User not authenticated');

    final groupChatRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata');

    final groupChatDoc = await groupChatRef.get();
    if (!groupChatDoc.exists) {
      await groupChatRef.set({
        'projectId': projectId,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user!.uid, ...collaboratorIds],
        'memberEmails': [user!.email, ...collaboratorEmails],
        'memberNames': {
          user!.uid: user!.displayName ?? user!.email?.split('@')[0] ?? 'You',
          ...collaboratorNames,
        },
        'creatorId': user!.uid,
      });
    }
  }

  Stream<QuerySnapshot> getMessages(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots();
  }

  Future<void> sendMessage(
      String projectId,
      String message, {
        String? mediaUrl,
        String? messageType,
        Map<String, dynamic>? replyTo,
        List<Map<String, dynamic>>? attachments, // NEW: Support for multiple attachments
      }) async {
    if (user == null) throw Exception('User not authenticated');

    final messageData = {
      'message': message,
      'sentBy': user!.email,
      'userName': user!.displayName ?? user!.email?.split('@')[0] ?? 'You',
      'sentAt': FieldValue.serverTimestamp(),
      'userId': user!.uid,
      'status': 'sent',
      'readBy': [user!.uid],
      'type': messageType ?? 'text',
      'mediaUrl': mediaUrl,
      'replyTo': replyTo,
      'photoUrl': user!.photoURL,
      'attachments': attachments, // NEW: Include attachments in message
    };

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('messages')
        .add(messageData);
  }

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

  Future<void> setTypingStatus(String projectId, bool isTyping) async {
    final typingRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .collection('typing')
        .doc(user!.uid);

    if (isTyping) {
      await typingRef.set({
        'isTyping': true,
        'userName': user!.displayName ?? user!.email?.split('@')[0] ?? 'User',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user!.uid,
      });
    } else {
      await typingRef.delete();
    }
  }

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

  Stream<DocumentSnapshot> getGroupChatDetails(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('group_chat')
        .doc('metadata')
        .snapshots();
  }
}