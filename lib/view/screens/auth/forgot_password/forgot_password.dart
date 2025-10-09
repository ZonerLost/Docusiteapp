import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/utils/Utils.dart';
import 'package:docu_site/view/screens/auth/forgot_password/reset_password.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_dialog_widget.dart';
import 'package:docu_site/view/widget/heading_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPassword extends StatefulWidget {
  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late TextEditingController _emailController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.snackBar('Error', 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.bottomSheet(
        CustomDialog(
          image: Assets.imagesMailSent,
          title: 'Mail Sent!',
          subTitle:
          'We have sent a password reset link to $email. Please check your email (including spam/junk) to reset your password.',
          buttonText: 'Check Email',
          onTap: () {
            Get.back();
            // Get.to(() => ResetPassword());
          },
        ),
        isScrollControlled: true,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      Utils.snackBar('Error', errorMessage);
    } catch (e) {
      Utils.snackBar('Error', 'Failed to send reset email: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            title: 'Forgot Password',
            subTitle:
            "Please enter the email address associated with your account.",
          ),
          MyTextField(
            controller: _emailController, // Bind to _emailController
            labelText: 'Email address',
            hintText: 'Enter your email',
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesEmail, height: 24)],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            MyButton(
              buttonText: 'Send Password Link',
              isLoading: _isLoading, // Show loading state
              onTap: _sendPasswordResetEmail, // Call Firebase method
            ),
            SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MyText(
                  text: "Back to",
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
                  color: kSecondaryColor,
                  weight: FontWeight.w500,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}