import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../models/project/project.dart';
import '../../utils/Utils.dart';


class ProjectService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference get _projectsCollection => _firestore.collection('projects');

  CollectionReference get _userProjectsCollection {
    if (currentUserId == null) {
      throw Exception("User is not authenticated.");
    }
    return _firestore.collection('users').doc(currentUserId).collection('projects');
  }


  Future<void> updateProject(String projectId, Project project) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .update(project.toMap());
  }

// In your ProjectService class
  Future<Project?> getProject(String projectId) async {
    try {
      print('🔍 Fetching project from Firestore: $projectId');
      final doc = await _firestore.collection('projects').doc(projectId).get();

      if (doc.exists) {
        print('📄 Document exists, creating Project object');
        final project = Project.fromSnapshot(doc);
        print('✅ Project created: ${project.title}');
        return project;
      } else {
        print('❌ Document does not exist');
        return null;
      }
    } catch (e) {
      print('❌ Error in getProject: $e');
      rethrow;
    }
  }

  // Method to add an update to a project
  Future<void> addProjectUpdate(String projectId, ProjectUpdate update) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .update({
      'lastUpdates': FieldValue.arrayUnion([update.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

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
