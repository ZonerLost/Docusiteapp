import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:get/get.dart';
import 'package:get/get_core/get_core.dart';

class Languages extends StatefulWidget {
  const Languages({super.key});

  @override
  State<Languages> createState() => _LanguagesState();
}

class _LanguagesState extends State<Languages> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> languages = [
      {'title': 'English', 'icon': Assets.imagesUk},
      {'title': 'German', 'icon': Assets.imagesGerman},
      {'title': 'Chinese', 'icon': Assets.imagesChinese},
      {'title': 'Dutch', 'icon': Assets.imagesDutch},
      {'title': 'French', 'icon': Assets.imagesFrench},
      {'title': 'Arabic', 'icon': Assets.imagesArabic},
    ];
    return Scaffold(
      appBar: simpleAppBar(title: 'Language'),
      body: ListView.separated(
        separatorBuilder: (context, index) => SizedBox(height: 8),
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kFillColor,
                border: Border.all(
                  width: 1.0,
                  color: selectedIndex == index
                      ? kSecondaryColor
                      : kBorderColor,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset(
                    languages[index]['icon'] ?? '',
                    height: 20,
                    width: 20,
                  ),
                  Expanded(
                    child: MyText(
                      paddingLeft: 10,
                      text: languages[index]['title'] ?? '',
                      size: 16,
                      weight: FontWeight.w500,
                    ),
                  ),
                  CustomCheckBox(
                    isActive: selectedIndex == index,
                    circularRadius: 100,
                    radius: 16,
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        child: MyButton(
          buttonText: "Update",
          onTap: () {
            Get.back();
          },
        ),
      ),
    );
  }
}
