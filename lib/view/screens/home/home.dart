import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/home/all.dart';
import 'package:docu_site/view/screens/notifications/notifications.dart';
import 'package:docu_site/view/screens/profile/profile.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_drop_down_widget.dart';
import 'package:docu_site/view/widget/custom_tag_field_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        body: NestedScrollView(
          physics: BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 160,
                backgroundColor: kFillColor,
                automaticallyImplyLeading: false,
                titleSpacing: 20.0,
                title: GestureDetector(
                  onTap: () {
                    Get.to(() => Profile());
                  },
                  child: CommonImageView(
                    height: 40,
                    width: 40,
                    radius: 100,
                    url: dummyImg,
                    fit: BoxFit.cover,
                  ),
                ),
                shape: Border(
                  bottom: BorderSide(color: kBorderColor, width: 1.0),
                ),
                actions: [
                  Center(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.bottomSheet(
                              _Filter(),
                              isScrollControlled: true,
                            );
                          },
                          child: Image.asset(Assets.imagesFilter, height: 40),
                        ),
                        Image.asset(Assets.imagesSearch, height: 40),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => Notifications());
                          },
                          child: Image.asset(
                            Assets.imagesNotifications,
                            height: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                ],
                flexibleSpace: Container(
                  color: kFillColor,
                  child: FlexibleSpaceBar(
                    background: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText(
                          paddingTop: 40,
                          paddingLeft: 20,
                          text: 'The Site. Simplified.',
                          size: 28,
                          weight: FontWeight.w500,
                        ),
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
                      isScrollable: true,
                      tabs: List.generate(4, (index) {
                        final titles = [
                          'All',
                          'In progress',
                          'Completed',
                          'Cancelled',
                        ];
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
            children: [All(), All(), All(), All()],
          ),
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
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
            text: 'Select Filters',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Please select the filters as per your preferences.',
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
                CustomTagField(labelText: 'Search by Client'),
                CustomTagField(labelText: 'Search by Location'),
                CustomDropDown(
                  labelText: 'Search by progress',
                  hintText: '50%',
                  items: ['0%', '25%', '50%', '75%', '100%'],
                  selectedValue: '50%',
                  onChanged: (v) {},
                ),
                CustomTagField(labelText: 'Search by PDF'),
              ],
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: MyBorderButton(
                  buttonText: 'Reset',
                  onTap: () {},
                  textColor: kQuaternaryColor,
                  bgColor: kFillColor,
                  borderColor: kBorderColor,
                ),
              ),
              Expanded(
                child: MyButton(
                  buttonText: 'Apply Filters',
                  onTap: () {
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
