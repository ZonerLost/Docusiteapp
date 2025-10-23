import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushToggleService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _messaging = FirebaseMessaging.instance;

  static DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  /// Live stream of the user's notificationsEnabled state.
  static Stream<bool> enabledStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream<bool>.empty();
    return _userRef(uid).snapshots().map((d) {
      final data = d.data() ?? {};
      // If the field is missing, treat as enabled (default true).
      final enabled = data['notificationsEnabled'];
      if (enabled is bool) return enabled;
      return (data['fcmToken'] ?? '') is String && (data['fcmToken'] ?? '').toString().isNotEmpty;
    });
  }

  /// Turn notifications ON: ask permission, get token, save to Firestore.
  static Future<void> enable() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    // iOS/Android 13+: ask for permission
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      throw Exception('Notifications permission denied');
    }

    // Get or refresh token
    String? token = await _messaging.getToken();
    if (token == null || token.isEmpty) {
      // Sometimes token is null right after permission; try a refresh:
      await _messaging.deleteToken();
      token = await _messaging.getToken();
    }

    final platform = Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : (kIsWeb ? 'web' : 'other'));

    await _userRef(user.uid).set({
      'fcmToken': token ?? '',
      'notificationsEnabled': true,
      'pushPlatform': platform,
      'pushUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Turn notifications OFF: delete local token and clear from Firestore.
  static Future<void> disable() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    // Delete device token (so this device stops getting pushes)
    try {
      await _messaging.deleteToken();
    } catch (_) {/* ignore */}

    await _userRef(user.uid).set({
      'notificationsEnabled': false,
      'pushUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also remove token server-side (optional but tidy)
    await _userRef(user.uid).update({'fcmToken': FieldValue.delete()}).catchError((_) {});
  }
}
