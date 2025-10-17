import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../../../models/project/project.dart';
import '../../../models/project/project_file.dart';
import '../../../models/project/collaborator.dart';
import '../../../services/project_services/firestore_project_services.dart';
import '../../../utils/Utils.dart';

class EditProjectController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final String projectId;
  final Rx<Project?> project = Rx<Project?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;

  // Form controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final RxString selectedStatus = 'In progress'.obs;
  final RxDouble progressValue = 0.0.obs;

  // Additional fields - stored as top-level fields
  final RxMap<String, dynamic> additionalFields = <String, dynamic>{}.obs;

  EditProjectController({required this.projectId});

  @override
  void onInit() {
    super.onInit();
    print('🎬 EditProjectController initialized for project: $projectId');
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      isLoading.value = true;
      update();

      print('🔄 Loading project: $projectId');
      final projectData = await _projectService.getProject(projectId);

      if (projectData != null) {
        project.value = projectData;
        _initializeForm(projectData);
        _loadAdditionalFields();
        print('✅ Project loaded: ${projectData.title}');
      } else {
        print('❌ Project not found');
        project.value = null;
      }
    } catch (e, stackTrace) {
      print('❌ Error loading project: $e');
      print('Stack trace: $stackTrace');
      Utils.snackBar('Error', 'Failed to load project: ${e.toString()}');
      project.value = null;
    } finally {
      isLoading.value = false;
      update();
      print('🏁 Loading completed');
    }
  }

  void _initializeForm(Project projectData) {
    titleController.text = projectData.title;
    clientController.text = projectData.clientName;
    locationController.text = projectData.location;
    deadlineController.text = DateFormat('yyyy-MM-dd').format(projectData.deadline);

    final status = projectData.status;
    if (Project.statusOptions.contains(status)) {
      selectedStatus.value = status;
    } else {
      if (status.toLowerCase().contains('progress')) {
        selectedStatus.value = 'In Progress';
      } else if (status.toLowerCase().contains('complete')) {
        selectedStatus.value = 'Completed';
      } else if (status.toLowerCase().contains('hold')) {
        selectedStatus.value = 'On Hold';
      } else if (status.toLowerCase().contains('pending')) {
        selectedStatus.value = 'Pending';
      } else {
        selectedStatus.value = Project.statusOptions.first;
      }
      _fixProjectStatus(status, selectedStatus.value);
    }

    progressValue.value = projectData.progress;

    selectedStatus.listen((_) => update());
    progressValue.listen((_) => update());
  }

  // Load additional fields from the complete project document
  void _loadAdditionalFields() async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final loadedAdditionalFields = Project.getAdditionalFieldsFromData(data);

        additionalFields.clear();
        additionalFields.addAll(loadedAdditionalFields);
        print('📋 Loaded ${additionalFields.length} additional fields: $additionalFields');
      }
    } catch (e) {
      print('❌ Error loading additional fields: $e');
    }
  }

  Future<void> _fixProjectStatus(String oldStatus, String newStatus) async {
    try {
      print('🔄 Fixing project status from "$oldStatus" to "$newStatus"');
      await _firestore.collection('projects').doc(projectId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Could not fix project status: $e');
    }
  }

  // Group files by category
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

  // Check if current user is the project owner
  bool get isCurrentUserOwner {
    final currentUser = auth.currentUser;
    return currentUser != null && project.value?.ownerId == currentUser.uid;
  }

  // Check if a member can be removed
  bool canRemoveMember(String memberId) {
    if (!isCurrentUserOwner) return false;
    final member = project.value?.collaborators.firstWhereOrNull((c) => c.uid == memberId);
    if (member == null) return false;
    if (member.uid == project.value?.ownerId) return false;
    if (member.uid == auth.currentUser?.uid) return false;
    return true;
  }

  // Date selection
  Future<void> selectDeadlineDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      deadlineController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // File operations
  Future<void> deleteFile(ProjectFile file) async {
    try {
      final currentProject = project.value;
      if (currentProject == null) return;

      final updatedProject = currentProject.addFileUpdate(
        file.fileName,
        'deleted',
        _currentUserId,
        _currentUserName,
      );

      try {
        final fileRef = _storage.refFromURL(file.fileUrl);
        await fileRef.delete();
      } catch (e) {
        print('Error deleting file from storage: $e');
      }

      await _firestore.collection('projects').doc(projectId).update({
        'files': FieldValue.arrayRemove([file.toMap()]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      project.value = updatedProject.copyWith(
        files: currentProject.files.where((f) => f.id != file.id).toList(),
      );

      Utils.snackBar('Success', '${file.fileName} deleted successfully.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to delete file: ${e.toString()}');
    }
  }

  // Member operations
  Future<void> removeMember(String memberId) async {
    try {
      final member = project.value?.collaborators.firstWhereOrNull((c) => c.uid == memberId);
      if (member == null) {
        Utils.snackBar('Error', 'Member not found.');
        return;
      }

      final currentProject = project.value;
      if (currentProject == null) return;

      final updatedProject = currentProject.addCollaboratorUpdate(
        member.name,
        'removed',
        _currentUserId,
        _currentUserName,
      );

      await _firestore.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayRemove([member.toMap()]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      project.value = updatedProject.copyWith(
        collaborators: currentProject.collaborators.where((c) => c.uid != memberId).toList(),
      );

      Utils.snackBar('Success', '${member.name} removed from project.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to remove member: ${e.toString()}');
    }
  }

  // Additional fields operations
  void addAdditionalField(String key, String value) {
    if (key.trim().isNotEmpty && !Project.reservedFieldNames.contains(key)) {
      additionalFields[key] = value;
      print('➕ Added additional field: $key = $value');
      update();
    } else if (Project.reservedFieldNames.contains(key)) {
      Utils.snackBar('Error', '"$key" is a reserved field name and cannot be used.');
    }
  }

  void updateAdditionalFieldKey(String oldKey, String newKey) {
    if (additionalFields.containsKey(oldKey) && newKey.trim().isNotEmpty && !Project.reservedFieldNames.contains(newKey)) {
      final value = additionalFields[oldKey]!;
      additionalFields.remove(oldKey);
      additionalFields[newKey] = value;
      print('✏️ Updated additional field key: $oldKey → $newKey');
      update();
    } else if (Project.reservedFieldNames.contains(newKey)) {
      Utils.snackBar('Error', '"$newKey" is a reserved field name and cannot be used.');
    }
  }

  void updateAdditionalFieldValue(String key, String value) {
    if (additionalFields.containsKey(key)) {
      additionalFields[key] = value;
      print('✏️ Updated additional field value: $key = $value');
      update();
    }
  }

  void removeAdditionalField(String key) {
    if (additionalFields.containsKey(key)) {
      additionalFields.remove(key);
      print('🗑️ Removed additional field: $key');
      update();
    }
  }

  // Save all changes - UPDATED to save additional fields as top-level fields
  Future<void> saveChanges() async {
    if (!isCurrentUserOwner) {
      Utils.snackBar('Error', 'Only project owner can edit project.');
      return;
    }

    if (titleController.text.trim().isEmpty ||
        clientController.text.trim().isEmpty ||
        locationController.text.trim().isEmpty) {
      Utils.snackBar('Error', 'Please fill all required fields.');
      return;
    }

    isSaving.value = true;
    update();

    try {
      final currentProject = project.value;
      if (currentProject == null) return;

      var updatedProject = currentProject;

      // Track changes for basic fields
      if (titleController.text.trim() != currentProject.title) {
        updatedProject = updatedProject.addProjectInfoUpdate(
          'title',
          titleController.text.trim(),
          _currentUserId,
          _currentUserName,
        );
      }

      if (clientController.text.trim() != currentProject.clientName) {
        updatedProject = updatedProject.addProjectInfoUpdate(
          'client name',
          clientController.text.trim(),
          _currentUserId,
          _currentUserName,
        );
      }

      if (locationController.text.trim() != currentProject.location) {
        updatedProject = updatedProject.addProjectInfoUpdate(
          'location',
          locationController.text.trim(),
          _currentUserId,
          _currentUserName,
        );
      }

      if (selectedStatus.value != currentProject.status) {
        updatedProject = updatedProject.addStatusUpdate(
          selectedStatus.value,
          _currentUserId,
          _currentUserName,
        );
      }

      if (progressValue.value != currentProject.progress) {
        updatedProject = updatedProject.addProgressUpdate(
          progressValue.value,
          _currentUserId,
          _currentUserName,
        );
      }

      final newDeadline = DateTime.parse(deadlineController.text.trim());
      if (newDeadline != currentProject.deadline) {
        updatedProject = updatedProject.addProjectInfoUpdate(
          'deadline',
          DateFormat('yyyy-MM-dd').format(newDeadline),
          _currentUserId,
          _currentUserName,
        );
      }

      // Handle additional fields changes
      final oldAdditionalFields = await _getCurrentAdditionalFields();
      final hasAdditionalFieldsChanged = !_areMapsEqual(oldAdditionalFields, additionalFields);

      if (hasAdditionalFieldsChanged) {
        _trackAdditionalFieldChanges(oldAdditionalFields, additionalFields, updatedProject);
      }

      // Create final updated project
      final finalProject = updatedProject.copyWith(
        title: titleController.text.trim(),
        clientName: clientController.text.trim(),
        location: locationController.text.trim(),
        deadline: DateTime.parse(deadlineController.text.trim()),
        status: selectedStatus.value,
        progress: progressValue.value,
        updatedAt: DateTime.now(),
      );

      print('💾 Saving project with ${additionalFields.length} additional fields as top-level fields');

      // Create update map with basic fields
      final updateMap = <String, dynamic>{
        'title': finalProject.title,
        'clientName': finalProject.clientName,
        'location': finalProject.location,
        'deadline': Timestamp.fromDate(finalProject.deadline),
        'status': finalProject.status,
        'progress': finalProject.progress,
        'lastUpdates': finalProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add additional fields as top-level fields
      for (final entry in additionalFields.entries) {
        updateMap[entry.key] = entry.value;
      }

      // Remove fields that were deleted
      for (final oldKey in oldAdditionalFields.keys) {
        if (!additionalFields.containsKey(oldKey)) {
          updateMap[oldKey] = FieldValue.delete();
        }
      }

      // Save to Firestore
      await _firestore.collection('projects').doc(projectId).update(updateMap);

      Utils.snackBar('Success', 'Project updated successfully.');
      Get.back();
    } catch (e) {
      print('❌ Error saving project: $e');
      Utils.snackBar('Error', 'Failed to update project: ${e.toString()}');
    } finally {
      isSaving.value = false;
      update();
    }
  }

  // Get current additional fields from Firestore
  Future<Map<String, dynamic>> _getCurrentAdditionalFields() async {
    try {
      final doc = await _firestore.collection('projects').doc(projectId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Project.getAdditionalFieldsFromData(data);
      }
    } catch (e) {
      print('❌ Error getting current additional fields: $e');
    }
    return {};
  }

  // Helper method to track additional field changes
  void _trackAdditionalFieldChanges(
      Map<String, dynamic> oldFields,
      Map<String, dynamic> newFields,
      Project project,
      ) {
    for (final key in newFields.keys) {
      if (!oldFields.containsKey(key)) {
        project.addAdditionalFieldUpdate(key, 'added', _currentUserId, _currentUserName);
      } else if (oldFields[key] != newFields[key]) {
        project.addAdditionalFieldUpdate(key, 'updated', _currentUserId, _currentUserName);
      }
    }

    for (final key in oldFields.keys) {
      if (!newFields.containsKey(key)) {
        project.addAdditionalFieldRemovedUpdate(key, _currentUserId, _currentUserName);
      }
    }
  }

  // Helper method to compare maps
  bool _areMapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    return true;
  }

  // Helper methods
  String get _currentUserId => auth.currentUser?.uid ?? '';
  String get _currentUserName => auth.currentUser?.displayName ??
      auth.currentUser?.email?.split('@')[0] ?? 'Unknown User';

  @override
  void onClose() {
    titleController.dispose();
    clientController.dispose();
    locationController.dispose();
    deadlineController.dispose();
    super.onClose();
  }
}