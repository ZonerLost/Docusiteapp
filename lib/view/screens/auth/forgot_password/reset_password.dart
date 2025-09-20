import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/view/screens/auth/login/login.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/heading_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';

class ResetPassword extends StatefulWidget {
  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
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
            title: 'Reset Password!',
            subTitle:
                "Please create your new password and try not to share with anyone.",
          ),
          MyTextField(
            labelText: 'Create new password',
            hintText: '********',
            isObSecure: true,
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesVisibility, height: 24)],
            ),
          ),
          MyTextField(
            labelText: 'Confirm new password',
            hintText: '********',
            isObSecure: true,
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesVisibility, height: 24)],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        child: MyButton(
          buttonText: 'Back to Login',
          onTap: () {
            Get.offAll(() => Login());
          },
        ),
      ),
    );
  }
}
