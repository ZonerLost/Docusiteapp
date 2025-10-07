import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/project/collaborator.dart';
import '../../models/project/project.dart';
import '../../../utils/Utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/project_services/firestore_project_services.dart'; // Needed for type hints

class HomeViewModel extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final FirebaseAuth _auth = FirebaseAuth.instance;


  RxList<Project> projects = <Project>[].obs;
  RxBool isLoadingProjects = true.obs;
  RxString currentUserId = ''.obs;
  late StreamSubscription<List<Project>> _projectSubscription;
  final titleController = TextEditingController();
  final clientController = TextEditingController();
  final locationController = TextEditingController();
  final deadlineController = TextEditingController(); // NOTE: Now controlled by Date Picker
  RxList<Collaborator> assignedMembers = <Collaborator>[].obs;
  RxBool isSavingProject = false.obs;
  RxBool hasViewAccess = true.obs;
  RxBool hasEditAccess = false.obs; // Toggle between View/Edit

  final memberNameController = TextEditingController();
  final memberEmailController = TextEditingController();
  RxBool isInvitingMember = false.obs;

  @override
  void onInit() {
    _initAuthState();
    super.onInit();
  }

  // Initialize and listen to Auth State
  void _initAuthState() {
    // Ensure we have a UID before streaming projects
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        currentUserId.value = user.uid;
        _startProjectStream();
      } else {
        currentUserId.value = '';
        projects.clear();
        isLoadingProjects.value = false;
        // Handle navigation to login if needed
      }
    });
  }

  // Start real-time subscription to projects
  void _startProjectStream() {
    if (currentUserId.value.isEmpty) {
      projects.clear();
      isLoadingProjects.value = false;
      Utils.snackBar('Info', 'Please log in to view projects.');
      return;
    }

    isLoadingProjects.value = true;
    _projectSubscription = _projectService.streamAllProjects().listen(
          (projectList) {
        projects.value = projectList;
        isLoadingProjects.value = false;
        if (projectList.isEmpty) {
          print('No projects found in /projects collection for user: ${currentUserId.value}');
          Utils.snackBar('Info', 'No projects available. Create a new project to get started.');
        } else {
          print('Loaded ${projectList.length} projects for user: ${currentUserId.value}');
        }
      },
      onError: (error) {
        isLoadingProjects.value = false;
        print('Firestore Stream Error: $error');
        Utils.snackBar('Error', 'Failed to load projects: $error');
      },
    );
  }

  Future<void> selectDeadlineDate() async {
    final context = Get.context;
    if (context == null) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select Project Deadline',
    );

    if (picked != null) {
      // Format the date into a strict string format (YYYY-MM-DD)
      // This is the format that DateTime.parse() expects and handles reliably.
      final formattedDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      deadlineController.text = formattedDate;
    }
  }



  void toggleAccess(bool isEdit) {
    if (isEdit) {
      hasViewAccess.value = true; // Edit implies view
      hasEditAccess.value = true;
    } else {
      // Toggle to View-Only access
      hasViewAccess.value = true;
      hasEditAccess.value = false;
    }
  }

  Future<void> createNewProject() async {
    if (titleController.text.isEmpty ||
        clientController.text.isEmpty ||
        locationController.text.isEmpty ||
        deadlineController.text.isEmpty) {
      Utils.snackBar('Missing Info', 'Please fill in all project details.');
      return;
    }

    isSavingProject.value = true;

    try {
      final currentOwnerId = _auth.currentUser?.uid;
      final currentOwnerName = _auth.currentUser?.displayName ?? 'Project Owner';
      final currentOwnerEmail = _auth.currentUser?.email ?? 'Unknown';

      // Ensure the project owner is the first collaborator (with edit access)
      final ownerCollaborator = Collaborator(
        uid: currentOwnerId!,
        email: currentOwnerEmail,
        name: currentOwnerName,
        canEdit: true, // Owner always has edit access
      );

      print('qweuioppasjklzxcnmwrtypsdfhlxcvbnm');

      final Project newProject = Project(
        id: '', // Firestore will assign this
        title: titleController.text.trim(),
        clientName: clientController.text.trim(),
        location: locationController.text.trim(),
        // FIX: Re-enable parsing now that the UI ensures the text is in a valid format (via selectDeadlineDate)
        deadline: DateTime.parse(deadlineController.text.trim()),
        // deadline: DateTime.now(),
        ownerId: currentOwnerId,
        progress: 0.0,
        // Combine owner and assigned members
        collaborators: [ownerCollaborator, ...assignedMembers.value],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'In progress',
      );
      print('qweuioppasjklzxcnmwrtypsdfhlxcvbnm');


      await _projectService.createProject(newProject);

      // Clear the form after successful creation
      _clearProjectForm();
    } catch (e) {
      print(e.toString());

      // Error handled and snackbar displayed in the service layer
    } finally {
      isSavingProject.value = false;
    }
  }

  void _clearProjectForm() {
    titleController.clear();
    clientController.clear();
    locationController.clear();
    deadlineController.clear();
    assignedMembers.clear();
    hasViewAccess.value = true;
    hasEditAccess.value = false;
  }


  // --- Member Invitation Logic (Mock for now, requires deeper integration) ---

  Future<void> sendMemberInvite() async {
    final name = memberNameController.text.trim();
    final email = memberEmailController.text.trim();

    if (name.isEmpty || email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.snackBar('Validation', 'Please enter a valid name and email address.');
      return;
    }

    isInvitingMember.value = true;

    // --- MOCK INVITATION LOGIC (Replace with real system) ---

    try {
      final newMember = Collaborator(
        uid: email,
        email: email,
        name: name,
        canEdit: hasEditAccess.value,
        photoUrl: 'https://placehold.co/100x100/A0A0A0/FFFFFF?text=${name.substring(0, 1)}',
      );

      // 3. Add to the list of members waiting to be assigned to the project
      assignedMembers.add(newMember);

      // 4. Close the invite sheet
      Get.back();
      memberNameController.clear();
      memberEmailController.clear();
      Utils.snackBar('Success', '$name added to assign list.');

    } catch (e) {
      Utils.snackBar('Error', 'Failed to process invite: ${e.toString()}');
    } finally {
      isInvitingMember.value = false;
    }
  }


  @override
  void onClose() {
    // _projectSubscription.cancelIfNotNull();
    titleController.dispose();
    clientController.dispose();
    locationController.dispose();
    deadlineController.dispose();
    memberNameController.dispose();
    memberEmailController.dispose();
    super.onClose();
  }
}
