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
    this.isLoading = false,
  });

  final String buttonText;
  final VoidCallback? onTap; // Already nullable
  double? height, textSize, radius;
  FontWeight? weight;
  Widget? customChild;
  Color? bgColor, textColor;
  final bool disabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isInactive = disabled || isLoading;

    return Opacity(
      opacity: isInactive ? 0.5 : 1.0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius ?? 12),
          color: bgColor ?? kSecondaryColor,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isInactive ? null : onTap,
            splashColor: isInactive ? Colors.transparent : kPrimaryColor.withOpacity(0.1),
            highlightColor: isInactive ? Colors.transparent : kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(radius ?? 12),
            child: customChild ??
                Center(
                  child: isLoading
                      ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        textColor ?? kPrimaryColor,
                      ),
                    ),
                  )
                      : MyText(
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
    this.disabled = false, // Added to support disabled state
  });

  final String buttonText;
  final VoidCallback? onTap; // Changed to nullable
  double? height, textSize, radius;
  FontWeight? weight;
  Widget? customChild;
  Color? textColor;
  Color? bgColor;
  Color? borderColor;
  final bool disabled; // New field

  @override
  Widget build(BuildContext context) {
    final bool isInactive = disabled || onTap == null; // Consider null onTap as disabled

    return Opacity(
      opacity: isInactive ? 0.5 : 1.0, // Fade when disabled
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius ?? 12),
          border: Border.all(
            color: isInactive
                ? (borderColor ?? textColor ?? kSecondaryColor).withOpacity(0.5)
                : borderColor ?? textColor ?? kSecondaryColor,
            width: 1,
          ),
          color: bgColor ?? Colors.transparent,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isInactive ? null : onTap, // Disable tap when inactive
            splashColor: isInactive ? Colors.transparent : kTertiaryColor.withOpacity(0.1),
            highlightColor: isInactive ? Colors.transparent : kTertiaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(radius ?? 12),
            child: customChild ??
                Center(
                  child: MyText(
                    text: buttonText,
                    size: textSize ?? 16,
                    weight: weight ?? FontWeight.w500,
                    color: isInactive
                        ? (textColor ?? kTertiaryColor).withOpacity(0.5)
                        : textColor ?? kTertiaryColor,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}