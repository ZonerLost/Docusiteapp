import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_dialog_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ReviewPdf extends StatelessWidget {
  const ReviewPdf({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Review PDF'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border.all(color: kBorderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xffF4F4F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset(Assets.imagesPdf, height: 40, width: 40),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MyText(
                              size: 14,
                              weight: FontWeight.w700,
                              text: 'Kitchendrawing.pdf',
                            ),
                            MyText(
                              paddingTop: 4,
                              size: 12,
                              color: kQuaternaryColor,
                              text: 'Last updated : 2 mins ago',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                ...List.generate(7, (index) {
                  final details = [
                    {'title': 'Project Owner', 'value': 'John Smith'},
                    {'title': 'Status', 'value': 'In Progress'},
                    {
                      'title': 'Location',
                      'value': 'St3 Wilsons road, California, USA',
                    },
                    {'title': 'Deadline', 'value': 'Oct 20, 2025'},
                    {'title': 'Members', 'value': '20 members'},
                    {
                      'title': 'Description',
                      'value': 'Lorem ipsum dolor ist amet sonters',
                    },
                    {
                      'title': 'Conclusion',
                      'value': 'Lorem ipsum dolor ist amet sonters',
                    },
                  ];
                  final bool isStatus = details[index]['title'] == 'Status';
                  return Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: kBorderColor, width: 1.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: MyText(
                            size: 12,
                            weight: FontWeight.w500,
                            text: details[index]['title']!,
                            color: kQuaternaryColor,
                          ),
                          flex: 3,
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          height: 48,
                          width: 1,
                          color: kBorderColor,
                        ),
                        Expanded(
                          child: Row(
                            spacing: 12,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (details[index]['title'] == 'Description' ||
                                  details[index]['title'] == 'Conclusion' ||
                                  details[index]['title'] == 'Location')
                                Expanded(
                                  child: MyText(
                                    text: details[index]['value']!,
                                    size: 12,
                                    maxLines: 1,
                                    textOverflow: TextOverflow.ellipsis,
                                    color: kTertiaryColor,
                                    weight: FontWeight.w500,
                                  ),
                                )
                              else
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isStatus
                                        ? kOrangeColor.withValues(alpha: 0.08)
                                        : kGreyColor2,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      width: 1.0,
                                      color: isStatus
                                          ? kOrangeColor.withValues(alpha: 0.08)
                                          : kBorderColor,
                                    ),
                                  ),
                                  child: MyText(
                                    text: details[index]['value']!,
                                    size: 12,
                                    color: isStatus
                                        ? kOrangeColor
                                        : kTertiaryColor,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              Image.asset(Assets.imagesEdit, height: 14),
                            ],
                          ),
                          flex: 7,
                        ),
                      ],
                    ),
                  );
                }),
                Container(height: 1, color: kBorderColor),
                SizedBox(height: 20),
                MyButton(
                  buttonText: 'Download PDF',
                  onTap: () {
                    Get.bottomSheet(
                      CustomDialog(
                        image: Assets.imagesExport,
                        title: 'Export PDF Report',
                        subTitle: 'Are you sure want to export this pdf?',
                        buttonText: 'Yes, Export',
                        onTap: () {
                          Get.back();
                        },
                      ),
                      isScrollControlled: false,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
