import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/chat/chat_screen.dart';
import 'package:docu_site/view/screens/project_details/pdf_details.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_drop_down_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class ProjectDetails extends StatelessWidget {
  const ProjectDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        body: NestedScrollView(
          physics: BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 480,
                backgroundColor: kFillColor,
                titleSpacing: 0.0,
                leading: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Image.asset(Assets.imagesArrowBack, height: 15),
                    ),
                  ],
                ),
                title: MyText(
                  text: 'Project Details',
                  size: 18,
                  color: kTertiaryColor,
                  weight: FontWeight.w500,
                ),
                elevation: 0,
                actions: [
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Get.bottomSheet(
                        //   _Filter(),
                        //   isScrollControlled: true,
                        // );
                      },
                      child: PopupMenuButton(
                        offset: Offset(0, 40),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(maxWidth: 111),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              value: 'invite',
                              height: 25,
                              onTap: () {
                                Get.bottomSheet(
                                  _AddMember(),
                                  isScrollControlled: true,
                                );
                              },
                              child: MyText(
                                text: 'Invite Member',
                                size: 14,
                                weight: FontWeight.w500,
                              ),
                            ),
                            PopupMenuItem(
                              padding: EdgeInsets.symmetric(horizontal: 10),

                              value: 'edit',
                              height: 25,
                              child: MyText(
                                text: 'Edit Project',
                                size: 14,
                                weight: FontWeight.w500,
                              ),
                            ),
                            PopupMenuItem(
                              padding: EdgeInsets.symmetric(horizontal: 10),

                              value: 'delete',
                              height: 25,
                              child: MyText(
                                text: 'Delete Project',
                                size: 14,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ];
                        },
                        child: Image.asset(
                          Assets.imagesMoreRounded,
                          height: 40,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
                flexibleSpace: Container(
                  color: kFillColor,
                  child: FlexibleSpaceBar(
                    background: ListView(
                      shrinkWrap: true,
                      padding: AppSizes.DEFAULT,
                      physics: BouncingScrollPhysics(),
                      children: [
                        SizedBox(height: 80),
                        Row(
                          children: [
                            Expanded(
                              child: MyText(
                                text: '200sq ft 4 Bedroom Villa',
                                size: 28,
                                weight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(
                              width: 118,
                              child: MyButton(
                                buttonText: 'Group Chat',
                                onTap: () {
                                  Get.to(() => ChatScreen());
                                },
                                textSize: 14,
                                weight: FontWeight.w500,
                                height: 36,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        ...List.generate(6, (index) {
                          final details = [
                            {'title': 'Client name', 'value': 'John Smith'},
                            {'title': 'Status', 'value': 'In Progress'},
                            {
                              'title': 'Location',
                              'value': 'St3 Wilsons road, California, USA',
                            },
                            {
                              'title': 'Project Owner',
                              'value': 'Christopher Henry',
                            },
                            {'title': 'Deadline', 'value': 'Oct 20, 2025'},
                            {'title': 'Members', 'value': '20 members'},
                          ];
                          final bool isStatus =
                              details[index]['title'] == 'Status';
                          return Container(
                            height: 48,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: kBorderColor,
                                  width: 1.0,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: MyText(
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isStatus
                                              ? kOrangeColor.withValues(
                                                  alpha: 0.08,
                                                )
                                              : kGreyColor2,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            width: 1.0,
                                            color: isStatus
                                                ? kOrangeColor.withValues(
                                                    alpha: 0.08,
                                                  )
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
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(50),
                  child: Container(
                    color: kFillColor,
                    child: TabBar(
                      labelPadding: AppSizes.HORIZONTAL,
                      automaticIndicatorColorAdjustment: false,
                      indicatorColor: kSecondaryColor,
                      indicatorWeight: 3,
                      labelColor: kSecondaryColor,
                      unselectedLabelColor: kQuaternaryColor,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        fontFamily: AppFonts.SFProDisplay,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        fontFamily: AppFonts.SFProDisplay,
                      ),
                      tabs: List.generate(2, (index) {
                        final titles = ['Files & Documents', 'Members'];
                        return Tab(text: titles[index]);
                      }),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            physics: BouncingScrollPhysics(),
            children: [_FilesAndDocuments(), _Members()],
          ),
        ),
      ),
    );
  }
}

class _FilesAndDocuments extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: BouncingScrollPhysics(),
      padding: AppSizes.DEFAULT,
      shrinkWrap: true,
      children: [
        MyText(
          text: '+ Add new PDF',
          size: 16,
          weight: FontWeight.w500,
          color: kSecondaryColor,
          paddingBottom: 12,
        ),
        ListView.separated(
          separatorBuilder: (context, index) {
            return SizedBox(height: 8);
          },
          physics: BouncingScrollPhysics(),
          padding: AppSizes.ZERO,
          shrinkWrap: true,
          itemCount: 10,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Get.to(() => PdfDetails());
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kFillColor,
                  border: Border.all(color: kBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          spacing: 6,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(2, (index) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: kRedColor.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  width: 1.0,
                                  color: kRedColor.withValues(alpha: .08),
                                ),
                              ),
                              child: MyText(
                                text: index != 0
                                    ? '2 new comments'
                                    : '2 new images',
                                size: 12,
                                color: kRedColor,
                                weight: FontWeight.w500,
                              ),
                            );
                          }),
                        ),
                      ),

                    Row(
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
                        Image.asset(Assets.imagesArrowNext, height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Members extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: BouncingScrollPhysics(),
      padding: AppSizes.DEFAULT,
      shrinkWrap: true,
      children: [
        MyText(
          onTap: () {
            Get.bottomSheet(_AddMember(), isScrollControlled: true);
          },
          text: '+ Add new member',
          size: 16,
          weight: FontWeight.w500,
          color: kSecondaryColor,
          paddingBottom: 12,
        ),
        ListView.separated(
          separatorBuilder: (context, index) {
            return SizedBox(height: 8);
          },
          physics: BouncingScrollPhysics(),
          padding: AppSizes.ZERO,
          shrinkWrap: true,
          itemCount: 10,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {},
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kFillColor,
                  border: Border.all(color: kBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CommonImageView(
                          height: 40,
                          width: 40,
                          radius: 100,
                          url: dummyImg,
                          fit: BoxFit.cover,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              MyText(
                                size: 14,
                                weight: FontWeight.w700,
                                text: 'Mike Ross',
                              ),
                              MyText(
                                paddingTop: 4,
                                size: 12,
                                color: kQuaternaryColor,
                                text: 'Contractor',
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kRedColor.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              width: 1.0,
                              color: kRedColor.withValues(alpha: .08),
                            ),
                          ),
                          child: MyText(
                            text: 'Remove',
                            size: 12,
                            color: kRedColor,
                            weight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AddMember extends StatelessWidget {
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
            text: 'Add new member',
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
                CustomDropDown(
                  labelText: 'Member role',
                  hintText: 'Contractor',
                  items: ['Contractor', 'Client', 'Project Owner'],
                  selectedValue: 'Contractor',
                  onChanged: (v) {},
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
