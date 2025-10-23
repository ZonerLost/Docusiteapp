import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../../../models/project/project.dart';
import '../../../models/project/project_file.dart';
import '../../models/collaborator/collaborator.dart';
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
  final RxString selectedStatus = 'In Progress'.obs; // keep same spelling used in UI
  final RxDouble progressValue = 0.0.obs;

  /// Dynamic/base-extra fields are edited via this reactive map
  final RxMap<String, dynamic> additionalFields = <String, dynamic>{}.obs;

  /// Cache text controllers per-field to avoid recreating them on rebuild
  final Map<String, TextEditingController> keyControllers = {};
  final Map<String, TextEditingController> valueControllers = {};

  EditProjectController({required this.projectId});

  @override
  void onInit() {
    super.onInit();
    _loadProject();
  }

  Future<void> _loadProject() async {
    try {
      isLoading.value = true;
      update();

      final projectData = await _projectService.getProject(projectId);

      if (projectData != null) {
        bindProject(projectData);
      } else {
        project.value = null;
      }
    } catch (e, stackTrace) {
      print('❌ Error loading project: $e\n$stackTrace');
      Utils.snackBar('Error', 'Failed to load project: ${e.toString()}');
      project.value = null;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Bind a loaded project to form + dynamic fields
  void bindProject(Project p) {
    project.value = p;

    // Base fields
    titleController.text = p.title;
    clientController.text = p.clientName;
    locationController.text = p.location;
    deadlineController.text = DateFormat('yyyy-MM-dd').format(p.deadline);

    // Status normalization
    final status = p.status;
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

    progressValue.value = p.progress;

    // Dynamic fields (extraFields)
    additionalFields.clear();
    additionalFields.addAll(p.extraFields);

    // controllers for dynamic fields
    keyControllers.clear();
    valueControllers.clear();
    for (final e in additionalFields.entries) {
      keyControllers[e.key] = TextEditingController(text: e.key);
      valueControllers[e.key] =
          TextEditingController(text: e.value?.toString() ?? '');
    }

    // subscribe for light UI refreshes
    selectedStatus.listen((_) => update());
    progressValue.listen((_) => update());
    update();
  }

  Future<void> _fixProjectStatus(String oldStatus, String newStatus) async {
    try {
      await _firestore.collection('projects').doc(projectId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // Group files by category
  Map<String, List<ProjectFile>> get groupedFiles {
    if (project.value == null) return {};
    final Map<String, List<ProjectFile>> map = {};
    for (var file in project.value!.files) {
      if (file.category.isNotEmpty) {
        map.putIfAbsent(file.category, () => []);
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
      update();
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
      update();
    } catch (e) {
      Utils.snackBar('Error', 'Failed to remove member: ${e.toString()}');
    }
  }

  /// ========= Additional fields (extraFields) =========

  void addAdditionalField(String key, String value) {
    if (key.trim().isEmpty) return;
    if (Project.reservedFieldNames.contains(key)) {
      Utils.snackBar('Error', '"$key" is a reserved field name and cannot be used.');
      return;
    }
    additionalFields[key] = value;
    keyControllers[key] = TextEditingController(text: key);
    valueControllers[key] = TextEditingController(text: value);
    update();
  }

  void updateAdditionalFieldKey(String oldKey, String newKey) {
    if (!additionalFields.containsKey(oldKey)) return;
    if (newKey.trim().isEmpty) return;
    if (Project.reservedFieldNames.contains(newKey)) {
      Utils.snackBar('Error', '"$newKey" is a reserved field name and cannot be used.');
      return;
    }

    final val = additionalFields.remove(oldKey);
    additionalFields[newKey] = val;

    final kc = keyControllers.remove(oldKey);
    final vc = valueControllers.remove(oldKey);
    if (kc != null) keyControllers[newKey] = kc..text = newKey;
    if (vc != null) valueControllers[newKey] = vc;

    update();
  }

  void updateAdditionalFieldValue(String key, String value) {
    if (!additionalFields.containsKey(key)) return;
    additionalFields[key] = value;
    valueControllers[key]?.text = value;
    update();
  }

  void removeAdditionalField(String key) {
    if (!additionalFields.containsKey(key)) return;
    additionalFields.remove(key);
    keyControllers.remove(key)?.dispose();
    valueControllers.remove(key)?.dispose();
    update();
  }

  /// Save all changes — writes extraFields as a single map under /projects/{id}.extraFields
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

      // Track changes for base fields
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

      // Compare dynamic fields (extraFields) and CAPTURE returned Project
      final oldExtra = Map<String, dynamic>.from(currentProject.extraFields);
      final newExtra = Map<String, dynamic>.from(additionalFields);
      final hasExtraChanged = !_areMapsEqual(oldExtra, newExtra);
      if (hasExtraChanged) {
        updatedProject = _trackAdditionalFieldChanges(
          oldExtra,
          newExtra,
          updatedProject,
        );
      }

      // Build final project
      final finalProject = updatedProject.copyWith(
        title: titleController.text.trim(),
        clientName: clientController.text.trim(),
        location: locationController.text.trim(),
        deadline: newDeadline,
        status: selectedStatus.value,
        progress: progressValue.value,
        updatedAt: DateTime.now(),
        extraFields: newExtra, // <—— write back
      );

      // Prepare update map (write extraFields under a single map key)
      final updateMap = {
        'title': finalProject.title,
        'clientName': finalProject.clientName,
        'location': finalProject.location,
        'deadline': Timestamp.fromDate(finalProject.deadline),
        'status': finalProject.status,
        'progress': finalProject.progress,
        'lastUpdates': finalProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
        'extraFields': finalProject.extraFields, // <—— single source of truth
      };

      await _firestore.collection('projects').doc(projectId).update(updateMap);

      // Update local state and close
      bindProject(finalProject);
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

  /// Returns an updated Project with lastUpdates entries for add/update/remove of extra fields
  Project _trackAdditionalFieldChanges(
      Map<String, dynamic> oldFields,
      Map<String, dynamic> newFields,
      Project proj,
      ) {
    var updated = proj;

    // Added or Updated
    for (final key in newFields.keys) {
      final newVal = newFields[key];
      if (!oldFields.containsKey(key)) {
        updated = updated.addAdditionalFieldUpdate(
          key, 'added', _currentUserId, _currentUserName,
        );
      } else if (oldFields[key] != newVal) {
        updated = updated.addAdditionalFieldUpdate(
          key, 'updated', _currentUserId, _currentUserName,
        );
      }
    }

    // Removed
    for (final key in oldFields.keys) {
      if (!newFields.containsKey(key)) {
        updated = updated.addAdditionalFieldRemovedUpdate(
          key, _currentUserId, _currentUserName,
        );
      }
    }

    return updated;
  }

  // Compare maps shallowly (sufficient for string/number values)
  bool _areMapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final k in a.keys) {
      if (!b.containsKey(k)) return false;
      if (a[k] != b[k]) return false;
    }
    return true;
  }

  // Helper getters
  String get _currentUserId => auth.currentUser?.uid ?? '';
  String get _currentUserName =>
      auth.currentUser?.displayName ?? auth.currentUser?.email?.split('@')[0] ?? 'Unknown User';

  @override
  void onClose() {
    titleController.dispose();
    clientController.dispose();
    locationController.dispose();
    deadlineController.dispose();
    for (final c in keyControllers.values) c.dispose();
    for (final c in valueControllers.values) c.dispose();
    super.onClose();
  }
}
