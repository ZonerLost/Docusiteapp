import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/home/support_widgets/all.dart';
import 'package:docu_site/view/screens/home/support_widgets/filter.dart';
import 'package:docu_site/view/screens/notifications/notifications.dart';
import 'package:docu_site/view/screens/profile/profile.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/home/home_controller.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());

    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // Search App Bar - Shows when searching
              Obx(() {
                final viewModel = Get.find<HomeController>();
                if (viewModel.isSearching.value) {
                  return _buildSearchAppBar(viewModel);
                }
                return _buildNormalAppBar(viewModel);
              }),
            ];
          },
          body: RefreshIndicator(
            onRefresh: () async {
              final controller = Get.find<HomeController>();
              await controller.refreshProjects();
            },
            color: kSecondaryColor, // optional custom color
            backgroundColor: kFillColor,
            displacement: 40, // distance from top to trigger refresh
            child: TabBarView(
              physics: const AlwaysScrollableScrollPhysics(), // ensures pull works even when content is short
              children: const [
                All(),
                All(filterStatus: 'In progress'),
                All(filterStatus: 'Completed'),
                All(filterStatus: 'Cancelled'),
              ],
            ),
          ),

        ),
      ),
    );
  }

  SliverAppBar _buildNormalAppBar(HomeController viewModel) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 160,
      backgroundColor: kFillColor,
      automaticallyImplyLeading: false,
      titleSpacing: 20.0,
      title: Obx(() {
        final user = viewModel.currentUserId.value;
        final photoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';
        return GestureDetector(
          onTap: () {
            Get.to(() => const Profile());
          },
          child: CommonImageView(
            height: 40,
            width: 40,
            radius: 100,
            url: photoUrl.isNotEmpty ? photoUrl : dummyImg,
            imagePath: photoUrl.isNotEmpty ? photoUrl : dummyImg,
            fit: BoxFit.cover,
          ),
        );
      }),
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
                    Filter(),
                    isScrollControlled: true,
                  );
                },
                child: Image.asset(Assets.imagesFilter, height: 40),
              ),
              GestureDetector(
                onTap: () {
                  viewModel.startSearch();
                },
                child: Image.asset(Assets.imagesSearch, height: 40),
              ),
              GestureDetector(
                onTap: () {
                  Get.to(() => const Notifications());
                },
                child: Image.asset(
                  Assets.imagesNotifications,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
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
        preferredSize: const Size.fromHeight(50),
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
    );
  }

  SliverAppBar _buildSearchAppBar(HomeController viewModel) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: kFillColor,
      automaticallyImplyLeading: false,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: kFillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: TextField(
          controller: viewModel.searchController,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            color: kTertiaryColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search projects by title...',
            hintStyle: TextStyle(
              fontSize: 16,
              color: kQuaternaryColor,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: IconButton(
              icon: Image.asset(Assets.imagesCancelBlue, height: 16),
              onPressed: () {
                viewModel.searchController.clear();
                viewModel.updateSearchQuery('');
              },
            ),
          ),
          onChanged: (value) {
            viewModel.updateSearchQuery(value);
          },
          onSubmitted: (value) {
            viewModel.updateSearchQuery(value);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            viewModel.stopSearch();
          },
          child: MyText(
            text: 'Cancel',
            color: kSecondaryColor,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

