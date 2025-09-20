import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/auth/register/email_verification.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/heading_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:get/get.dart';

class Register extends StatefulWidget {
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        bgColor: Colors.transparent,
        haveLeading: false,
        actions: [
          Center(
            child: MyText(
              text: 'Get Help',
              size: 16,
              weight: FontWeight.w500,
              paddingRight: 20,
              color: kSecondaryColor,
            ),
          ),
        ],
      ),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          AuthHeading(
            marginTop: 0,
            title: 'Register Now',
            subTitle: 'Please enter the Information to get started.',
          ),
          MyTextField(
            controller: _emailController,
            labelText: 'Full name',
            hintText: 'Enter your full name',
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesFullName, height: 24)],
            ),
          ),
          MyTextField(
            controller: _emailController,
            labelText: 'Email address',
            hintText: 'Enter your email',
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesEmail, height: 24)],
            ),
          ),
          MyTextField(
            controller: _passwordController,
            marginBottom: 40,
            labelText: 'Create password',
            hintText: '********',
            isObSecure: true,
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesVisibility, height: 24)],
            ),
          ),

          Row(
            spacing: 8,
            children: [
              CustomCheckBox(isActive: false, onTap: () {}),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: AppFonts.SFProDisplay,
                      color: kTertiaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(
                          fontSize: 16,
                          color: kTertiaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(
                          fontSize: 16,
                          color: kSecondaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle Terms & Conditions tap
                          },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          MyButton(
            buttonText: 'Continue',
            onTap: () {
              Get.to(() => VerificationCode());
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: kBorderColor)),
                MyText(
                  text: 'or sign up',
                  size: 14,
                  color: kQuaternaryColor,
                  paddingLeft: 7,
                  paddingRight: 7,
                ),
                Expanded(child: Container(height: 1, color: kBorderColor)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Image.asset(Assets.imagesGoogle, height: 48),
              Image.asset(Assets.imagesApple, height: 48),
            ],
          ),
          SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MyText(
                text: "Already have an Account?",
                size: 16,
                weight: FontWeight.w500,
                color: kQuaternaryColor,
              ),
              MyText(
                onTap: () {
                  Get.back();
                },
                text: ' Login',
                size: 16,
                weight: FontWeight.w500,
                color: kSecondaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
