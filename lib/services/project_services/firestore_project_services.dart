import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../models/project/project.dart';
import '../../utils/Utils.dart';


class ProjectService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // NEW: Reference to the top-level projects collection
  CollectionReference get _projectsCollection => _firestore.collection('projects');

  // Reference to the user's projects subcollection (for quick owner lookup)
  CollectionReference get _userProjectsCollection {
    if (currentUserId == null) {
      throw Exception("User is not authenticated.");
    }
    // Path: users/{userId}/projects
    return _firestore.collection('users').doc(currentUserId).collection('projects');
  }

  /// 1. Create a new project document in Firestore using a Write Batch.
  /// It creates the project in the main /projects collection and adds
  /// a quick reference in the user's /users/{userId}/projects subcollection.
  Future<String> createProject(Project project) async {
    try {
      if (currentUserId == null) {
        throw Exception("Authentication required to create a project.");
      }

      final projectData = project.toMap();

      // Start a new batch operation
      final batch = _firestore.batch();

      // 1. Create a new document reference in the top-level 'projects' collection
      final newProjectDocRef = _projectsCollection.doc();
      final projectId = newProjectDocRef.id;
      print(projectId);

      // Add project data to the main collection
      batch.set(newProjectDocRef, projectData);

      // 2. Add a lightweight reference in the user's subcollection
      // This document only needs the ID and maybe the title for fast dashboard loading
      final userProjectRef = _userProjectsCollection.doc(projectId);
      batch.set(userProjectRef, {
        'projectId': projectId,
        'title': project.title,
        'status': project.status,
        'updatedAt': FieldValue.serverTimestamp(),
        // We will fetch the full project details from the main collection later.
      });

      // Commit the batch
      await batch.commit();

      Utils.snackBar('Success', 'Project "${project.title}" added successfully!');
      return projectId;
    } catch (e) {
      Utils.snackBar('Creation Failed', 'Could not add project: ${e.toString()}');
      rethrow;
    }
  }

  /// 2. Stream all projects where the current user is listed in the /users/{userId}/projects subcollection.
  /// NOTE: This only fetches the lightweight reference documents.
  /// The UI needs to be updated to fetch the full details for the Project Card.
  Stream<List<Project>> streamAllProjects() {
    return _projectsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        print('No projects found in /projects collection');
        return <Project>[];
      }

      final projectsList = <Project>[];
      for (var doc in snapshot.docs) {
        try {
          if (doc.exists && doc.data() != null) {
            projectsList.add(Project.fromSnapshot(doc));
          } else {
            print('Project ${doc.id} has no data or does not exist');
          }
        } catch (e) {
          print('Error parsing project ${doc.id}: $e');
        }
      }
      print('Loaded ${projectsList.length} projects from /projects');
      return projectsList;
    }).handleError((error) {
      print('Stream error: $error');
      return <Project>[];
    });
  }
  /// 3. Stream a single project document from the main collection.
  /// This is used by the Project Details Controller to listen for real-time changes
  /// to the currently viewed project.
  Stream<Project?> streamProject(String projectId) {
    return _projectsCollection.doc(projectId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      // Use the Project.fromSnapshot factory method to convert the document
      return Project.fromSnapshot(snapshot);
    });
  }
}
