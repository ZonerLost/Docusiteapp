import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/utils.dart';

// ignore: must_be_immutable
class CustomCheckBox extends StatelessWidget {
  CustomCheckBox({
    Key? key,
    required this.isActive,
    required this.onTap,
    this.circularRadius,
    this.radius,
    this.unSelectedColor,
  }) : super(key: key);

  final bool isActive;
  final VoidCallback onTap;
  final Color? unSelectedColor;
  double? circularRadius;
  double? radius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 230),
        curve: Curves.easeInOut,
        height: radius ?? 24,
        width: radius ?? 24,
        decoration: BoxDecoration(
          border: Border.all(
            width: 1,
            color: isActive ? kSecondaryColor : unSelectedColor ?? kBorderColor,
          ),
          color: isActive ? kSecondaryColor : kFillColor,
          borderRadius: BorderRadius.circular(circularRadius ?? 8),
        ),
        child: !isActive
            ? SizedBox()
            : circularRadius == 100
            ? Container(
                margin: EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kFillColor,
                ),
              )
            : Icon(
                Icons.check,
                size: (radius == 24) ? 16 : 12,
                color: kPrimaryColor,
              ),
      ),
    );
  }
}

class CustomRadio extends StatelessWidget {
  CustomRadio({
    Key? key,
    required this.isActive,
    required this.onTap,
    this.unSelectedColor,
  }) : super(key: key);

  final bool isActive;
  final VoidCallback onTap;
  final Color? unSelectedColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 230),
        curve: Curves.easeInOut,
        height: 16,
        width: 16,
        padding: EdgeInsets.all(3.2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isActive
                ? kSecondaryColor
                : (unSelectedColor ?? Color(0xffB1BCFF).withValues(alpha: 0.5)),
            width: 1.0,
          ),
          color: isActive ? kSecondaryColor : kPrimaryColor,
          shape: BoxShape.circle,
        ),
        child: !isActive
            ? SizedBox()
            : Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  height: Get.height,
                  width: Get.width,
                ),
              ),
      ),
    );
  }
}
