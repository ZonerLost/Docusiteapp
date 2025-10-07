import 'package:cloud_firestore/cloud_firestore.dart';

class Collaborator {
  final String uid;
  final String email;
  final String name;
  final bool canEdit; // true for Edit Access, false for View Access
  final String photoUrl;
  final String role; // e.g., 'Contractor', 'Client', 'Project Owner'


  Collaborator({
    required this.uid,
    required this.email,
    required this.name,
    required this.canEdit,
    this.photoUrl = '',
    this.role='',
  });

  // Factory constructor for creating a Collaborator from a Firestore map
  factory Collaborator.fromMap(Map<String, dynamic> map) {
    return Collaborator(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      canEdit: map['canEdit'] ?? false,
      photoUrl: map['photoUrl'] ?? '',
      role: map['role'] as String,

    );
  }

  // Convert Collaborator to a map for Firestore storage
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
}