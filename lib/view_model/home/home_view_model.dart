import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void onInit() {
    _initAuthState();
    super.onInit();
  }

  void _initAuthState() {
    auth.authStateChanges().listen((User? user) {
      if (user != null) {
        currentUserId.value = user.uid;
        _startProjectStream();
        _startInvitesStream();
      } else {
        currentUserId.value = '';
        projects.clear();
        pendingInvitesCount.value = 0;
        isLoadingProjects.value = false;
      }
    });
  }

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
          print('No projects found for user: ${currentUserId.value}');
          Utils.snackBar('Info', 'No projects available.');
        } else {
          print('Loaded ${projectList.length} projects');
        }
      },
      onError: (error) {
        isLoadingProjects.value = false;
        print('Firestore Stream Error: $error');
        Utils.snackBar('Error', 'Failed to load projects: $error');
      },
    );
  }

  void _startInvitesStream() {
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
    }, onError: (error) {
      print('Invites Stream Error: $error');
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

      final Project newProject = Project(
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
      );

      final projectId = await _projectService.createProject(newProject);

      for (var member in assignedMembers.value) {
        await _sendInvite(member.email, projectId);
      }

      _clearProjectForm();
    } catch (e) {
      print('Error creating project: $e');
      Utils.snackBar('Error', 'Failed to create project: $e');
    } finally {
      isSavingProject.value = false;
    }
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
      print('Error sending invite: $e');
      Utils.snackBar('Error', 'Failed to send invite: $e');
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

  Future<void> sendMemberInvite() async {
    final name = memberNameController.text.trim();
    final email = memberEmailController.text.trim();
    final role = selectedMemberRole.value;

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

      if (assignedMembers.any((member) => member.email == email)) {
        Utils.snackBar('Info', '$userName is already invited.');
        return;
      }

      final newMember = Collaborator(
        uid: userId,
        email: email,
        name: userName,
        canEdit: hasEditAccess.value,
        photoUrl: userPhotoUrl,
        role: role,
      );

      assignedMembers.add(newMember);
      Get.back();
      memberNameController.clear();
      memberEmailController.clear();
      selectedMemberRole.value = Project.roleOptions.first;
      Utils.snackBar('Success', '$userName added with role $role.');
    } catch (e) {
      print('Error inviting member: $e');
      Utils.snackBar('Error', 'Failed to invite member: $e');
    } finally {
      isInvitingMember.value = false;
    }
  }

  Future<void> acceptInvite(String inviteId, String projectId) async {
    try {
      final user = auth.currentUser!;
      final currentUserEmail = user.email ?? '';
      final collaborator = {
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? user.email!.split('@')[0],
        'canEdit': false,
        'photoUrl': user.photoURL ?? '',
        'role': 'Member',
      };

      await firestore
          .collection('pending_requests')
          .doc(currentUserEmail)
          .collection('requests')
          .doc(inviteId)
          .update({'status': 'accepted'});

      await firestore.collection('projects').doc(projectId).update({
        'collaborators': FieldValue.arrayUnion([collaborator]),
      });

      Utils.snackBar('Success', 'You have joined the project!');
    } catch (e) {
      print('Error accepting invite: $e');
      Utils.snackBar('Error', 'Failed to accept invite: $e');
    }
  }

  Future<void> declineInvite(String inviteId) async {
    try {
      final currentUserEmail = auth.currentUser?.email ?? '';
      await firestore
          .collection('pending_requests')
          .doc(currentUserEmail)
          .collection('requests')
          .doc(inviteId)
          .update({'status': 'rejected'});
      Utils.snackBar('Info', 'Invite declined.');
    } catch (e) {
      print('Error declining invite: $e');
      Utils.snackBar('Error', 'Failed to decline invite: $e');
    }
  }

  @override
  void onClose() {
    _projectSubscription.cancel();
    _invitesSubscription.cancel();
    titleController.dispose();
    clientController.dispose();
    locationController.dispose();
    deadlineController.dispose();
    memberNameController.dispose();
    memberEmailController.dispose();
    super.onClose();
  }
}
