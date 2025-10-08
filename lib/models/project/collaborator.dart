import 'package:cloud_firestore/cloud_firestore.dart';

class Collaborator {
  final String uid;
  final String email;
  final String name;
  final bool canEdit; // true = Edit Access, false = View Access
  final String photoUrl;
  final String role; // e.g. 'Contractor', 'Client', 'Project Owner'

  Collaborator({
    required this.uid,
    required this.email,
    required this.name,
    required this.canEdit,
    this.photoUrl = '',
    this.role = '',
  });

  /// Factory constructor to create from a Map (e.g. Firestore data)
  factory Collaborator.fromMap(Map<String, dynamic> map) {
    return Collaborator(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      canEdit: map['canEdit'] ?? false,
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] ?? '',
    );
  }

  /// Factory constructor to create from JSON (e.g. REST API or local storage)
  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      canEdit: json['canEdit'] ?? false,
      photoUrl: json['photoUrl'] ?? '',
      role: json['role'] ?? '',
    );
  }

  /// Factory to create from Firestore DocumentSnapshot
  factory Collaborator.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Collaborator.fromMap(data);
  }

  /// Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'canEdit': canEdit,
      'photoUrl': photoUrl,
      'role': role,
    };
  }

  /// Convert to JSON for local storage or APIs
  Map<String, dynamic> toJson() => toMap();
}
