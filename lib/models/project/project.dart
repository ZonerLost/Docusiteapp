import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docu_site/models/project/project_update.dart';
import '../../services/date_parse/date_parse_service.dart';
import '../collaborator/collaborator.dart';
import 'project_file.dart';


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

  /// NEW: single source of truth for dynamic/base-extra fields
  final Map<String, dynamic> extraFields;

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
    this.extraFields = const {}, // NEW
  });

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
    Map<String, dynamic>? extraFields, // NEW
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
      extraFields: extraFields ?? this.extraFields, // NEW
    );
  }

  // Keep the spelling you already use in UI
  static const List<String> statusOptions = [
    'In Progress',
    'Completed',
    'On Hold',
    'Pending'
  ];

  static const List<String> roleOptions = [
    'Contractor',
    'Client',
    'Project Owner',
    'Engineer'
  ];

  static const List<String> reservedFieldNames = [
    'id',
    'title',
    'ownerId',
    'clientName',
    'status',
    'location',
    'deadline',
    'collaborators',
    'files',
    'progress',
    'createdAt',
    'updatedAt',
    'lastUpdates',
    'extraFields', // reserve the container too
  ];

  /// Tolerant factory from Firestore snapshot
  factory Project.fromSnapshot(DocumentSnapshot doc) {
    final data = asMap(doc.data());

    final collaborators = (data['collaborators'] is List)
        ? asListOfMap(data['collaborators'])
        .map((m) => Collaborator.fromMap(m))
        .toList()
        : <Collaborator>[];

    final files = (data['files'] is List)
        ? asListOfMap(data['files'])
        .map((m) => ProjectFile.fromMapLoose(m))
        .toList()
        : <ProjectFile>[];

    final lastUpdates = (data['lastUpdates'] is List)
        ? asListOfMap(data['lastUpdates'])
        .map((m) => ProjectUpdate.fromMap(m))
        .toList()
        : <ProjectUpdate>[];

    final created = parseTs(data['createdAt']) ?? DateTime.now();
    final updated = parseTs(data['updatedAt']) ?? created;
    final deadlineDt = parseTs(data['deadline']) ?? DateTime.now();

    // NEW: read explicit extraFields or harvest legacy top-level extras
    final explicitExtra =
    (data['extraFields'] is Map) ? asMap(data['extraFields']) : <String, dynamic>{};
    final legacyExtra = getAdditionalFieldsFromData(data); // ignores reserved keys
    final mergedExtra = {...legacyExtra, ...explicitExtra}; // prefer explicit map

    return Project(
      id: doc.id,
      title: (data['title'] ?? 'Untitled Project').toString(),
      ownerId: (data['ownerId'] ?? 'unknown').toString(),
      clientName: (data['clientName'] ?? 'N/A').toString(),
      status: (data['status'] ?? statusOptions.first).toString(),
      location: (data['location'] ?? 'Not specified').toString(),
      deadline: deadlineDt,
      progress: parseDouble(data['progress']),
      collaborators: collaborators,
      files: files,
      lastUpdates: lastUpdates,
      createdAt: created,
      updatedAt: updated,
      extraFields: mergedExtra, // NEW
    );
  }

  /// Map for Firestore writes (general update)
  Map<String, dynamic> toMap() {
    return {
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
      'extraFields': extraFields, // NEW
    };
  }

  Map<String, dynamic> toCreateMap() {
    return {
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
      'updatedAt': Timestamp.fromDate(updatedAt),
      'extraFields': extraFields, // NEW
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
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
      'updatedAt': FieldValue.serverTimestamp(),
      'extraFields': extraFields, // NEW
    };
  }

  /// Harvest legacy top-level extra fields (for backwards compatibility)
  static Map<String, dynamic> getAdditionalFieldsFromData(
      Map<String, dynamic> data) {
    final additionalFields = <String, dynamic>{};
    for (final key in data.keys) {
      if (!reservedFieldNames.contains(key)) {
        additionalFields[key] = data[key];
      }
    }
    return additionalFields;
  }

  /// Tolerant fromJson
  factory Project.fromJson(Map<String, dynamic> json) {
    final data = asMap(json);

    final collaborators = (data['collaborators'] is List)
        ? asListOfMap(data['collaborators'])
        .map((m) => Collaborator.fromMap(m))
        .toList()
        : <Collaborator>[];

    final files = (data['files'] is List)
        ? asListOfMap(data['files'])
        .map((m) => ProjectFile.fromMapLoose(m))
        .toList()
        : <ProjectFile>[];

    final lastUpdates = (data['lastUpdates'] is List)
        ? asListOfMap(data['lastUpdates'])
        .map((m) => ProjectUpdate.fromMap(m))
        .toList()
        : <ProjectUpdate>[];

    final created = parseTs(data['createdAt']) ?? DateTime.now();
    final updated = parseTs(data['updatedAt']) ?? created;
    final deadlineDt = parseTs(data['deadline']) ?? DateTime.now();

    final extra = (data['extraFields'] is Map)
        ? asMap(data['extraFields'])
        : <String, dynamic>{};

    return Project(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      clientName: (data['clientName'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      deadline: deadlineDt,
      ownerId: (data['ownerId'] ?? '').toString(),
      progress: parseDouble(data['progress']),
      collaborators: collaborators,
      files: files,
      lastUpdates: lastUpdates,
      createdAt: created,
      updatedAt: updated,
      status: (data['status'] ?? 'In progress').toString(),
      extraFields: extra, // NEW
    );
  }


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

    final updatedLastUpdates = [newUpdate, ...lastUpdates];
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
