import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseTs(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) { try { return DateTime.parse(v); } catch (_) {} }
  if (v is int) { try { return DateTime.fromMillisecondsSinceEpoch(v); } catch (_) {} }
  return null;
}

int _asInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) {
    final n = int.tryParse(v);
    if (n != null) return n;
  }
  return fallback;
}

class ProjectFile {
  final String id;
  final String fileName;
  final String fileUrl;         // Firebase Storage URL
  final String category;        // e.g., 'STRUCTURAL', 'MVP', 'Architectural'
  final String uploadedBy;      // uploader name/uid (your data varies; keep as String)
  final DateTime? lastUpdated;  // make nullable to tolerate missing
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

  /// Strict id + tolerant fields
  factory ProjectFile.fromMap(Map<String, dynamic> map, String id) {
    return ProjectFile(
      id: id,
      fileName: (map['fileName'] ?? '').toString(),
      fileUrl: (map['fileUrl'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      uploadedBy: (map['uploadedBy'] ?? '').toString(),
      lastUpdated: _parseTs(map['lastUpdated']),
      newCommentsCount: _asInt(map['newCommentsCount']),
      newImagesCount: _asInt(map['newImagesCount']),
    );
  }

  /// If your item maps don’t carry their own id, use this and pass a synthetic id if needed.
  factory ProjectFile.fromMapLoose(Map<String, dynamic> map) =>
      ProjectFile.fromMap(map, (map['id'] ?? '').toString());

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'category': category,
      'uploadedBy': uploadedBy,
      if (lastUpdated != null) 'lastUpdated': Timestamp.fromDate(lastUpdated!),
      'newCommentsCount': newCommentsCount,
      'newImagesCount': newImagesCount,
    };
  }

  factory ProjectFile.fromJson(Map<String, dynamic> json) {
    return ProjectFile(
      id: (json['id'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      fileUrl: (json['fileUrl'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      uploadedBy: (json['uploadedBy'] ?? '').toString(),
      // Accept ISO string or epoch or Timestamp in JSON too
      lastUpdated: _parseTs(json['lastUpdated']),
      newCommentsCount: _asInt(json['newCommentsCount']),
      newImagesCount: _asInt(json['newImagesCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'category': category,
      'uploadedBy': uploadedBy,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'newCommentsCount': newCommentsCount,
      'newImagesCount': newImagesCount,
    };
  }

  factory ProjectFile.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return ProjectFile.fromMap(data, doc.id);
    // Note: this path is usually used if files are a subcollection; if files live in an array on the project doc, use fromMap/fromMapLoose instead.
  }

  factory ProjectFile.fromQueryDocumentSnapshot(QueryDocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});
    return ProjectFile.fromMap(data, doc.id);
  }
}
