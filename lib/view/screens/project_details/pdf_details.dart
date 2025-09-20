import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/project_details/pdf_open_camera.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_dialog_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:sheet/sheet.dart';

class PdfDetails extends StatelessWidget {
  const PdfDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return _PdfDetailsSelectable();
  }
}

class _PdfDetailsSelectable extends StatefulWidget {
  @override
  State<_PdfDetailsSelectable> createState() => _PdfDetailsSelectableState();
}

class _PdfDetailsSelectableState extends State<_PdfDetailsSelectable> {
  int selectedIndex = 0;

  final annotationModes = const [
    {'image': Assets.imagesViewFile, 'title': 'View File'},
    {'image': Assets.imagesAnnotate, 'title': 'Annotate'},
    {'image': Assets.imagesDraw, 'title': 'Draw'},
    {'image': Assets.imagesCamera, 'title': 'Camera'},
    {'image': Assets.imagesPens, 'title': 'Pens'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: "Back",
        actions: [
          Center(
            child: Container(
              width: 120,
              child: MyButton(
                buttonText: 'Save & Export',
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
                height: 36,
                textSize: 14,
              ),
            ),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: Stack(
        children: [
          Image.asset(
            Assets.imagesDummyPdf,
            height: Get.height,
            width: Get.width,
            fit: BoxFit.cover,
          ),
          if (selectedIndex == 1)
            Positioned(
              top: 70,
              left: 30,
              child: Image.asset(Assets.imagesAnnotation, height: 200),
            ),
          Center(
            child: _Marker(onTap: () {}, icon: Assets.imagesCameraOnPdf),
          ),
          if (selectedIndex == 1)
            Positioned(
              right: 20,
              bottom: 80,
              child: Column(
                spacing: 8,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (index) {
                  final List<String> _items = [
                    Assets.imagesTt,
                    Assets.imagesEd,
                    Assets.imagesSave,
                    Assets.imagesUn,
                    Assets.imagesRe,
                  ];
                  return _Marker(onTap: () {}, icon: _items[index]);
                }),
              ),
            ),
          Sheet(
            initialExtent: 50,
            minExtent: 50,
            maxExtent: 280,
            child: Container(
              padding: AppSizes.DEFAULT,
              decoration: BoxDecoration(
                color: kFillColor,
                boxShadow: [
                  BoxShadow(
                    color: kTertiaryColor.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(color: kBorderColor, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MyText(
                          text: 'Annotation Modes: ',
                          size: 16,
                          weight: FontWeight.w500,
                        ),
                      ),
                      // Show selected mode icon and title
                      Image.asset(
                        annotationModes[selectedIndex]['image'] as String,
                        height: 16,
                      ),
                      SizedBox(width: 8),
                      MyText(
                        text: annotationModes[selectedIndex]['title'] as String,
                        size: 16,
                        color: kSecondaryColor,
                        weight: FontWeight.w500,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      physics: BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: annotationModes.length,
                      itemBuilder: (context, index) {
                        final mode = annotationModes[index];
                        final isSelected = selectedIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                            if (annotationModes[index]['title'] == 'Pens') {
                              Get.bottomSheet(
                                _AddNotes(),
                                isScrollControlled: true,
                              );
                            } else if (annotationModes[index]['title'] ==
                                'Camera') {
                              Get.to(() => PdfOpenCamera());
                            }
                          },
                          child: Row(
                            children: [
                              Image.asset(mode['image'] as String, height: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: MyText(
                                  text: mode['title'] as String,
                                  size: 16,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              if (isSelected)
                                Image.asset(Assets.imagesTick, height: 20),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return Container(
                          height: 1,
                          color: kBorderColor,
                          margin: EdgeInsets.symmetric(vertical: 12),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.onTap, required this.icon});
  final VoidCallback onTap;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: kTertiaryColor.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(icon, height: 52),
      ),
    );
  }
}

class _AddNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.5,
      margin: EdgeInsets.only(top: 55),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            text: 'Add Notes',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Add important notes to this annotation.',
            color: kQuaternaryColor,
            weight: FontWeight.w500,
            size: 13,
          ),
          Container(
            height: 1,
            color: kBorderColor,
            margin: EdgeInsets.symmetric(vertical: 12),
          ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: BouncingScrollPhysics(),
              children: [
                SimpleTextField(
                  labelText: 'Notes',
                  hintText: 'Add your notes here',
                  maxLines: 5,
                ),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Add',
            onTap: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
