import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:docu_site/utils/Utils.dart';

import '../../models/project/collaborator.dart';
import '../../models/project/project.dart';
import '../../models/project/project_file.dart';
import '../../services/project_services/firestore_project_services.dart'; // Assuming this exists for snackbars


class ProjectDetailsController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Rx<Project?> project = Rx<Project?>(null);
  final String projectId;
  final RxBool isAddingMember = false.obs;
  final RxBool isUploadingFile = false.obs;

  ProjectDetailsController({required this.projectId});

  @override
  void onInit() {
    super.onInit();
    _streamProjectDetails();
  }

  void _streamProjectDetails() {
    _projectService.streamProject(projectId).listen((projectData) {
      project.value = projectData;
      if (projectData == null && project.value == null) {
        Utils.snackBar('Error', 'Project not found or you do not have access.');
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

  Future<void> addMember(String name, String email, String role) async {
    if (name.isEmpty || email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.snackBar('Validation', 'Please enter a valid name and email address.');
      return;
    }

    isAddingMember.value = true;

    try {
      final newMember = Collaborator(
        uid: email, // Using email as UID for simplicity; adjust as needed
        email: email,
        name: name,
        canEdit: role.toLowerCase() == 'editor', // Example logic for edit access
        photoUrl: 'https://placehold.co/100x100/A0A0A0/FFFFFF?text=${name.substring(0, 1)}',
        role: role,
      );

      // Update main projects collection
      await _firestore.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayUnion([newMember.toMap()])
      });

      // Update user's projects subcollection
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('projects')
            .doc(projectId)
            .update({
          'collaborators': FieldValue.arrayUnion([newMember.toMap()])
        });
      }

      Utils.snackBar('Success', '$name added to project.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to add member: ${e.toString()}');
    } finally {
      isAddingMember.value = false;
    }
  }

  Future<void> addNewPdf(String category, String filePath, String fileName) async {
    isUploadingFile.value = true;

    try {
      // Upload file to Firebase Storage
      final storageRef = _storage.ref().child('project_files/$projectId/$fileName');
      final uploadTask = await storageRef.putData(
        await File(filePath).readAsBytes(),
        SettableMetadata(contentType: 'application/pdf'),
      );
      final fileUrl = await uploadTask.ref.getDownloadURL();

      // Create new ProjectFile
      final newFile = ProjectFile(
        id: projectId,
        uploadedBy: projectOwnerName,
        fileName: fileName,
        category: category,
        fileUrl: fileUrl,
        lastUpdated: DateTime.now(),
        newCommentsCount: 0,
        newImagesCount: 0,
      );

      // Update main projects collection
      await _firestore.collection('projects').doc(projectId).update({
        'files': FieldValue.arrayUnion([newFile.toMap()])
      });

      // Update user's projects subcollection
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('projects')
            .doc(projectId)
            .update({
          'files': FieldValue.arrayUnion([newFile.toMap()])
        });
      }

      Utils.snackBar('Success', 'File "$fileName" uploaded successfully.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to upload file: ${e.toString()}');
    } finally {
      isUploadingFile.value = false;
    }
  }

  void deleteProject() {
    Utils.snackBar('Action', 'Delete project functionality TBD for ID: $projectId.');
  }

  void editProject() {
    Utils.snackBar('Action', 'Edit project functionality TBD for ID: $projectId.');
  }
}