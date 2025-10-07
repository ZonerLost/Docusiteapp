import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/home/project_invites.dart';
import 'package:docu_site/view/screens/project_details/project_details.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/custom_tag_field_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class All extends StatefulWidget {
  const All({super.key});

  @override
  State<All> createState() => _AllState();
}

class _AllState extends State<All> {
  bool _showEmpty = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showEmpty = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showEmpty) {
      return _EmptyState();
    }
    return Stack(
      children: [
        ListView(
          physics: BouncingScrollPhysics(),
          padding: AppSizes.DEFAULT,
          shrinkWrap: true,
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kFillColor,
                  border: Border.all(color: kBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      Assets.imagesPendingInvites,
                      height: 40,
                      width: 40,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MyText(
                            size: 14,
                            weight: FontWeight.w700,
                            text: '2 Pending Invites',
                          ),
                          MyText(
                            paddingTop: 4,
                            size: 12,
                            color: kQuaternaryColor,
                            text: 'You have received 2 new projects invites.',
                          ),
                        ],
                      ),
                    ),
                    Image.asset(Assets.imagesArrowNext, height: 24),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            ListView.builder(
              physics: BouncingScrollPhysics(),
              padding: AppSizes.ZERO,
              shrinkWrap: true,
              itemCount: 10,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Get.to(() => ProjectDetails(projectId: '',));
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kFillColor,
                      border: Border.all(color: kBorderColor, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                spacing: 4,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    text: 'Hotel Al-Buraak',
                                    size: 14,
                                    weight: FontWeight.w500,
                                  ),
                                  MyText(
                                    text:
                                        'John Smith  |  St 3 Wilsons road, California',
                                    color: kQuaternaryColor,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Stack(
                                children: List.generate(3, (index) {
                                  return Container(
                                    margin: EdgeInsets.only(
                                      left: index == 0 ? 0 : index * 16.0,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: kFillColor,
                                        width: 1,
                                      ),
                                    ),
                                    child: CommonImageView(
                                      height: 24,
                                      width: 24,
                                      radius: 100,
                                      url: dummyImg,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          spacing: 6,
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kGreyColor2,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    width: 1.0,
                                    color: kBorderColor,
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: AppFonts.SFProDisplay,
                                      color: kGreyColor3.withValues(alpha: 0.7),
                                    ),
                                    children: [
                                      TextSpan(text: 'Last updated: '),
                                      TextSpan(
                                        text: '2 mins ago',
                                        style: TextStyle(
                                          color: kTertiaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kGreyColor2,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    width: 1.0,
                                    color: kBorderColor,
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: AppFonts.SFProDisplay,
                                      color: kGreyColor3.withValues(alpha: 0.7),
                                    ),
                                    children: [
                                      TextSpan(text: 'Deadline: '),
                                      TextSpan(
                                        text: 'Oct 20, 2025',
                                        style: TextStyle(
                                          color: kTertiaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kGreyColor2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MyText(
                                text: 'Progress',
                                size: 12,
                                paddingBottom: 5,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearPercentIndicator(
                                      lineHeight: 8.0,
                                      percent: 0.44,
                                      padding: AppSizes.ZERO,
                                      backgroundColor: kFillColor,
                                      progressColor: kSecondaryColor,
                                      barRadius: Radius.circular(50),
                                    ),
                                  ),
                                  MyText(text: '44%', paddingLeft: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          left: 70,
          right: 70,
          child: MyButton(
            buttonText: '+ Add new project',
            onTap: () {
              Get.bottomSheet(_AddNewProject(), isScrollControlled: true);
            },
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(Assets.imagesNoProjects, height: 64),
        MyText(
          text: 'No Projects Added Yet!',
          paddingTop: 16,
          weight: FontWeight.w500,
          size: 18,
          textAlign: TextAlign.center,
        ),
        MyText(
          text: 'Your projects will be shown up here.\nTap to add new project.',
          paddingTop: 6,
          lineHeight: 1.5,
          weight: FontWeight.w500,
          size: 14,
          color: kQuaternaryColor,
          textAlign: TextAlign.center,
          paddingBottom: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            SizedBox(
              width: 125,
              child: MyButton(
                bgColor: kFillColor,
                height: 40,
                buttonText: 'View Invites',
                onTap: () {
                  Get.to(() => ProjectInvites());
                },
                radius: 12,
                textSize: 14,
                textColor: kQuaternaryColor,
              ),
            ),
            SizedBox(
              width: 125,
              child: MyButton(
                height: 40,
                buttonText: '+ Add new',
                onTap: () {
                  Get.bottomSheet(_AddNewProject(), isScrollControlled: true);
                },
                radius: 12,
                textSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 100),
      ],
    );
  }
}

class _AddNewProject extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.8,
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
            text: 'Create new project',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Please enter the correct information to add a new project.',
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
                  labelText: 'Project Title',
                  hintText: '200sq ft 4 bedroom Villa',
                ),
                SimpleTextField(
                  labelText: 'Client name',
                  hintText: 'John Smith',
                ),
                SimpleTextField(
                  labelText: 'Project location',
                  hintText: 'St 3 Wilsons Road, California, USA',
                ),
                SimpleTextField(
                  labelText: 'Project Deadline',
                  hintText: 'October 20, 2025',
                ),
                Row(
                  children: [
                    Expanded(
                      child: MyText(
                        text: 'Assign Members',
                        size: 14,
                        weight: FontWeight.w500,
                        color: kQuaternaryColor,
                      ),
                    ),
                    MyText(
                      onTap: () {
                        Get.bottomSheet(
                          _InviteNewMember(),
                          isScrollControlled: true,
                        );
                        ;
                      },
                      text: '+ Invite new member',
                      size: 14,
                      weight: FontWeight.w500,
                      color: kSecondaryColor,
                    ),
                  ],
                ),
                SizedBox(height: 4),
                CustomTagField(),
                SizedBox(height: 4),
                Row(
                  spacing: 20,
                  children: List.generate(2, (index) {
                    return Row(
                      spacing: 4,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomCheckBox(
                          circularRadius: 5,
                          isActive: true,
                          onTap: () {},
                          radius: 20,
                        ),
                        MyText(
                          text: index == 0 ? 'View Access' : 'Edit Access',
                          size: 14,
                          weight: FontWeight.w500,
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          MyButton(buttonText: 'Add', onTap: () {}),
        ],
      ),
    );
  }
}

class _InviteNewMember extends StatelessWidget {
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
            text: 'Invite new member',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Please enter the correct information to add a new member.',
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
                  labelText: 'Member Name',
                  hintText: 'Chris Taylor',
                ),
                SimpleTextField(
                  labelText: 'Member email address',
                  hintText: 'chris345@gmail.com',
                ),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Send Invite ',
            onTap: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
