import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:get/get.dart';

class EditProfile extends StatelessWidget {
  const EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: "Edit Profile"),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: kFillColor,
              border: Border.all(width: 1.0, color: kBorderColor),
            ),
            child: Row(
              children: [
                CommonImageView(
                  height: 44,
                  width: 44,
                  radius: 100.0,
                  url: dummyImg,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MyText(
                        text: "Upload Profile Photo",
                        size: 15,
                        weight: FontWeight.w500,
                      ),
                      MyText(
                        paddingTop: 4,
                        text: "File size (100 mb max)",
                        size: 12,
                        weight: FontWeight.w500,
                        color: kQuaternaryColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: MyBorderButton(
                    borderColor: kSecondaryColor,
                    height: 30,
                    buttonText: '',
                    onTap: () {},
                    radius: 8,
                    customChild: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText(
                          paddingLeft: 6,
                          paddingRight: 4,
                          text: "Upload",
                          size: 12,
                          color: kSecondaryColor,
                          weight: FontWeight.w500,
                        ),
                        Image.asset(
                          Assets.imagesArrowDropdown,
                          height: 16,
                          color: kSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          MyText(
            text: 'PERSONAL INFORMATION',
            size: 12,
            weight: FontWeight.w500,
            color: kQuaternaryColor,
            paddingTop: 16,
            letterSpacing: 1.0,
            paddingBottom: 16,
          ),
          MyTextField(labelText: "Full Name", hintText: 'Kevin Backer'),
          MyTextField(
            labelText: "Email Address",
            hintText: 'Kevinbacker234@gmail.com',
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        child: MyButton(
          buttonText: "Update",
          onTap: () {
            Get.back();
          },
        ),
      ),
    );
  }
}
