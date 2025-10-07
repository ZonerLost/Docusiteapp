import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Widget _buildContentSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (e.g., "Introduction")
        MyText(
          text: title,
          size: 20,
          weight: FontWeight.w700,
          color: kPrimaryColor, // Assuming a dark/primary color for headings
          paddingBottom: 8,
        ),
        // Content Paragraph 1
        MyText(
          text: content,
          size: 16,
          weight: FontWeight.w400,
          color: kTertiaryColor,
          paddingBottom: 16,
        ),
        // Content Paragraph 2 (Duplicated content for layout simulation)
        MyText(
          text: 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
          size: 16,
          weight: FontWeight.w400,
          color: kTertiaryColor,
          paddingBottom: 24,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        bgColor: Colors.transparent,
        title: 'Help', // Title from the Figma screen
        // Custom back button to match the Figma screen's leading icon

        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
        //   onPressed: () => Get.back(),
        // ),
        haveLeading: true,
      ),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT, // Use your standard padding
        physics: const BouncingScrollPhysics(),
        children: [
          MyText(
            text: 'Get Help',
            size: 24,
            weight: FontWeight.w700,
            color: kPrimaryColor,
            paddingBottom: 32,
          ),

         _buildContentSection(
            title: 'Introduction',
            content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
          ),

          _buildContentSection(
            title: 'Introduction', // Duplicated title structure from Figma
            content: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
          ),
          MyText(
            text: 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
            size: 16,
            weight: FontWeight.w400,
            color: kTertiaryColor,
            paddingBottom: 24,
          ),
          MyText(
            text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            size: 16,
            weight: FontWeight.w400,
            color: kTertiaryColor,
            paddingBottom: 16,
          ),
          MyText(
            text: 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
            size: 16,
            weight: FontWeight.w400,
            color: kTertiaryColor,
            paddingBottom: 24,
          ),
        ],
      ),
    );
  }
}
