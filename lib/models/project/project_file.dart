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
}
