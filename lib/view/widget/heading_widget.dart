import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.title,
    required this.subTitle,
    this.marginTop,
  });
  final String? title;
  final String? subTitle;
  final double? marginTop;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: marginTop ?? 70),
        Image.asset(Assets.imagesLogo, height: 72),
        MyText(
          paddingTop: 28,
          text: title ?? '',
          size: 26,
          textAlign: TextAlign.center,
          paddingBottom: 8,
          weight: FontWeight.w500,
        ),
        if (subTitle!.isNotEmpty)
          MyText(
            text: subTitle ?? '',
            size: 14,
            lineHeight: 1.5,
            weight: FontWeight.w500,
            paddingBottom: 24,
            textAlign: TextAlign.center,
            color: kQuaternaryColor,
          ),
      ],
    );
  }
}
