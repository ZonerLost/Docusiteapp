import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/project_details/edit_images.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ChooseFromGallery extends StatefulWidget {
  @override
  State<ChooseFromGallery> createState() => _ChooseFromGalleryState();
}

class _ChooseFromGalleryState extends State<ChooseFromGallery> {
  // Track selected indices
  final Set<int> _selectedIndices = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: "Back",
        actions: [
          if (_selectedIndices.isNotEmpty)
            Center(
              child: MyText(
                text:
                    '${_selectedIndices.length} ${_selectedIndices.length == 1 ? 'item' : 'items'} Selected',
                size: 12,
                weight: FontWeight.w500,
                color: kQuaternaryColor,
                paddingRight: 8,
              ),
            ),
          Center(
            child: Container(
              width: 80,
              child: MyButton(
                buttonText: 'Next',
                onTap: () {
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
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 135,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: 15,
        itemBuilder: (BuildContext context, int index) {
          final isSelected = _selectedIndices.contains(index);
          return GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorderColor, width: 1.0),
                  ),
                  child: CommonImageView(
                    height: Get.height,
                    width: Get.width,
                    radius: 0,
                    url: dummyImg,
                    fit: BoxFit.cover,
                  ),
                ),
                if (isSelected)
                  Container(
                    height: Get.height,
                    width: Get.width,
                    color: kTertiaryColor.withValues(alpha: 0.4),
                    padding: EdgeInsets.all(8),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Image.asset(Assets.imagesSelected, height: 24),
                    ),
                  ),
              ],
            ),
          );
        },
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
