import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/auth/login/login.dart';
import 'package:docu_site/view/screens/home/home.dart';
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
    Future.delayed(const Duration(milliseconds: 1200), () => checkAuthentication());
  }

  Future<void> checkAuthentication() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      print('Splash Screen Debug:');
      print('- Firebase User: ${user?.email}');
      print('- User UID: ${user?.uid}');

      if (user != null) {
        // User is authenticated with Firebase - go directly to Home
        print('- User is authenticated, going to Home');
        Get.offAll(() => Home());
      } else {
        // No user authenticated - go to Login
        print('- No authenticated user, going to Login');
        Get.offAll(() => Login());
      }
    } catch (e) {
      print('Error in splash screen: $e');
      // If any error occurs, go to login screen
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