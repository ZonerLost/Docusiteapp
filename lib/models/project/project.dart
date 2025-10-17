import 'package:cloud_firestore/cloud_firestore.dart';
import 'collaborator.dart';
import 'project_file.dart';

class ProjectUpdate {
  final String id;
  final String message;
  final String userId;
  final String userName;
  final DateTime timestamp;
  final String type;

  ProjectUpdate({
    required this.id,
    required this.message,
    required this.userId,
    required this.userName,
    required this.timestamp,
    required this.type,
  });

  factory ProjectUpdate.fromMap(Map<String, dynamic> data) {
    return ProjectUpdate(
      id: data['id'] as String? ?? '',
      message: data['message'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String? ?? 'updated',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'userId': userId,
      'userName': userName,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
    };
  }

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) => ProjectUpdate(
    id: json['id'] ?? '',
    message: json['message'] ?? '',
    userId: json['userId'] ?? '',
    userName: json['userName'] ?? '',
    timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    type: json['type'] ?? 'updated',
  );

  // CopyWith method for ProjectUpdate
  ProjectUpdate copyWith({
    String? id,
    String? message,
    String? userId,
    String? userName,
    DateTime? timestamp,
    String? type,
  }) {
    return ProjectUpdate(
      id: id ?? this.id,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
    );
  }
}

class Project {
  final String id;
  final String title;
  final String ownerId;
  final String clientName;
  final String status;
  final String location;
  final DateTime deadline;
  final List<Collaborator> collaborators;
  final List<ProjectFile> files;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ProjectUpdate> lastUpdates;
  // Additional dynamic fields will be stored as top-level fields in Firestore

  Project({
    required this.id,
    required this.title,
    required this.ownerId,
    required this.clientName,
    required this.status,
    required this.location,
    required this.deadline,
    required this.progress,
    this.collaborators = const [],
    this.files = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastUpdates = const [],
  });

  // CopyWith method for Project
  Project copyWith({
    String? id,
    String? title,
    String? ownerId,
    String? clientName,
    String? status,
    String? location,
    DateTime? deadline,
    double? progress,
    List<Collaborator>? collaborators,
    List<ProjectFile>? files,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ProjectUpdate>? lastUpdates,
  }) {
    return Project(
      id: id ?? this.id,
      title: title ?? this.title,
      ownerId: ownerId ?? this.ownerId,
      clientName: clientName ?? this.clientName,
      status: status ?? this.status,
      location: location ?? this.location,
      deadline: deadline ?? this.deadline,
      progress: progress ?? this.progress,
      collaborators: collaborators ?? this.collaborators,
      files: files ?? this.files,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUpdates: lastUpdates ?? this.lastUpdates,
    );
  }

  // List of possible statuses for the UI dropdowns
  static const List<String> statusOptions = ['In Progress', 'Completed', 'On Hold', 'Pending'];

  // Static list of possible collaborator roles for the UI dropdowns
  static const List<String> roleOptions = ['Contractor', 'Client', 'Project Owner', 'Engineer'];

  // List of reserved field names that cannot be used as additional fields
  static const List<String> reservedFieldNames = [
    'id', 'title', 'ownerId', 'clientName', 'status', 'location', 'deadline',
    'collaborators', 'files', 'progress', 'createdAt', 'updatedAt', 'lastUpdates'
  ];

  // Factory to create a Project from a Firestore Document Snapshot
  factory Project.fromSnapshot(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse Collaborators list
    final List<Collaborator> collaborators = (data['collaborators'] as List<dynamic>? ?? [])
        .map((e) => Collaborator.fromMap(e as Map<String, dynamic>))
        .toList();

    // Parse Files list
    final List<ProjectFile> files = (data['files'] as List<dynamic>? ?? [])
        .map((e) => ProjectFile.fromMap(e as Map<String, dynamic>, e['id'] ?? ''))
        .toList();

    // Parse LastUpdates list
    final List<ProjectUpdate> lastUpdates = (data['lastUpdates'] as List<dynamic>? ?? [])
        .map((e) => ProjectUpdate.fromMap(e as Map<String, dynamic>))
        .toList();

    // Helper to safely parse numbers which might be stored as int or double in Firestore
    double parseProgress(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      return 0.0;
    }

    return Project(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Project',
      ownerId: data['ownerId'] as String? ?? 'unknown',
      clientName: data['clientName'] as String? ?? 'N/A',
      status: data['status'] as String? ?? Project.statusOptions.first,
      location: data['location'] as String? ?? 'Not specified',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: parseProgress(data['progress']),
      collaborators: collaborators,
      files: files,
      lastUpdates: lastUpdates,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert Project to a Map for Firestore storage
  // Additional fields will be added to this map dynamically
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'ownerId': ownerId,
      'clientName': clientName,
      'status': status,
      'location': location,
      'deadline': Timestamp.fromDate(deadline),
      'progress': progress,
      'collaborators': collaborators.map((c) => c.toMap()).toList(),
      'files': files.map((f) => f.toMap()).toList(),
      'lastUpdates': lastUpdates.map((u) => u.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return map;
  }

  // Method to get all additional fields from a Firestore document
  static Map<String, dynamic> getAdditionalFieldsFromData(Map<String, dynamic> data) {
    final additionalFields = <String, dynamic>{};

    for (final key in data.keys) {
      if (!reservedFieldNames.contains(key)) {
        additionalFields[key] = data[key];
      }
    }

    return additionalFields;
  }

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    clientName: json['clientName'] ?? '',
    location: json['location'] ?? '',
    deadline: (json['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
    ownerId: json['ownerId'] ?? '',
    progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    collaborators: (json['collaborators'] as List<dynamic>?)?.map((c) => Collaborator.fromJson(c as Map<String, dynamic>)).toList() ?? [],
    files: (json['files'] as List<dynamic>?)?.map((f) => ProjectFile.fromJson(f as Map<String, dynamic>)).toList() ?? [],
    lastUpdates: (json['lastUpdates'] as List<dynamic>?)?.map((u) => ProjectUpdate.fromJson(u as Map<String, dynamic>)).toList() ?? [],
    createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    status: json['status'] ?? 'In progress',
  );

  // Helper method to add a new update with short descriptive messages
  Project addUpdate({
    required String message,
    required String userId,
    required String userName,
    required String type,
  }) {
    final newUpdate = ProjectUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      userId: userId,
      userName: userName,
      timestamp: DateTime.now(),
      type: type,
    );

    // Create a new list with the new update at the beginning
    final updatedLastUpdates = [newUpdate, ...lastUpdates];

    // Limit the number of stored updates to prevent unbounded growth (e.g., keep last 50)
    final limitedLastUpdates = updatedLastUpdates.length > 50
        ? updatedLastUpdates.sublist(0, 50)
        : updatedLastUpdates;

    return copyWith(
      updatedAt: DateTime.now(),
      lastUpdates: limitedLastUpdates,
    );
  }

  static const List<String> updateTypes = [
    'created',
    'updated',
    'file_added',
    'file_deleted',
    'collaborator_added',
    'collaborator_removed',
    'status_changed',
    'progress_updated',
    'info_updated',
    'invite_sent',
    'invite_accepted',
    'invite_declined',
    'field_added',
    'field_updated',
    'field_removed',
  ];

  // New methods for invite tracking
  Project addInviteSentUpdate(String memberName, String userId, String userName) {
    return addUpdate(
      message: 'Invite sent to $memberName',
      userId: userId,
      userName: userName,
      type: 'invite_sent',
    );
  }

  Project addInviteAcceptedUpdate(String memberName, String userId, String userName) {
    return addUpdate(
      message: '$memberName accepted the invite',
      userId: userId,
      userName: userName,
      type: 'invite_accepted',
    );
  }

  Project addInviteDeclinedUpdate(String memberName, String userId, String userName) {
    return addUpdate(
      message: '$memberName declined the invite',
      userId: userId,
      userName: userName,
      type: 'invite_declined',
    );
  }

  // Convenience methods for common update types with short descriptive messages
  Project addCreationUpdate(String userId, String userName) {
    return addUpdate(
      message: 'Project Created',
      userId: userId,
      userName: userName,
      type: 'created',
    );
  }

  Project addFileUpdate(String fileName, String action, String userId, String userName) {
    return addUpdate(
      message: '$fileName is $action in project',
      userId: userId,
      userName: userName,
      type: action == 'added' ? 'file_added' : 'file_deleted',
    );
  }

  Project addCollaboratorUpdate(String collaboratorName, String action, String userId, String userName) {
    return addUpdate(
      message: '$collaboratorName is $action in project',
      userId: userId,
      userName: userName,
      type: action == 'added' ? 'collaborator_added' : 'collaborator_removed',
    );
  }

  Project addStatusUpdate(String newStatus, String userId, String userName) {
    return addUpdate(
      message: 'Project status changed to $newStatus',
      userId: userId,
      userName: userName,
      type: 'status_changed',
    );
  }

  Project addProgressUpdate(double newProgress, String userId, String userName) {
    return addUpdate(
      message: 'Project progress updated to ${(newProgress * 100).toStringAsFixed(0)}%',
      userId: userId,
      userName: userName,
      type: 'progress_updated',
    );
  }

  Project addProjectInfoUpdate(String field, String newValue, String userId, String userName) {
    return addUpdate(
      message: 'Project $field updated to $newValue',
      userId: userId,
      userName: userName,
      type: 'info_updated',
    );
  }

  // Methods for additional field updates
  Project addAdditionalFieldUpdate(String fieldName, String action, String userId, String userName) {
    return addUpdate(
      message: 'Additional field "$fieldName" was $action',
      userId: userId,
      userName: userName,
      type: action == 'added' ? 'field_added' : 'field_updated',
    );
  }

  Project addAdditionalFieldRemovedUpdate(String fieldName, String userId, String userName) {
    return addUpdate(
      message: 'Additional field "$fieldName" was removed',
      userId: userId,
      userName: userName,
      type: 'field_removed',
    );
  }
}