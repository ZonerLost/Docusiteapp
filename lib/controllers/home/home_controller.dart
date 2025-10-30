import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../models/collaborator/collaborator.dart';
import '../../models/project/project.dart';
import '../../../utils/Utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/project_services/firestore_project_services.dart';

class HomeController extends GetxController {
  final ProjectService _projectService = Get.find<ProjectService>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  RxList<Project> projects = <Project>[].obs;
  RxBool isLoadingProjects = true.obs;
  RxString currentUserId = ''.obs;
  RxInt pendingInvitesCount = 0.obs;

  StreamSubscription<List<Project>>? _projectSubscription;
  StreamSubscription<QuerySnapshot>? _invitesSubscription;

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

  // ------------------------------
  // EXTRA FIELDS (CREATE) STATE
  // ------------------------------
  final RxMap<String, dynamic> createExtraFields = <String, dynamic>{}.obs;
  final Map<String, TextEditingController> createKeyControllers = {};
  final Map<String, TextEditingController> createValueControllers = {};


  // In HomeController, update the toggleAccess method and add new methods:

// Remove the old toggleAccess method and replace with these:
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

// Update the sendMemberInvite method to use the correct access values
  Future<void> sendMemberInvite() async {
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
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        Utils.snackBar('Error', 'Not an authorized user.');
        return;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      final userId = userDoc.id;
      final userName = userData['displayName'] ?? name;
      final userPhotoUrl = userData['photoUrl'] ?? '';

      if (assignedMembers.any((m) => m.email == email)) {
        Utils.snackBar('Info', '$userName is already invited.');
        return;
      }

      final newMember = Collaborator(
        uid: userId,
        email: email,
        name: userName,
        canEdit: hasEditAccess.value, // Use the actual edit access value
        photoUrl: userPhotoUrl,
        role: finalRole,
      );

      assignedMembers.add(newMember);
      Get.back();

      memberNameController.clear();
      memberEmailController.clear();
      memberRoleController.clear();

      // Reset access to default after adding member
      hasViewAccess.value = true;
      hasEditAccess.value = false;

      Utils.snackBar('Success', '$userName added with role $finalRole.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to invite member: $e');
    } finally {
      isInvitingMember.value = false;
    }
  }



  void addCreateExtraField(String key, String value) {
    final k = key.trim();
    if (k.isEmpty) return;
    if (Project.reservedFieldNames.contains(k)) {
      Utils.snackBar('Error', '"$k" is a reserved field name and cannot be used.');
      return;
    }
    createExtraFields[k] = value;
    createKeyControllers[k] = TextEditingController(text: k);
    createValueControllers[k] = TextEditingController(text: value);
    update();
  }

  void updateCreateExtraFieldKey(String oldKey, String newKey) {
    if (!createExtraFields.containsKey(oldKey)) return;
    final nk = newKey.trim();
    if (nk.isEmpty) return;
    if (Project.reservedFieldNames.contains(nk)) {
      Utils.snackBar('Error', '"$nk" is a reserved field name and cannot be used.');
      return;
    }
    final val = createExtraFields.remove(oldKey);
    createExtraFields[nk] = val;

    final kc = createKeyControllers.remove(oldKey);
    final vc = createValueControllers.remove(oldKey);
    if (kc != null) createKeyControllers[nk] = kc..text = nk;
    if (vc != null) createValueControllers[nk] = vc;
    update();
  }

  void updateCreateExtraFieldValue(String key, String value) {
    if (!createExtraFields.containsKey(key)) return;
    createExtraFields[key] = value;
    createValueControllers[key]?.text = value;
    update();
  }

  void removeCreateExtraField(String key) {
    if (!createExtraFields.containsKey(key)) return;
    createExtraFields.remove(key);
    createKeyControllers.remove(key)?.dispose();
    createValueControllers.remove(key)?.dispose();
    update();
  }

  void _clearCreateExtraFields() {
    createExtraFields.clear();
    for (final c in createKeyControllers.values) c.dispose();
    for (final c in createValueControllers.values) c.dispose();
    createKeyControllers.clear();
    createValueControllers.clear();
  }
  // ------------------------------

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

  void startSearch() {
    isSearching.value = true;
    searchQuery.value = '';
    searchController.clear();
  }

  void stopSearch() {
    isSearching.value = false;
    searchQuery.value = '';
    searchController.clear();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<Project> get filteredProjects {
    var filtered = projects.where((project) {
      if (searchQuery.isNotEmpty) {
        if (!project.title.toLowerCase().contains(searchQuery.value.toLowerCase())) {
          return false;
        }
      }
      if (filterClient.isNotEmpty) {
        if (!project.clientName.toLowerCase().contains(filterClient.value.toLowerCase())) {
          return false;
        }
      }
      if (filterLocation.isNotEmpty) {
        if (!project.location.toLowerCase().contains(filterLocation.value.toLowerCase())) {
          return false;
        }
      }
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

  void clearFilters() {
    searchQuery.value = '';
    filterClient.value = '';
    filterLocation.value = '';
    filterProgress.value = '';
    filterPdf.value = '';
  }

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
      Utils.snackBar('Info', 'Please log in to view projects.');
      return;
    }

    log('[HomeViewModel] _startProjectStream: Subscribing to projects for user ${currentUserId.value}');
    _projectSubscription?.cancel(); // <— add this
    isLoadingProjects.value = true;
    _projectSubscription = _projectService.streamAllProjects().listen(
          (projectList) {
        projects.value = projectList;
        isLoadingProjects.value = false;
        if (projectList.isEmpty) {
          Utils.snackBar('Info', 'No projects available.');
        } else {
          log('[HomeViewModel] ProjectStream: Successfully loaded ${projectList.length} projects.');
        }
      },
      onError: (error) {
        isLoadingProjects.value = false;
        Utils.snackBar('Error', 'Failed to load projects: $error');
      },
    );
  }

  void _startInvitesStream() {
    log('[HomeViewModel] _startInvitesStream: Attempting to start invites stream.');
    if (currentUserId.value.isEmpty) return;

    final currentUserEmail = auth.currentUser?.email ?? '';
    if (currentUserEmail.isEmpty) return;

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
      final formattedDate =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      deadlineController.text = formattedDate;
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
  }

  RxMap<String, String> fieldErrors = <String, String>{}.obs;

  bool validateProjectForm() {
    fieldErrors.clear();

    if (titleController.text.trim().isEmpty) {
      fieldErrors['title'] = 'Project title is required';
    }
    if (clientController.text.trim().isEmpty) {
      fieldErrors['client'] = 'Client name is required';
    }
    if (locationController.text.trim().isEmpty) {
      fieldErrors['location'] = 'Project location is required';
    }
    if (deadlineController.text.trim().isEmpty) {
      fieldErrors['deadline'] = 'Project deadline is required';
    } else {
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
    // Validate form first
    if (!validateProjectForm()) {
      Utils.snackBar('Validation Error', 'Please fix the errors in the form.');
      return;
    }

    isSavingProject.value = true;

    try {
      final currentOwnerId = auth.currentUser?.uid;
      final currentOwnerName = auth.currentUser?.displayName ?? 'Project Owner';
      final currentOwnerEmail = auth.currentUser?.email ?? 'Unknown';

      final ownerCollaborator = Collaborator(
        uid: currentOwnerId!,
        email: currentOwnerEmail,
        name: currentOwnerName,
        canEdit: true,
        photoUrl: '',
        role: 'Project Owner',
      );

      // Base project (extraFields from create sheet)
      Project baseProject = Project(
        id: '',
        title: titleController.text.trim(),
        clientName: clientController.text.trim(),
        location: locationController.text.trim(),
        deadline: DateTime.parse(deadlineController.text.trim()),
        ownerId: currentOwnerId,
        progress: 0.0,
        collaborators: [ownerCollaborator, ...assignedMembers],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: 'In progress',
        lastUpdates: const [],
        extraFields: Map<String, dynamic>.from(createExtraFields), // <<—— add here
      );

      // Add creation update
      baseProject = baseProject.addCreationUpdate(currentOwnerId, currentOwnerName);

      // Add "field_added" updates for each extra field present at creation
      if (createExtraFields.isNotEmpty) {
        createExtraFields.keys.forEach((k) {
          baseProject = baseProject.addAdditionalFieldUpdate(
            k,
            'added',
            currentOwnerId,
            currentOwnerName,
          );
        });
      }

      // Create in Firestore
      final projectId = await _projectService.createProject(baseProject);

      // Add updates for each assigned member invite (optional)
      if (assignedMembers.isNotEmpty) {
        final updatedProject = await _projectService.getProject(projectId);
        if (updatedProject != null) {
          var withInvites = updatedProject;
          for (var member in assignedMembers) {
            withInvites = withInvites.addInviteSentUpdate(
              member.name,
              currentOwnerId,
              currentOwnerName,
            );
          }
          await _projectService.updateProject(projectId, withInvites);
        }
      }

      for (var member in assignedMembers) {
        await _sendInvite(member.email, projectId);
      }

      _clearProjectForm();
      _clearCreateExtraFields(); // <<—— reset create-time extra fields

      Utils.snackBar('Success', 'Project created successfully!');
      Get.back(); // close sheet on success
    } catch (e) {
      Utils.snackBar('Error', 'Failed to create project: $e');
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
    fieldErrors.clear();
  }

  Future<void> _sendInvite(String email, String projectId) async {
    try {
      final userQuery = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        Utils.snackBar('Error', 'Not an authorized user: $email');
        return;
      }

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
    } catch (e) {
      Utils.snackBar('Error', 'Failed to send invite: $e');
    }
  }


  Future<void> acceptInvite(String inviteId, String projectId) async {
    try {
      final user = auth.currentUser!;
      final currentUserEmail = user.email ?? '';
      final currentUserName = user.displayName ?? user.email!.split('@')[0];

      final collaborator = {
        'uid': user.uid,
        'email': user.email,
        'name': currentUserName,
        'canEdit': false,
        'photoUrl': user.photoURL ?? '',
        'role': 'Member',
      };

      final currentProject = await _projectService.getProject(projectId);
      if (currentProject == null) throw Exception('Project not found');

      final updatedProject = currentProject.addInviteAcceptedUpdate(
        currentUserName,
        user.uid,
        currentUserName,
      );

      await firestore.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayUnion([collaborator]),
        'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await firestore
          .collection('pending_requests')
          .doc(currentUserEmail)
          .collection('requests')
          .doc(inviteId)
          .update({'status': 'accepted'});

      Utils.snackBar('Success', 'You have joined the project!');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to accept invite: $e');
    }
  }

  Future<void> declineInvite(String inviteId, String projectId) async {
    try {
      final user = auth.currentUser!;
      final currentUserEmail = user.email ?? '';
      final currentUserName = user.displayName ?? user.email!.split('@')[0];

      final currentProject = await _projectService.getProject(projectId);
      if (currentProject != null) {
        final updatedProject = currentProject.addInviteDeclinedUpdate(
          currentUserName,
          user.uid,
          currentUserName,
        );
        await firestore.collection('projects').doc(projectId).update({
          'lastUpdates': updatedProject.lastUpdates.map((u) => u.toMap()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await firestore
          .collection('pending_requests')
          .doc(currentUserEmail)
          .collection('requests')
          .doc(inviteId)
          .update({'status': 'rejected'});

      Utils.snackBar('Info', 'Invite declined.');
    } catch (e) {
      Utils.snackBar('Error', 'Failed to decline invite: $e');
    }
  }


  Future<void> refreshProjects() async {
    isLoadingProjects.value = true;
    await Future.delayed(const Duration(seconds: 1)); // optional delay for effect
    _projectSubscription?.cancel();
    _startProjectStream(); // restart project stream
    isLoadingProjects.value = false;
  }


  @override
  void onClose() {
    _projectSubscription?.cancel();
    _invitesSubscription?.cancel();
    titleController.dispose();
    clientController.dispose();
    locationController.dispose();
    deadlineController.dispose();
    memberNameController.dispose();
    memberEmailController.dispose();
    memberRoleController.dispose();
    _clearCreateExtraFields(); // cleanup
    super.onClose();
  }
}
