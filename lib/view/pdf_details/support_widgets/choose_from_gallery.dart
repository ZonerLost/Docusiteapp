import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/pdf_details/support_widgets/edit_images.dart';
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
                  Get.to(() => EditImages());
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

