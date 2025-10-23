import 'package:docu_site/view/screens/profile/policies/policy_screen.dart';
import 'package:flutter/material.dart';


class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({super.key});
  @override
  Widget build(BuildContext context) =>
      const PolicyScreen(title: 'Privacy Policy', docId: 'privacy_policy');
}