import 'package:cloud_firestore/cloud_firestore.dart';
import 'collaborator.dart';
import 'project_file.dart';

class Project {
  final String id;
  final String title;
  final String ownerId;
  final String clientName;
  final String status;
  final String location;
  final DateTime deadline;
  final List<Collaborator> collaborators; // List of members on the project
  final List<ProjectFile> files; // List of files associated with the project
  final double progress; // <--- ADDED: Project completion progress (0.0 to 1.0)
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.clientName,
    required this.status,
    required this.location,
    required this.deadline,
    required this.progress, // <--- ADDED to constructor
    this.collaborators = const [],
    this.files = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // List of possible statuses for the UI dropdowns
  static const List<String> statusOptions = ['In Progress', 'Completed', 'On Hold', 'Pending'];

  // Static list of possible collaborator roles for the UI dropdowns
  static const List<String> roleOptions = ['Contractor', 'Client', 'Project Owner', 'Engineer'];

  // Factory to create a Project from a Firestore Document Snapshot
  factory Project.fromSnapshot(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse Collaborators list
    final List<Collaborator> collaborators = (data['collaborators'] as List<dynamic>? ?? [])
        .map((e) => Collaborator.fromMap(e as Map<String, dynamic>))
        .toList();

    // Parse Files list
    // Note: ProjectFile.fromMap handles parsing data retrieved from the 'files' array
    final List<ProjectFile> files = (data['files'] as List<dynamic>? ?? [])
        .map((e) => ProjectFile.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
        .toList();

    // Helper to safely parse numbers which might be stored as int or double in Firestore
    double parseProgress(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0; // Default to 0% progress
    }

    return Project(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Project',
      ownerId: data['ownerId'] as String? ?? 'unknown',
      clientName: data['clientName'] as String? ?? 'N/A',
      status: data['status'] as String? ?? Project.statusOptions.first,
      location: data['location'] as String? ?? 'Not specified',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: parseProgress(data['progress']), // <--- ADDED: Parse progress
      collaborators: collaborators,
      files: files,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Project to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'ownerId': ownerId,
      'clientName': clientName,
      'status': status,
      'location': location,
      'deadline': Timestamp.fromDate(deadline),
      'progress': progress, // <--- ADDED: Save progress
      'collaborators': collaborators.map((c) => c.toMap()).toList(),
      'files': files.map((f) => f.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
