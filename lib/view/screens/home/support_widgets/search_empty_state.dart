import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';




class SearchEmptyState extends StatelessWidget {
  final String query;
  const SearchEmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(Assets.imagesNoProjects, height: 64),
        MyText(
          text: 'No Projects Found',
          paddingTop: 16,
          weight: FontWeight.w500,
          size: 18,
          textAlign: TextAlign.center,
        ),
        MyText(
          text: 'No projects found for "$query".\nTry different keywords.',
          paddingTop: 6,
          lineHeight: 1.5,
          weight: FontWeight.w500,
          size: 14,
          color: kQuaternaryColor,
          textAlign: TextAlign.center,
          paddingBottom: 20,
        ),
      ],
    );
  }
}