import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/project/collaborator.dart';
import '../../models/project/project.dart';
import '../../../utils/Utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/project_services/firestore_project_services.dart';

class HomeViewModel extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  RxList<Project> projects = <Project>[].obs;
  RxBool isLoadingProjects = true.obs;
  RxString currentUserId = ''.obs;
  RxInt pendingInvitesCount = 0.obs;

  late StreamSubscription<List<Project>> _projectSubscription;
  late StreamSubscription<QuerySnapshot> _invitesSubscription;

  final titleController = TextEditingController();
  final clientController = TextEditingController();
  final locationController = TextEditingController();
  final deadlineController = TextEditingController();
  RxList<Collaborator> assignedMembers = <Collaborator>[].obs;
  RxBool isSavingProject = false.obs;

  RxBool hasViewAccess = true.obs;
  RxBool hasEditAccess = false.obs;

  final memberNameController = TextEditingController();
  final memberEmailController = TextEditingController();
  RxBool isInvitingMember = false.obs;
  RxString selectedMemberRole = Project.roleOptions.first.obs;


  // Add these Rx variables to HomeViewModel
  RxString searchQuery = ''.obs;
  RxString filterClient = ''.obs;
  RxString filterLocation = ''.obs;
  RxString filterProgress = ''.obs;
  RxString filterPdf = ''.obs;


  // Add these Rx variables for search
  RxBool isSearching = false.obs;
  TextEditingController searchController = TextEditingController();

  final memberRoleController = TextEditingController();

// Method to start searching
  void startSearch() {
    isSearching.value = true;
    searchQuery.value = '';
    searchController.clear();
  }

// Method to stop searching
  void stopSearch() {
    isSearching.value = false;
    searchQuery.value = '';
    searchController.clear();
  }

// Method to update search query
  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

// Add this computed property to filter projects
  List<Project> get filteredProjects {
    var filtered = projects.where((project) {
      // Search by title
      if (searchQuery.isNotEmpty) {
        if (!project.title.toLowerCase().contains(searchQuery.value.toLowerCase())) {
          return false;
        }
      }

      // Filter by client
      if (filterClient.isNotEmpty) {
        if (!project.clientName.toLowerCase().contains(filterClient.value.toLowerCase())) {
          return false;
        }
      }

      // Filter by location
      if (filterLocation.isNotEmpty) {
        if (!project.location.toLowerCase().contains(filterLocation.value.toLowerCase())) {
          return false;
        }
      }

      // Filter by progress
      if (filterProgress.isNotEmpty) {
        final progressPercent = (project.progress * 100).toInt();
        final filterValue = filterProgress.value.replaceAll('%', '');
        if (filterValue.isNotEmpty) {
          final targetProgress = int.tryParse(filterValue) ?? 0;
          if (progressPercent != targetProgress) {
            return false;
          }
        }
      }

      return true;
    }).toList();

    return filtered;
  }

// Method to clear all filters
  void clearFilters() {
    searchQuery.value = '';
    filterClient.value = '';
    filterLocation.value = '';
    filterProgress.value = '';
    filterPdf.value = '';
  }

// Method to apply filters
  void applyFilters({
    String? client,
    String? location,
    String? progress,
    String? pdf,
  }) {
    filterClient.value = client ?? '';
    filterLocation.value = location ?? '';
    filterProgress.value = progress ?? '';
    filterPdf.value = pdf ?? '';
  }

  @override
  void onInit() {
    super.onInit();
    log('[HomeViewModel] onInit: Initializing ViewModel.');
    _initAuthState();
    messaging.onTokenRefresh.listen((token) {
      log('[HomeViewModel] onTokenRefresh: FCM token has been refreshed.');
      _saveFcmToken(token);
    });
  }

  void _initAuthState() {
    log('[HomeViewModel] _initAuthState: Setting up auth state listener.');
    auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        log('[HomeViewModel] AuthStateChange: User is signed in. UID: ${user.uid}');
        currentUserId.value = user.uid;
        await _requestNotificationPermission();
        String? token = await messaging.getToken();
        await _saveFcmToken(token);
        _startProjectStream();
        _startInvitesStream();
      } else {
        log('[HomeViewModel] AuthStateChange: User is signed out.');
        currentUserId.value = '';
        projects.clear();
        pendingInvitesCount.value = 0;
        isLoadingProjects.value = false;
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    log('[HomeViewModel] _requestNotificationPermission: Requesting notification permissions.');
    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        log('[HomeViewModel] _requestNotificationPermission: User granted notification permission.');
      } else {
        log('[HomeViewModel] _requestNotificationPermission: Notification permission denied.');
      }
    } catch (e) {
      log('[HomeViewModel] _requestNotificationPermission: Error requesting permission: $e');
    }
  }

  Future<void> _saveFcmToken(String? token) async {
    log('[HomeViewModel] _saveFcmToken: Attempting to save FCM token.');
    if (token != null && currentUserId.value.isNotEmpty) {
      try {
        log('[HomeViewModel] _saveFcmToken: Saving token for user: ${currentUserId.value}');
        await firestore.collection('users').doc(currentUserId.value).set(
          {'fcmToken': token},
          SetOptions(merge: true),
        );
        log('[HomeViewModel] _saveFcmToken: FCM token saved successfully.');
      } catch (e) {
        log('[HomeViewModel] _saveFcmToken: Error saving FCM token: $e');
      }
    } else {
      log('[HomeViewModel] _saveFcmToken: Skipped saving token. Token is null or user is not logged in.');
    }
  }

  void _startProjectStream() {
    log('[HomeViewModel] _startProjectStream: Attempting to start project stream.');
    if (currentUserId.value.isEmpty) {
      projects.clear();
      isLoadingProjects.value = false;
      String snackbarMessage = 'Please log in to view projects.';
      log('[HomeViewModel] _startProjectStream: User not logged in. SNACKBAR: Info, $snackbarMessage');
      Utils.snackBar('Info', snackbarMessage);
      return;
    }

    log('[HomeViewModel] _startProjectStream: Subscribing to projects for user ${currentUserId.value}');
    isLoadingProjects.value = true;
    _projectSubscription = _projectService.streamAllProjects().listen(
          (projectList) {
        projects.value = projectList;
        isLoadingProjects.value = false;
        if (projectList.isEmpty) {
          String snackbarMessage = 'No projects available.';
          log('[HomeViewModel] ProjectStream: Received 0 projects for user: ${currentUserId.value}. SNACKBAR: Info, $snackbarMessage');
          Utils.snackBar('Info', snackbarMessage);
        } else {
          log('[HomeViewModel] ProjectStream: Successfully loaded ${projectList.length} projects.');
        }
      },
      onError: (error) {
        isLoadingProjects.value = false;
        String snackbarMessage = 'Failed to load projects: $error';
        log('[HomeViewModel] ProjectStream: ERROR - $error. SNACKBAR: Error, $snackbarMessage');
        Utils.snackBar('Error', snackbarMessage);
      },
    );
  }

  void _startInvitesStream() {
    log('[HomeViewModel] _startInvitesStream: Attempting to start invites stream.');
    if (currentUserId.value.isEmpty) {
      log('[HomeViewModel] _startInvitesStream: Aborted, no current user.');
      return;
    }

    final currentUserEmail = auth.currentUser?.email ?? '';
    if (currentUserEmail.isEmpty) {
      log('[HomeViewModel] _startInvitesStream: Aborted, user has no email.');
      return;
    }

    log('[HomeViewModel] _startInvitesStream: Subscribing to invites for email: $currentUserEmail');
    _invitesSubscription = firestore
        .collection('pending_requests')
        .doc(currentUserEmail)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      pendingInvitesCount.value = snapshot.docs.length;
      log('[HomeViewModel] InvitesStream: Found ${snapshot.docs.length} pending invites.');
    }, onError: (error) {
      log('[HomeViewModel] InvitesStream: ERROR - $error');
    });
  }

  Future<void> selectDeadlineDate() async {
    log('[HomeViewModel] selectDeadlineDate: Opening date picker.');
    final context = Get.context;
    if (context == null) {
      log('[HomeViewModel] selectDeadlineDate: Aborted, Get.context is null.');
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select Project Deadline',
    );

    if (picked != null) {
      final formattedDate = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      deadlineController.text = formattedDate;
      log('[HomeViewModel] selectDeadlineDate: Date picked and formatted: $formattedDate');
    } else {
      log('[HomeViewModel] selectDeadlineDate: Date picker was cancelled.');
    }
  }

  void toggleAccess(bool isEdit) {
    if (isEdit) {
      hasViewAccess.value = true;
      hasEditAccess.value = true;
    } else {
      hasViewAccess.value = true;
      hasEditAccess.value = false;
    }
    log('[HomeViewModel] toggleAccess: Toggled access. CanEdit is now ${hasEditAccess.value}');
  }



  RxMap<String, String> fieldErrors = <String, String>{}.obs;

  bool validateProjectForm() {
    fieldErrors.clear();

    // Validate title
    if (titleController.text.trim().isEmpty) {
      fieldErrors['title'] = 'Project title is required';
    }

    // Validate client name
    if (clientController.text.trim().isEmpty) {
      fieldErrors['client'] = 'Client name is required';
    }

    // Validate location
    if (locationController.text.trim().isEmpty) {
      fieldErrors['location'] = 'Project location is required';
    }

    // Validate deadline
    if (deadlineController.text.trim().isEmpty) {
      fieldErrors['deadline'] = 'Project deadline is required';
    } else {
      // Validate date format and ensure it's not in the past
      try {
        final selectedDate = DateTime.parse(deadlineController.text.trim());
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

        if (selectedDateOnly.isBefore(todayDate)) {
          fieldErrors['deadline'] = 'Deadline cannot be in the past';
        }
      } catch (e) {
        fieldErrors['deadline'] = 'Invalid date format';
      }
    }

    return fieldErrors.isEmpty;
  }

  void clearFieldError(String fieldName) {
    if (fieldErrors.containsKey(fieldName)) {
      fieldErrors.remove(fieldName);
    }
  }

  Future<void> createNewProject() async {
    log('[HomeViewModel] createNewProject: Attempting to create new project.');

    // Validate form first
    if (!validateProjectForm()) {
      String snackbarMessage = 'Please fix the errors in the form.';
      log('[HomeViewModel] createNewProject: Form validation failed. SNACKBAR: Validation Error, $snackbarMessage');
      Utils.snackBar('Validation Error', snackbarMessage);
      return;
    }

    isSavingProject.value = true;
    log('[HomeViewModel] createNewProject: isSavingProject set to true.');

    try {
      final currentOwnerId = auth.currentUser?.uid;
      final currentOwnerName = auth.currentUser?.displayName ?? 'Project Owner';
      final currentOwnerEmail = auth.currentUser?.email ?? 'Unknown';
      log('[HomeViewModel] createNewProject: Owner details - ID: $currentOwnerId, Name: $currentOwnerName, Email: $currentOwnerEmail');

      final ownerCollaborator = Collaborator(
        uid: currentOwnerId!,
        email: currentOwnerEmail,
        name: currentOwnerName,
        canEdit: true,
        photoUrl: '',
        role: 'Project Owner',
      );

      // Create initial project with creation update
      final initialProject = Project(
        id: '',
        title: titleController.text.trim(),
        clientName: clientController.text.trim(),
        location: locationController.text.trim(),
        deadline: DateTime.parse(deadlineController.text.trim()),
        ownerId: currentOwnerId,
        progress: 0.0,
        collaborators: [ownerCollaborator, ...assignedMembers.value],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'In progress',
        lastUpdates: [], // Start with empty updates
      );

      // Add creation update
      final projectWithUpdate = initialProject.addCreationUpdate(
        currentOwnerId,
        currentOwnerName,
      );

      log('[HomeViewModel] createNewProject: Creating project object: ${projectWithUpdate.title}');
      final projectId = await _projectService.createProject(projectWithUpdate);
      log('[HomeViewModel] createNewProject: Project created with ID: $projectId');

      // Add updates for each assigned member invite
      if (assignedMembers.value.isNotEmpty) {
        final updatedProject = await _projectService.getProject(projectId);
        if (updatedProject != null) {
          var projectWithInviteUpdates = updatedProject;
          for (var member in assignedMembers.value) {
            projectWithInviteUpdates = projectWithInviteUpdates.addInviteSentUpdate(
              member.name,
              currentOwnerId,
              currentOwnerName,
            );
          }
          // Save the project with all invite sent updates
          await _projectService.updateProject(projectId, projectWithInviteUpdates);
        }
      }

      log('[HomeViewModel] createNewProject: Sending invites to ${assignedMembers.value.length} members.');
      for (var member in assignedMembers.value) {
        await _sendInvite(member.email, projectId);
      }

      _clearProjectForm();

      String snackbarMessage = 'Project created successfully!';
      log('[HomeViewModel] createNewProject: Success. SNACKBAR: Success, $snackbarMessage');
      Utils.snackBar('Success', snackbarMessage);

      // Close the bottom sheet only on success
      Get.back();

    } catch (e) {
      String snackbarMessage = 'Failed to create project: $e';
      log('[HomeViewModel] createNewProject: ERROR - $e. SNACKBAR: Error, $snackbarMessage');
      Utils.snackBar('Error', snackbarMessage);
    } finally {
      isSavingProject.value = false;
      log('[HomeViewModel] createNewProject: isSavingProject set to false.');
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
    fieldErrors.clear(); // Clear any existing errors
    log('[HomeViewModel] _clearProjectForm: Project creation form has been cleared.');
  }



  Future<void> _sendInvite(String email, String projectId) async {
    log('[HomeViewModel] _sendInvite: Attempting to send invite to $email for project $projectId.');
    try {
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        String snackbarMessage = 'Not an authorized user: $email';
        log('[HomeViewModel] _sendInvite: User not found in "users" collection. SNACKBAR: Error, $snackbarMessage');
        Utils.snackBar('Error', snackbarMessage);
        return;
      }
      log('[HomeViewModel] _sendInvite: User found. Proceeding to create invite document.');

      final parentDocRef = firestore.collection('pending_requests').doc(email);
      await parentDocRef.set({'createdAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      final inviteRef = parentDocRef.collection('requests').doc();
      await inviteRef.set({
        'projectId': projectId,
        'invitedBy': auth.currentUser!.uid,
        'invitedEmail': email,
        'invitedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      log('[HomeViewModel] _sendInvite: Invite sent successfully to $email.');
    } catch (e) {
      String snackbarMessage = 'Failed to send invite: $e';
      log('[HomeViewModel] _sendInvite: ERROR - $e. SNACKBAR: Error, $snackbarMessage');
      Utils.snackBar('Error', snackbarMessage);
    }
  }

  Future<void> sendMemberInvite() async {
    final name = memberNameController.text.trim();
    final email = memberEmailController.text.trim();
    final role = memberRoleController.text.trim(); // CHANGED: Get from text field

    // Set default role if empty
    final finalRole = role.isEmpty ? 'Member' : role;

    log('[HomeViewModel] sendMemberInvite: Attempting to add member: Name: $name, Email: $email, Role: $finalRole');

    if (name.isEmpty || email.isEmpty || !GetUtils.isEmail(email)) {
      String snackbarMessage = 'Please enter a valid name and email address.';
      log('[HomeViewModel] sendMemberInvite: Validation failed. SNACKBAR: Validation, $snackbarMessage');
      Utils.snackBar('Validation', snackbarMessage);
      return;
    }

    isInvitingMember.value = true;
    log('[HomeViewModel] sendMemberInvite: isInvitingMember set to true.');

    try {
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        String snackbarMessage = 'Not an authorized user.';
        log('[HomeViewModel] sendMemberInvite: User not found. SNACKBAR: Error, $snackbarMessage');
        Utils.snackBar('Error', snackbarMessage);
        return;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;
      final userName = userData['displayName'] ?? name;
      final userPhotoUrl = userData['photoUrl'] ?? '';

      if (assignedMembers.any((member) => member.email == email)) {
        String snackbarMessage = '$userName is already invited.';
        log('[HomeViewModel] sendMemberInvite: Member already invited. SNACKBAR: Info, $snackbarMessage');
        Utils.snackBar('Info', snackbarMessage);
        return;
      }

      final newMember = Collaborator(
        uid: userId,
        email: email,
        name: userName,
        canEdit: hasEditAccess.value,
        photoUrl: userPhotoUrl,
        role: finalRole, // CHANGED: Use the custom role
      );

      assignedMembers.add(newMember);
      Get.back();

      // Clear all form fields
      memberNameController.clear();
      memberEmailController.clear();
      memberRoleController.clear(); // ADD THIS: Clear role field

      String snackbarMessage = '$userName added with role $finalRole.';
      log('[HomeViewModel] sendMemberInvite: Member added to local list. SNACKBAR: Success, $snackbarMessage');
      Utils.snackBar('Success', snackbarMessage);
    } catch (e) {
      String snackbarMessage = 'Failed to invite member: $e';
      log('[HomeViewModel] sendMemberInvite: ERROR - $e. SNACKBAR: Error, $snackbarMessage');
      Utils.snackBar('Error', snackbarMessage);
    } finally {
      isInvitingMember.value = false;
      log('[HomeViewModel] sendMemberInvite: isInvitingMember set to false.');
    }
  }

  Future<void> acceptInvite(String inviteId, String projectId) async {
    log('[HomeViewModel] acceptInvite: Attempting to accept invite $inviteId for project $projectId.');
    try {
      final user = auth.currentUser!;
      final currentUserEmail = user.email ?? '';
      final currentUserName = user.displayName ?? user.email!.split('@')[0];
      log('[HomeViewModel] acceptInvite: Current user email: $currentUserEmail, name: $currentUserName');

      final collaborator = {
        'uid': user.uid,
        'email': user.email,
        'name': currentUserName,
        'canEdit': false, // Default access on accepting
        'photoUrl': user.photoURL ?? '',
        'role': 'Member', // Default role on accepting
      };
      log('[HomeViewModel] acceptInvite: Created collaborator object for user.');

      // First, get the current project to add the update
      final currentProject = await _projectService.getProject(projectId);
      if (currentProject == null) {
        throw Exception('Project not found');
      }

      // Add invite accepted update
      final updatedProject = currentProject.addInviteAcceptedUpdate(
        currentUserName,
        user.uid,
        currentUserName,
      );

      // Update the project with the new update and collaborator
      await firestore.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayUnion([collaborator]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the invite status
      await firestore
          .collection('pending_requests')
          .doc(currentUserEmail)
          .collection('requests')
          .doc(inviteId)
          .update({'status': 'accepted'});

      log('[HomeViewModel] acceptInvite: Updated invite status to "accepted" and added user to project.');

      String snackbarMessage = 'You have joined the project!';
      log('[HomeViewModel] acceptInvite: Success. SNACKBAR: Success, $snackbarMessage');
      Utils.snackBar('Success', snackbarMessage);
    } catch (e) {
      String snackbarMessage = 'Failed to accept invite: $e';
      log('[HomeViewModel] acceptInvite: ERROR - $e. SNACKBAR: Error, $snackbarMessage');
      Utils.snackBar('Error', snackbarMessage);
    }
  }

  Future<void> declineInvite(String inviteId, String projectId) async {
    log('[HomeViewModel] declineInvite: Attempting to decline invite $inviteId for project $projectId.');
    try {
      final user = auth.currentUser!;
      final currentUserEmail = user.email ?? '';
      final currentUserName = user.displayName ?? user.email!.split('@')[0];
      log('[HomeViewModel] declineInvite: Current user email: $currentUserEmail, name: $currentUserName');

      // First, get the current project to add the update
      final currentProject = await _projectService.getProject(projectId);
      if (currentProject != null) {
        // Add invite declined update
        final updatedProject = currentProject.addInviteDeclinedUpdate(
          currentUserName,
          user.uid,
          currentUserName,
        );

        // Update the project with the decline update
        await firestore.collection('projects').doc(projectId).update({
          'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Update the invite status
      await firestore
          .collection('pending_requests')
          .doc(currentUserEmail)
          .collection('requests')
          .doc(inviteId)
          .update({'status': 'rejected'});

      String snackbarMessage = 'Invite declined.';
      log('[HomeViewModel] declineInvite: Success, invite status set to "rejected". SNACKBAR: Info, $snackbarMessage');
      Utils.snackBar('Info', snackbarMessage);
    } catch (e) {
      String snackbarMessage = 'Failed to decline invite: $e';
      log('[HomeViewModel] declineInvite: ERROR - $e. SNACKBAR: Error, $snackbarMessage');
      Utils.snackBar('Error', snackbarMessage);
    }
  }

  @override
  void onClose() {
    log('[HomeViewModel] onClose: Disposing controllers and cancelling subscriptions.');
    _projectSubscription.cancel();
    _invitesSubscription.cancel();
    titleController.dispose();
    clientController.dispose();
    locationController.dispose();
    deadlineController.dispose();
    memberNameController.dispose();
    memberEmailController.dispose();
    memberRoleController.dispose();
    super.onClose();
  }
}