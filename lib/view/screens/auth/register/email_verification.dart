import 'package:docu_site/view/screens/home/home.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/view/widget/custom_dialog_widget.dart';
import 'package:docu_site/view/widget/heading_widget.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';

class VerificationCode extends StatelessWidget {
  const VerificationCode({super.key});

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 54,
      height: 60,
      textStyle: TextStyle(
        fontSize: 30,
        color: kTertiaryColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: kFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          bottom: BorderSide(color: kInputBorderColor, width: 1.0),
        ),
      ),
    );
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
            title: 'Verification Code',
            subTitle:
                'We have sent a verification code on your email address chri******@gmail.com',
          ),
          Pinput(
            length: 5,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: kSecondaryColor.withValues(alpha: 0.1),
                border: Border.all(color: kSecondaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(
                fontSize: 30,
                color: kSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            submittedPinTheme: defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                color: kSecondaryColor.withValues(alpha: 0.1),
                border: Border.all(color: kSecondaryColor),
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: TextStyle(
                fontSize: 30,
                color: kSecondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
            showCursor: true,
            onCompleted: (pin) => print(pin),
          ),
          SizedBox(height: 50),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MyText(
                text: "Didn't receive code?",
                size: 16,
                weight: FontWeight.w500,
                color: kQuaternaryColor,
              ),
              MyText(
                text: " 00:54",
                size: 16,
                weight: FontWeight.w500,
                color: kSecondaryColor,
              ),
            ],
          ),
          SizedBox(height: 20),
          MyButton(
            buttonText: 'Go to home page',
            onTap: () {
              Get.bottomSheet(
                CustomDialog(
                  image: Assets.imagesSuccess,
                  title: 'Account Created !',
                  subTitle:
                      'You have successfully created your account. Enjoy the ride',
                  buttonText: 'Continue',
                  onTap: () {
                    Get.back();
                    Get.to(() => Home());
                  },
                ),
                isScrollControlled: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
