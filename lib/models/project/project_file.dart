import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectFile {
  final String id;
  final String fileName;
  final String fileUrl; // Firebase Storage URL
  final String category; // e.g., 'STRUCTURAL', 'MVP', 'Architectural'
  final String uploadedBy; // User ID of the uploader
  final DateTime lastUpdated;

  // Placeholder for future features (e.g., to indicate unread annotations/comments)
  final int newCommentsCount;
  final int newImagesCount;

  ProjectFile({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.category,
    required this.uploadedBy,
    required this.lastUpdated,
    this.newCommentsCount = 0,
    this.newImagesCount = 0,
  });

  // Factory constructor to create a ProjectFile from a Firestore Map
  factory ProjectFile.fromMap(Map<String, dynamic> map, String id) {
    return ProjectFile(
      id: id,
      fileName: map['fileName'] as String,
      fileUrl: map['fileUrl'] as String,
      category: map['category'] as String,
      uploadedBy: map['uploadedBy'] as String,
      lastUpdated: (map['lastUpdated'] as Timestamp).toDate(),
      newCommentsCount: map['newCommentsCount'] as int? ?? 0,
      newImagesCount: map['newImagesCount'] as int? ?? 0,
    );
  }

  // Convert ProjectFile to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'category': category,
      'uploadedBy': uploadedBy,
      'lastUpdated': lastUpdated,
      'newCommentsCount': newCommentsCount,
      'newImagesCount': newImagesCount,
    };
  }

  // Factory constructor to create a ProjectFile from JSON
  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String,
      category: json['category'] as String,
      uploadedBy: json['uploadedBy'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      newCommentsCount: json['newCommentsCount'] as int? ?? 0,
      newImagesCount: json['newImagesCount'] as int? ?? 0,
    );
  }

  // Convert ProjectFile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'category': category,
      'uploadedBy': uploadedBy,
      'lastUpdated': lastUpdated.toIso8601String(),
      'newCommentsCount': newCommentsCount,
      'newImagesCount': newImagesCount,
    };
  }

  // Helper method to create from Firestore DocumentSnapshot
  factory ProjectFile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectFile.fromMap(data, doc.id);
  }

  // Helper method to create from QueryDocumentSnapshot
  factory ProjectFile.fromQueryDocumentSnapshot(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectFile.fromMap(data, doc.id);
  }
}