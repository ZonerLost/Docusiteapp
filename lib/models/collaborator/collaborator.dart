import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/date_parse/date_parse_service.dart';

class Collaborator {
  final String uid;
  final String email;
  final String name;
  final bool canEdit;
  final String photoUrl;
  final String role;

  Collaborator({
    required this.uid,
    required this.email,
    required this.name,
    required this.canEdit,
    this.photoUrl = '',
    this.role = 'Member',
  });

  factory Collaborator.fromMap(Map<String, dynamic> map) {
    final email = (map['email'] ?? '').toString();
    final uidRaw = (map['uid'] ?? '').toString();
    return Collaborator(
      uid: uidRaw.isNotEmpty ? uidRaw : email,            // tolerate empty uid
      email: email,
      name: (map['name'] ?? '').toString(),
      canEdit: map['canEdit'] is bool ? map['canEdit'] as bool : false,
      photoUrl: (map['photoUrl'] ?? '').toString(),
      role: ((map['role'] ?? '').toString().isEmpty) ? 'Member' : (map['role'] ?? '').toString(),
    );
  }

  factory Collaborator.fromJson(Map<String, dynamic> json) =>
      Collaborator.fromMap(json);

  factory Collaborator.fromDocument(DocumentSnapshot doc) =>
      Collaborator.fromMap(asMap(doc.data()));

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'name': name,
    'canEdit': canEdit,
    'photoUrl': photoUrl,
    'role': role,
  };

  Map<String, dynamic> toJson() => toMap();
}

