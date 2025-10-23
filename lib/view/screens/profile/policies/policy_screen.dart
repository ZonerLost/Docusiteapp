import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({
    super.key,
    required this.title,
    required this.docId, // "privacy_policy" or "terms_and_conditions"
  });

  final String title;
  final String docId;

  Stream<DocumentSnapshot<Map<String, dynamic>>> _stream() {
    return FirebaseFirestore.instance
        .collection("app_policies")
        .doc(docId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: title),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snap.hasError) {
            return Center(child: Text("Failed to load $title"));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(child: Text("No $title found."));
          }

          final data = snap.data!.data()!;
          final html = (data["html"] ?? "").toString();
          final ts = data["updatedAt"];
          DateTime? updatedAt;
          if (ts is Timestamp) updatedAt = ts.toDate();

          return ListView(
            padding: AppSizes.DEFAULT,
            physics: const BouncingScrollPhysics(),
            children: [
              if (updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Last updated: ${updatedAt.toLocal()}",
                    style: TextStyle(fontSize: 12, color: kQuaternaryColor),
                  ),
                ),
              Html(
                data: html,
                style: {
                  "body": Style(fontSize: FontSize(14), lineHeight: LineHeight.em(1.55)),
                  "h3": Style(fontWeight: FontWeight.w700),
                  "h4": Style(fontWeight: FontWeight.w600),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

