import 'package:docu_site/view/screens/profile/policies/policy_screen.dart';
import 'package:flutter/material.dart';


class TermsCondition extends StatelessWidget {
  const TermsCondition({super.key});
  @override
  Widget build(BuildContext context) =>
      const PolicyScreen(title: 'Terms & Conditions', docId: 'terms_and_conditions');
}