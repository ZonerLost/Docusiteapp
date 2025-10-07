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

import '../../../../view_model/auth/register_view_model.dart';

class Register extends StatelessWidget {
  Register({super.key});

  // Instantiate the controller once
  final RegisterViewModel _viewModel = Get.put(RegisterViewModel());

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
            controller: _viewModel.nameController, // Use controller from ViewModel
            labelText: 'Full name',
            hintText: 'Enter your full name',
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesFullName, height: 24)],
            ),
          ),
          MyTextField(
            controller: _viewModel.emailController, // Use controller from ViewModel
            labelText: 'Email address',
            hintText: 'Enter your email',
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesEmail, height: 24)],
            ),
          ),
          MyTextField(
            controller: _viewModel.passwordController, // Use controller from ViewModel
            marginBottom: 40,
            labelText: 'Create password',
            hintText: '********',
            isObSecure: true,
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesVisibility, height: 24)],
            ),
          ),

          // --- Terms & Conditions Checkbox (Connected to ViewModel) ---
          Obx(
                () => Row(
              spacing: 8,
              children: [
                CustomCheckBox(
                  isActive: _viewModel.agreedToTerms.value,
                  onTap: () {
                    _viewModel.agreedToTerms.toggle(); // Toggle the RxBool state
                  },
                ),
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
                              // Handle Terms & Conditions tap (e.g., navigate to a web view)
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // --- Continue Button (Connected to ViewModel) ---
          Obx(
                () => MyButton(
              buttonText: 'Continue',
              isLoading: _viewModel.loading.value, // Show loading state
              onTap: _viewModel.loading.value ? null : _viewModel.register, // Call the register function
            ),
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
              // Google Sign-In Button
              GestureDetector(
                onTap: _viewModel.loading.value ? null : _viewModel.signInWithGoogle,
                child: Image.asset(Assets.imagesGoogle, height: 48),
              ),

              // Apple Sign-In Button (Conditional for iOS)
              Obx(() {
                if (_viewModel.isAppleSignInAvailable.value) {
                  return GestureDetector(
                    // onTap: _viewModel.loading.value ? null : _viewModel.signInWithApple,
                    child: Image.asset(Assets.imagesApple, height: 48),
                  );
                }
                // If not iOS or not available, don't show the Apple button
                return const SizedBox.shrink();
              }),
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