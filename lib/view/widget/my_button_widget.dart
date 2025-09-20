import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import 'my_text_widget.dart';

// ignore: must_be_immutable
class MyButton extends StatelessWidget {
  MyButton({
    required this.buttonText,
    required this.onTap,
    this.height = 48,
    this.textSize,
    this.weight,
    this.radius,
    this.customChild,
    this.bgColor,
    this.textColor,
    this.disabled = false,
  });

  final String buttonText;
  final VoidCallback onTap;
  double? height, textSize, radius;
  FontWeight? weight;
  Widget? customChild;
  Color? bgColor, textColor;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius ?? 12),
          color: bgColor ?? kSecondaryColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onTap,
            splashColor: disabled
                ? Colors.transparent
                : kPrimaryColor.withValues(alpha: 0.1),
            highlightColor: disabled
                ? Colors.transparent
                : kPrimaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(radius ?? 12),
            child:
                customChild ??
                Center(
                  child: MyText(
                    text: buttonText,
                    size: textSize ?? 16,
                    weight: weight ?? FontWeight.w500,
                    color: textColor ?? kPrimaryColor,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class MyBorderButton extends StatelessWidget {
  MyBorderButton({
    required this.buttonText,
    required this.onTap,
    this.height = 48,
    this.textSize,
    this.weight,
    this.radius,
    this.customChild,
    this.textColor,
    this.bgColor,
    this.borderColor,
  });

  final String buttonText;
  final VoidCallback onTap;
  double? height, textSize, radius;
  FontWeight? weight;
  Widget? customChild;
  Color? textColor;
  Color? bgColor;
  Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? 12),
        border: Border.all(
          color: borderColor ?? textColor ?? kSecondaryColor,
          width: 1,
        ),
        color: bgColor ?? Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: kTertiaryColor.withValues(alpha: 0.1),
          highlightColor: kTertiaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(radius ?? 12),
          child:
              customChild ??
              Center(
                child: MyText(
                  text: buttonText,
                  size: textSize ?? 16,
                  weight: weight ?? FontWeight.w500,
                  color: textColor ?? kTertiaryColor,
                ),
              ),
        ),
      ),
    );
  }
}
