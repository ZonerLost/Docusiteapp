import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseTs(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp) return v.toDate();
  if (v is String) {
    try { return DateTime.parse(v); } catch (_) {}
  }
  if (v is int) {
    try { return DateTime.fromMillisecondsSinceEpoch(v); } catch (_) {}
  }
  return null;
}

double parseDouble(dynamic v, {double fallback = 0.0}) {
  if (v is num) return v.toDouble();
  if (v is String) {
    final d = double.tryParse(v);
    if (d != null) return d;
  }
  return fallback;
}

int parseInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) {
    final n = int.tryParse(v);
    if (n != null) return n;
  }
  return fallback;
}

List<Map<String, dynamic>> asListOfMap(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
  }
  return const [];
}

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map) return v.cast<String, dynamic>();
  return const {};
}