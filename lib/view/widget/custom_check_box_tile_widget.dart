import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';

class CustomCheckBoxTile extends StatelessWidget {
  const CustomCheckBoxTile({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xffFFC39C) : kFillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kSecondaryColor : kInputBorderColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: MyText(text: title, size: 14, weight: FontWeight.w500),
            ),
            CustomCheckBox(
              isActive: isSelected,
              onTap: onTap,
              radius: 22,
              unSelectedColor: kQuaternaryColor,
              circularRadius: 100,
            ),
          ],
        ),
      ),
    );
  }
}
