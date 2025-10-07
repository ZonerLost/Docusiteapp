import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/auth/login/login.dart';
import 'package:docu_site/view/screens/home/home.dart'; // <-- make sure you have this screen
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Run after delay
    Future.delayed(const Duration(milliseconds: 1200), () => checkUser());
  }

  Future<void> checkUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User already logged in → Go to Home
      Get.offAll(() => Home());
    } else {
      // No user logged in → Go to Login
      Get.offAll(() => Login());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kPrimaryColor,
      child: Padding(
        padding: AppSizes.DEFAULT,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MyText(text: '', size: 16),
            Center(child: Image.asset(Assets.imagesLogo, height: 120)),
            MyText(
              text: 'Powered by Docusite',
              size: 16,
              textAlign: TextAlign.center,
              weight: FontWeight.w500,
              color: kQuaternaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
