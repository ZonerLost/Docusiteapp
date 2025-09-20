import 'dart:async';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/auth/login/login.dart';
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
    splashScreenHandler();
  }

  void splashScreenHandler() {
    Timer(Duration(milliseconds: 1200), () => Get.offAll(() => Login()));
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
