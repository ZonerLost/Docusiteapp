import 'package:docu_site/view/screens/home/home.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/auth/forgot_password/forgot_password.dart';
import 'package:docu_site/view/screens/auth/register/register.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/heading_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:get/get.dart';

class Login extends StatefulWidget {
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
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
            title: 'Welcome Back!',
            subTitle: 'Please enter the credentials to get started.',
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
            marginBottom: 12,
            labelText: 'Password',
            hintText: '********',
            isObSecure: true,
            suffix: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Image.asset(Assets.imagesVisibility, height: 24)],
            ),
          ),
          MyText(
            onTap: () {
              Get.to(() => ForgotPassword());
            },
            text: 'Forgot Password?',
            size: 16,
            color: kSecondaryColor,
            weight: FontWeight.w500,
            textAlign: TextAlign.end,
            paddingBottom: 60,
          ),
          Row(
            children: [
              CustomCheckBox(isActive: true, onTap: () {}),
              Expanded(
                child: MyText(
                  text: 'Remember me',
                  size: 16,
                  paddingLeft: 8,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          MyButton(
            buttonText: 'Login',
            onTap: () {
              Get.to(() => Home());
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              children: [
                Expanded(child: Container(height: 1, color: kBorderColor)),
                MyText(
                  text: 'or sign in',
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
                text: "Don’t have an Account?",
                size: 16,
                weight: FontWeight.w500,
                color: kQuaternaryColor,
              ),
              MyText(
                onTap: () {
                  Get.to(() => Register());
                },
                text: ' Register',
                size: 16,
                color: kSecondaryColor,
                weight: FontWeight.w500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
