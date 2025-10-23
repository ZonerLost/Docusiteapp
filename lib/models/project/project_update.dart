
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/date_parse/date_parse_service.dart';

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
      id: (data['id'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? '').toString(),
      timestamp: parseTs(data['timestamp']) ?? DateTime.now(),
      type: (data['type'] ?? 'updated').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'message': message,
    'userId': userId,
    'userName': userName,
    'timestamp': Timestamp.fromDate(timestamp),
    'type': type,
  };

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) =>
      ProjectUpdate.fromMap(json);

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

