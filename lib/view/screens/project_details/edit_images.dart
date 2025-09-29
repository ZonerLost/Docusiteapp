import 'dart:ffi';

import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/project_details/pdf_open_camera.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class EditImages extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: "Back",
        actions: [
          Center(child: Image.asset(Assets.imagesUndo, height: 24)),
          SizedBox(width: 8),
          Center(child: Image.asset(Assets.imagesRedo, height: 24)),
          SizedBox(width: 12),
          Center(
            child: Container(
              width: 80,
              child: MyButton(
                buttonText: 'Done',
                onTap: () {
                  Get.back();
                  Get.back();
                  Get.back();
                  Get.bottomSheet(_AddNotes(), isScrollControlled: true);
                },
                height: 36,
                textSize: 14,
              ),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: PageView.builder(
        itemCount: 5,
        controller: PageController(viewportFraction: 0.92, initialPage: 0),
        physics: BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
            decoration: BoxDecoration(
              border: Border.all(color: kFillColor, width: 3),
            ),
            child: CommonImageView(
              height: Get.height,
              width: Get.width,
              radius: 0,
              url: dummyImg,
              fit: BoxFit.cover,
            ),
          );
        },
      ),

      bottomNavigationBar: Container(
        height: 60,
        padding: AppSizes.HORIZONTAL,
        decoration: BoxDecoration(
          color: kFillColor,
          border: Border(top: BorderSide(color: kBorderColor, width: 1.0)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: kTertiaryColor.withValues(alpha: 0.1),
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6 * 2 - 1, (i) {
            if (i.isOdd) {
              // Divider between items
              return Container(
                width: 1,
                height: 32,
                color: kBorderColor,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              );
            }
            final index = i ~/ 2;
            // Define your menu items here
            final items = [
              _MenuItem(
                icon: Assets.imagesText,
                title: 'Text',
                onTap: () => Get.to(() => PdfOpenCamera()),
              ),
              _MenuItem(icon: Assets.imagesEdit, title: 'Edit', onTap: () {}),
              _MenuItem(icon: Assets.imagesCrop, title: 'Crop', onTap: () {}),
              _MenuItem(
                icon: Assets.imagesDrawIcon,
                title: 'Draw',
                onTap: () {},
              ),
              _MenuItem(
                icon: Assets.imagesRotate,
                title: 'Rotate',
                onTap: () {},
              ),
              _MenuItem(
                icon: Assets.imagesDelete,
                title: 'Delete',
                onTap: () {},
              ),
            ];
            return items[index];
          }),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final String icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(icon, height: 16),
          MyText(
            text: title,
            paddingTop: 6,
            size: 12,
            weight: FontWeight.w500,
            color: kTertiaryColor.withValues(alpha: .7),
          ),
        ],
      ),
    );
  }
}

class _AddNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.5,
      margin: EdgeInsets.only(top: 55),
      padding: EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            paddingLeft: 16,
            paddingRight: 16,
            text: 'Add Notes',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            paddingLeft: 16,
            paddingRight: 16,
            text: 'Add important notes to this annotation.',
            color: kQuaternaryColor,
            weight: FontWeight.w500,
            size: 13,
          ),
          Container(
            height: 1,
            color: kBorderColor,
            margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: BouncingScrollPhysics(),
              children: [
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    itemCount: 4,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      if (index < 3)
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CommonImageView(
                              width: 64,
                              height: 64,
                              radius: 12,
                              fit: BoxFit.cover,
                              url: dummyImg,
                            ),
                            Positioned(
                              top: 0,
                              right: -6,
                              child: Image.asset(
                                Assets.imagesRemoveImage,
                                height: 20,
                              ),
                            ),
                          ],
                        );
                      else
                        return Image.asset(
                          Assets.imagesAddImage,
                          height: 64,
                          width: 64,
                        );
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(width: 18);
                    },
                  ),
                ),
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SimpleTextField(
                    labelText: 'Notes',
                    hintText: 'Add your notes here',
                    maxLines: 5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: MyButton(
              buttonText: 'Add',
              onTap: () {
                Get.back();
                Get.to(() => EditImages());
              },
            ),
          ),
        ],
      ),
    );
  }
}
