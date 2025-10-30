import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/pdf_details/support_widgets/choose_from_gallery.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class PdfOpenCamera extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        haveBorder: false,
        contentColor: kFillColor,
        bgColor: kTertiaryColor,
        title: "Back",
        actions: [
          Center(
            child: Container(
              width: 120,
              child: MyButton(
                buttonText: 'Next',
                onTap: () {},
                height: 36,
                textSize: 14,
              ),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          CommonImageView(
            height: Get.height,
            width: Get.width,
            radius: 0,
            url: dummyImg,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              color: kTertiaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.to(() => ChooseFromGallery());
                    },
                    child: Image.asset(
                      Assets.imagesGallery,
                      height: 32,
                      width: 32,
                    ),
                  ),
                  Image.asset(Assets.imagesCapture, height: 72, width: 72),
                  SizedBox(width: 32, height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
