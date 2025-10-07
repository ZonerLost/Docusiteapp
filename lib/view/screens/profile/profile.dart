import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/profile/language.dart';
import 'package:docu_site/view/screens/profile/terms_condition.dart';
import 'package:docu_site/view/widget/custom_dialog_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/screens/profile/change_password.dart';
import 'package:docu_site/view/screens/profile/edit_profile.dart';
import 'package:docu_site/view/screens/profile/help_and_support.dart';
import 'package:docu_site/view/screens/profile/privacy_policy.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:get/get.dart';

import '../../../config/routes/route_names.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final controller = ValueNotifier<bool>(false);
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance of Firebase Auth

  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed(RouteName.loginPage);
    } catch (e) {
      Get.snackbar('Logout Error', 'Failed to sign out: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'User Profile'),
      body: ListView(
        shrinkWrap: true,
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          // Use StreamBuilder to listen for user data changes from FirebaseAuth
          StreamBuilder<User?>(
            stream: _auth.authStateChanges(),
            builder: (context, snapshot) {
              final User? user = snapshot.data;

              // Determine values, using safe fallbacks
              final String displayName = user?.displayName ?? 'Guest User';
              final String email = user?.email ?? 'N/A';
              final String photoUrl = user?.photoURL ?? '';

              // Note: The dummy image reference is now removed/managed by conditional logic

              return GestureDetector(
                onTap: () {
                  Get.to(() => const EditProfile());
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kFillColor,
                    border: Border.all(color: kBorderColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(width: 1.0, color: kSecondaryColor),
                        ),
                        child: CommonImageView(
                          height: 48,
                          width: 48,
                          radius: 100.0,
                          // Use the fetched photo URL, or a local asset fallback
                          url: photoUrl.isNotEmpty ? photoUrl : dummyImg,
                          // Fallback to local asset if no URL
                          imagePath: photoUrl.isEmpty ? Assets.imagesCamera : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MyText(
                              size: 16,
                              weight: FontWeight.w700,
                              text: displayName, // Display user's name
                            ),
                            MyText(
                              paddingTop: 6,
                              size: 14,
                              weight: FontWeight.w500,
                              color: kQuaternaryColor,
                              text: email, // Display user's email
                            ),
                          ],
                        ),
                      ),
                      Image.asset(Assets.imagesArrowNext, height: 24),
                    ],
                  ),
                ),
              );
            },
          ),

          MyText(
            text: 'GENERAL',
            size: 12,
            letterSpacing: 1.0,
            weight: FontWeight.w500,
            color: kQuaternaryColor,
            paddingTop: 12,
            paddingBottom: 12,
          ),
          Container(
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border.all(color: kBorderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              itemCount: 3,
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: const NeverScrollableScrollPhysics(), // Important: inside ListView
              separatorBuilder: (BuildContext context, int index) {
                return Container(
                  height: 1,
                  color: kBorderColor,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                );
              },
              itemBuilder: (BuildContext context, int index) {
                final details = [
                  {
                    'icon': Assets.imagesChangePassword,
                    'title': 'Change Password',
                  },
                  {'icon': Assets.imagesLanguage, 'title': 'Language'},
                  {
                    'icon': Assets.imagesEnableNotifications,
                    'title': 'Enable Notifications',
                  },
                ];
                final detail = details[index];
                return _ProfileTile(
                  icon: detail['icon'] ?? '',
                  title: detail['title'] ?? '',
                  trailing: index == 2
                      ? AdvancedSwitch(
                    controller: controller,
                    activeColor: kSecondaryColor,
                    inactiveColor: const Color(0xffDADADA),
                    activeChild: Image.asset(Assets.imagesOff, height: 8),
                    inactiveChild: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Image.asset(Assets.imagesOn, height: 8),
                    ),
                    borderRadius: BorderRadius.circular(50),
                    width: 40.0,
                    height: 24.0,
                    enabled: true,
                    disabledOpacity: 0.5,
                    onChanged: (newValue) {
                      setState(() {
                        controller.value = newValue;
                      });
                    },
                  )
                      : null,
                  onTap: () {
                    switch (index) {
                      case 0:
                        Get.to(() =>  ChangePassword());
                        break;
                      case 1:
                        Get.to(() => const Languages());
                        break;
                      case 2:
                        break;
                    }
                  },
                );
              },
            ),
          ),
          MyText(
            text: 'SUPPORT',
            size: 12,
            weight: FontWeight.w500,
            color: kQuaternaryColor,
            paddingTop: 12,
            letterSpacing: 1.0,
            paddingBottom: 12,
          ),
          Container(
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border.all(color: kBorderColor, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: ListView.separated(
              itemCount: 4,
              shrinkWrap: true,
              padding: AppSizes.ZERO,
              physics: const NeverScrollableScrollPhysics(), // Important: inside ListView
              separatorBuilder: (BuildContext context, int index) {
                return Container(
                  height: 1,
                  color: kBorderColor,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                );
              },
              itemBuilder: (BuildContext context, int index) {
                final details = [
                  {
                    'icon': Assets.imagesHelpAndSupport,
                    'title': 'Help & Support',
                  },
                  {
                    'icon': Assets.imagesTermsConditions,
                    'title': 'Terms & Conditions',
                  },
                  {'icon': Assets.imagesPrivacy, 'title': 'Privacy Policy'},
                  {'icon': Assets.imagesLogout, 'title': 'Logout'},
                ];
                final detail = details[index];
                return _ProfileTile(
                  icon: detail['icon'] ?? '',
                  title: detail['title'] ?? '',
                  showArrow: index < 3,
                  onTap: () {
                    switch (index) {
                      case 0:
                        Get.to(() => const HelpAndSupport());
                        break;
                      case 1:
                        Get.to(() =>  TermsCondition());
                        break;
                      case 2:
                        Get.to(() =>  PrivacyPolicy());
                        break;
                      case 3:
                        Get.bottomSheet(
                          CustomDialog(
                            image: Assets.imagesLogoutIcon,
                            title: 'Logout?',
                            subTitle:
                            'Are you sure want to logout from this app?',
                            buttonText: 'Yes, Logout',
                            onTap: logout,
                          ),
                          isScrollControlled: false,
                        );
                        break;
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showArrow = true,
    this.trailing,
  });
  final String icon;
  final String title;
  final VoidCallback onTap;
  final bool showArrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Image.asset(icon, height: 20),
          Expanded(child: MyText(paddingLeft: 12, text: title, size: 16)),
          if (trailing != null)
            trailing!
          else if (showArrow)
            Image.asset(Assets.imagesArrowNext, height: 24),
        ],
      ),
    );
  }
}