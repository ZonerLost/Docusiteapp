import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:docu_site/utils/Utils.dart';

import '../../constants/app_colors.dart';
import '../../models/collaborator/collaborator.dart';
import '../../models/project/project.dart';
import '../../models/project/project_file.dart';
import '../../services/project_services/firestore_project_services.dart';
import '../../view/screens/home/home.dart';
import '../../view/widget/my_text_widget.dart';

class ProjectDetailsController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<Project?> project = Rx<Project?>(null);
  final String projectId;
  final RxBool isAddingMember = false.obs;
  final RxBool isUploadingFile = false.obs;
  final RxBool isDeletingProject = false.obs;

  // Invitation-related properties
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController memberEmailController = TextEditingController();
  final RxString selectedMemberRole = Project.roleOptions.first.obs;
  final RxBool isInvitingMember = false.obs;

  ProjectDetailsController({required this.projectId});

  final memberRoleController = TextEditingController();


  @override
  void onInit() {
    super.onInit();
    _streamProjectDetails();
  }


  // Add these properties to ProjectDetailsController class
  final RxBool hasViewAccess = true.obs;
  final RxBool hasEditAccess = false.obs;

// Add these methods to ProjectDetailsController class
  void toggleViewAccess(bool value) {
    hasViewAccess.value = value;
    // If view access is turned off, edit access must also be off
    if (!value) {
      hasEditAccess.value = false;
    }
  }

  void toggleEditAccess(bool value) {
    hasEditAccess.value = value;
    // If edit access is turned on, view access must also be on
    if (value) {
      hasViewAccess.value = true;
    }
  }

// Update the inviteMemberToProject method to use access controls
  Future<void> inviteMemberToProject() async {
    final name = memberNameController.text.trim();
    final email = memberEmailController.text.trim();
    final role = memberRoleController.text.trim();
    final finalRole = role.isEmpty ? 'Member' : role;

    if (name.isEmpty || email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.snackBar('Validation', 'Please enter a valid name and email address.');
      return;
    }

    isInvitingMember.value = true;

    try {
      // Check if user exists in the system
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        Utils.snackBar('Error', 'User with email $email is not registered in the system.');
        return;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;
      final userName = userData['displayName'] ?? name;

      // Check if user is already a collaborator in this project
      final currentCollaborators = project.value?.collaborators ?? [];
      if (currentCollaborators.any((collab) => collab.email == email)) {
        Utils.snackBar('Info', '$userName is already a member of this project.');
        return;
      }

      // Check if there's already a pending invite
      final pendingInviteQuery = await _firestore
          .collection('pending_requests')
          .doc(email)
          .collection('requests')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingInviteQuery.docs.isNotEmpty) {
        Utils.snackBar('Info', 'An invitation has already been sent to $email.');
        return;
      }

      // Get current project to add update
      final currentProject = project.value;
      if (currentProject == null) {
        Utils.snackBar('Error', 'Project not found.');
        return;
      }

      // Add invite sent update to project
      final updatedProject = currentProject.addInviteSentUpdate(
        userName,
        _currentUserId,
        _currentUserName,
      );

      // Update project with the new update
      await _projectService.updateProject(projectId, updatedProject);

      // Send the invitation with access level
      await _sendProjectInvite(email, userName, finalRole);

      Get.back();
      memberNameController.clear();
      memberEmailController.clear();
      memberRoleController.clear();

      // Reset access controls after successful invitation
      hasViewAccess.value = true;
      hasEditAccess.value = false;

      Utils.snackBar('Success', 'Invitation sent to $userName successfully.');

    } catch (e) {
      Utils.snackBar('Error', 'Failed to send invitation: ${e.toString()}');
    } finally {
      isInvitingMember.value = false;
    }
  }

// Update the _sendProjectInvite method to include access level
  Future<void> _sendProjectInvite(String email, String userName, String role) async {
    try {
      final currentUser = auth.currentUser!;
      final projectData = project.value;

      // Create parent document if it doesn't exist
      final parentDocRef = _firestore.collection('pending_requests').doc(email);
      await parentDocRef.set({
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Determine access level based on the checkboxes
      final accessLevel = hasEditAccess.value ? 'edit' : 'view';

      // Create the invitation
      final inviteRef = parentDocRef.collection('requests').doc();
      await inviteRef.set({
        'id': inviteRef.id,
        'projectId': projectId,
        'projectTitle': projectData?.title ?? 'Unknown Project',
        'invitedBy': currentUser.uid,
        'invitedByEmail': currentUser.email,
        'invitedByName': currentUser.displayName ?? 'Unknown User',
        'invitedEmail': email,
        'invitedUserName': userName,
        'role': role,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'accessLevel': accessLevel, // Use the actual access level from checkboxes
      });
    } catch (e) {
      rethrow;
    }
  }

  void _streamProjectDetails() {
    _projectService.streamProject(projectId).listen((projectData) {
      project.value = projectData;
      if (projectData == null && project.value == null) {
        // Utils.snackBar('Error', 'Project not found or you do not have access.');
      }
    }).onError((error) {
      Utils.snackBar('Error', 'Failed to fetch project details: ${error.toString()}');
    });
  }

  Map<String, List<ProjectFile>> get groupedFiles {
    if (project.value == null) return {};

    final Map<String, List<ProjectFile>> map = {};
    for (var file in project.value!.files) {
      if (file.category.isNotEmpty) {
        if (!map.containsKey(file.category)) {
          map[file.category] = [];
        }
        map[file.category]!.add(file);
      }
    }
    return map;
  }

  int get memberCount => project.value?.collaborators.length ?? 0;

  String get projectOwnerName {
    final ownerId = project.value?.ownerId;
    if (ownerId == null) return 'Unknown Owner';

    final owner = project.value?.collaborators.firstWhereOrNull(
          (c) => c.uid == ownerId,
    );
    return owner?.name ?? 'Unknown Owner';
  }

  // Check if current user is the project owner
  bool get isCurrentUserOwner {
    final currentUser = auth.currentUser;
    return currentUser != null && project.value?.ownerId == currentUser.uid;
  }

  // Get current user info for updates
  String get _currentUserId => auth.currentUser?.uid ?? '';
  String get _currentUserName => auth.currentUser?.displayName ?? auth.currentUser?.email?.split('@')[0] ?? 'Unknown User';


  Future<void> removeMember(String memberId) async {
    try {
      final member = project.value?.collaborators.firstWhereOrNull((c) => c.uid == memberId);
      if (member == null) {
        Utils.snackBar('Error', 'Member not found in project.');
        return;
      }

      // Prevent removing the project owner
      if (member.uid == project.value?.ownerId) {
        Utils.snackBar('Error', 'Cannot remove the project owner.');
        return;
      }

      // Get current project to add update
      final currentProject = project.value;
      if (currentProject == null) {
        Utils.snackBar('Error', 'Project not found.');
        return;
      }

      // Add collaborator removed update
      final updatedProject = currentProject.addCollaboratorUpdate(
        member.name,
        'removed',
        _currentUserId,
        _currentUserName,
      );

      // Remove from main projects collection with update
      await _firestore.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayRemove([member.toMap()]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Utils.snackBar('Success', '${member.name} removed from project.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to remove member: ${e.toString()}');
    }
  }

  Future<bool> addNewPdf(String category, String filePath, String fileName) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      Utils.snackBar('Error', 'User not logged in.');
      return false;
    }

    // ✅ Allow only project owner or collaborators
    final currentProject = project.value;
    if (currentProject == null) {
      Utils.snackBar('Error', 'Project not found.');
      return false;
    }

    final isOwner = currentProject.ownerId == currentUser.uid;
    final isCollaborator = currentProject.collaborators
        .any((c) => c.uid == currentUser.uid);

    if (!isOwner && !isCollaborator) {
      Utils.snackBar('Access Denied', 'Only project members can upload files.');
      return false;
    }

    // continue with existing upload code...
    isUploadingFile.value = true;
    try {
      final storageRef = _storage
          .ref()
          .child('project_files/$projectId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      final uploadTask = await storageRef.putFile(File(filePath));
      final fileUrl = await uploadTask.ref.getDownloadURL();

      final newFile = ProjectFile(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        uploadedBy: currentUser.displayName ?? currentUser.email ?? 'Unknown User',
        uploadedById: currentUser.uid,
        fileName: fileName,
        category: category,
        fileUrl: fileUrl,
        lastUpdated: DateTime.now(),
        newCommentsCount: 0,
        newImagesCount: 0,
      );

      final updatedProject = currentProject.addFileUpdate(
        fileName,
        'added',
        _currentUserId,
        _currentUserName,
      );

      await _firestore.collection('projects').doc(projectId).update({
        'files': FieldValue.arrayUnion([newFile.toMap()]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Get.back();
      return true;
    } catch (e) {
      Utils.snackBar('Error', 'Failed to upload file: ${e.toString()}');
      return false;
    } finally {
      isUploadingFile.value = false;
    }
  }

  Future<void> deleteFile(ProjectFile file) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      Utils.snackBar('Error', 'User not logged in.');
      return;
    }

    // ✅ Only allow owner or uploader to delete
    final isOwner = isCurrentUserOwner;
    final isUploader = file.uploadedById == currentUser.uid;

    if (!isOwner && !isUploader) {
      Utils.snackBar('Access Denied', 'You can only delete files you uploaded.');
      return;
    }

    try {
      final currentProject = project.value;
      if (currentProject == null) return;

      // Record update for history tracking
      final updatedProject = currentProject.addFileUpdate(
        file.fileName,
        'deleted',
        _currentUserId,
        _currentUserName,
      );

      // Delete file from Firebase Storage
      try {
        final fileRef = _storage.refFromURL(file.fileUrl);
        await fileRef.delete();
      } catch (e) {
        print('Error deleting file from storage: $e');
      }

      // Remove file from Firestore array
      await _firestore.collection('projects').doc(projectId).update({
        'files': FieldValue.arrayRemove([file.toMap()]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // ✅ Update local project cache so UI refreshes instantly
      project.value = updatedProject.copyWith(
        files: currentProject.files.where((f) => f.id != file.id).toList(),
      );

      Utils.snackBar('Success', '${file.fileName} deleted successfully.');
      update();
    } catch (e) {
      Utils.snackBar('Error', 'Failed to delete file: ${e.toString()}');
    }
  }


  // Update project status with tracking
  Future<void> updateProjectStatus(String newStatus) async {
    try {
      final currentProject = project.value;
      if (currentProject == null) {
        Utils.snackBar('Error', 'Project not found.');
        return;
      }

      // Add status update
      final updatedProject = currentProject.addStatusUpdate(
        newStatus,
        _currentUserId,
        _currentUserName,
      );

      // Update project status and add update
      await _firestore.collection('projects').doc(projectId).update({
        'status': newStatus,
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Utils.snackBar('Success', 'Project status updated to $newStatus.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to update project status: ${e.toString()}');
    }
  }

  // Update project progress with tracking
  Future<void> updateProjectProgress(double newProgress) async {
    try {
      final currentProject = project.value;
      if (currentProject == null) {
        Utils.snackBar('Error', 'Project not found.');
        return;
      }

      // Add progress update
      final updatedProject = currentProject.addProgressUpdate(
        newProgress,
        _currentUserId,
        _currentUserName,
      );

      // Update project progress and add update
      await _firestore.collection('projects').doc(projectId).update({
        'progress': newProgress,
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Utils.snackBar('Success', 'Project progress updated to ${(newProgress * 100).toStringAsFixed(0)}%.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to update project progress: ${e.toString()}');
    }
  }

  // Update project info with tracking
  Future<void> updateProjectInfo(String field, String newValue) async {
    try {
      final currentProject = project.value;
      if (currentProject == null) {
        Utils.snackBar('Error', 'Project not found.');
        return;
      }

      // Add info update
      final updatedProject = currentProject.addProjectInfoUpdate(
        field,
        newValue,
        _currentUserId,
        _currentUserName,
      );

      // Update project field and add update
      await _firestore.collection('projects').doc(projectId).update({
        field: newValue,
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      Utils.snackBar('Success', 'Project $field updated successfully.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to update project $field: ${e.toString()}');
    }
  }

  Future<void> deleteProject() async {
    // Check if current user is the project owner
    if (!isCurrentUserOwner) {
      Utils.snackBar('Error', 'Only the project owner can delete the project.');
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await _showDeleteConfirmationDialog();
    if (!shouldDelete) return;

    isDeletingProject.value = true;

    try {
      final currentProject = project.value;
      if (currentProject == null) {
        Utils.snackBar('Error', 'Project not found.');
        return;
      }

      // 1. Delete all project files from Firebase Storage
      await _deleteProjectFiles(currentProject.files);

      // 2. Delete project from main projects collection
      await _firestore.collection('projects').doc(projectId).delete();

      // 3. Delete project from all collaborators' user projects subcollection
      await _deleteProjectFromCollaborators(currentProject.collaborators);

      // 4. Delete any pending invitations for this project
      await _deletePendingInvites();

      Utils.snackBar('Success', 'Project deleted successfully.');

      // Navigate directly back to home and remove all routes from stack
      Get.offAll(() => Home()); // Make sure to import your Home screen

    } catch (e) {
      Utils.snackBar('Error', 'Failed to delete project: ${e.toString()}');
    } finally {
      isDeletingProject.value = false;
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: MyText(
          text: 'Delete Project',
          size: 18,
          weight: FontWeight.w600,
        ),
        content: MyText(
          text: 'Are you sure you want to delete this project? This action cannot be undone and all project data will be permanently lost.',
          size: 14,
          color: kQuaternaryColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: MyText(
              text: 'Cancel',
              color: kQuaternaryColor,
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: MyText(
              text: 'Delete',
              color: kRedColor,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _deleteProjectFiles(List<ProjectFile> files) async {
    try {
      for (final file in files) {
        try {
          // Extract file path from download URL or use the file name
          final fileRef = _storage.refFromURL(file.fileUrl);
          await fileRef.delete();
        } catch (e) {
          // Log error but continue with other files
          print('Error deleting file ${file.fileName}: $e');
        }
      }
    } catch (e) {
      print('Error in project files deletion: $e');
      // Don't throw error here - we want to continue with project deletion
    }
  }

  Future<void> _deleteProjectFromCollaborators(List<Collaborator> collaborators) async {
    try {
      for (final collaborator in collaborators) {
        try {
          await _firestore
              .collection('users')
              .doc(collaborator.uid)
              .collection('projects')
              .doc(projectId)
              .delete();
        } catch (e) {
          // Log error but continue with other collaborators
          print('Error deleting project from user ${collaborator.uid}: $e');
        }
      }
    } catch (e) {
      print('Error in collaborators cleanup: $e');
      // Don't throw error here - we want to continue with project deletion
    }
  }

  Future<void> _deletePendingInvites() async {
    try {
      // Get all pending invites for this project
      final invitesQuery = await _firestore
          .collectionGroup('requests')
          .where('projectId', isEqualTo: projectId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final inviteDoc in invitesQuery.docs) {
        try {
          await inviteDoc.reference.delete();
        } catch (e) {
          print('Error deleting invite ${inviteDoc.id}: $e');
        }
      }
    } catch (e) {
      print('Error in pending invites cleanup: $e');
      // Don't throw error here - we want to continue with project deletion
    }
  }

  bool canRemoveMember(String memberId) {
    // Only project owner can remove members
    if (!isCurrentUserOwner) return false;

    final member = project.value?.collaborators.firstWhereOrNull((c) => c.uid == memberId);
    if (member == null) return false;

    // Cannot remove the project owner
    if (member.uid == project.value?.ownerId) return false;

    // Cannot remove yourself
    if (member.uid == auth.currentUser?.uid) return false;

    return true;
  }

  @override
  void onClose() {
    memberNameController.dispose();
    memberEmailController.dispose();
    super.onClose();
  }
}