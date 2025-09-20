import 'package:docu_site/constants/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
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

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Account Created!',
      'subTitle': 'Your account has been successfully created.',
      'time': '12 mins ago',
      'unread': true,
    },
    {
      'title': 'Image Added',
      'subTitle': 'Your captured image has been uploaded successfully.',
      'time': '12 mins ago',
      'unread': false,
    },
    {
      'title': 'Project Invitation',
      'subTitle':
          'You have received a project invitation from admin. Tap to view',
      'time': '12 mins ago',
      'unread': true,
    },
    {
      'title': 'Account Created!',
      'subTitle': 'Your account has been successfully created.',
      'time': '12 mins ago',
      'unread': false,
    },
    {
      'title': 'Project Invitation',
      'subTitle':
          'You have received a project invitation from admin. Tap to view',
      'time': '12 mins ago',
      'unread': true,
    },
    {
      'title': 'Account Created!',
      'subTitle': 'Your account has been successfully created.',
      'time': '12 mins ago',
      'unread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(
        title: "Notifications",
        actions: [
          Center(
            child: MyText(
              text: 'Clear All',
              size: 16,
              weight: FontWeight.w500,
              color: kRedColor,
              paddingRight: 20,
            ),
          ),
        ],
      ),
      body: _showEmpty
          ? _EmptyState()
          : ListView.separated(
              physics: BouncingScrollPhysics(),
              shrinkWrap: true,
              padding: AppSizes.DEFAULT,
              itemCount: _notifications.length,
              itemBuilder: (ctx, index) {
                return _NotificationTile(
                  title: _notifications[index]['title']!,
                  subTitle: _notifications[index]['subTitle']!,
                  time: _notifications[index]['time']!,
                  unread: _notifications[index]['unread'] ?? false,
                );
              },
              separatorBuilder: (ctx, index) {
                return Container(
                  height: 1,
                  color: kBorderColor,
                  margin: EdgeInsets.symmetric(vertical: 12),
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title, subTitle, time;
  final bool unread;
  const _NotificationTile({
    required this.title,
    required this.time,
    required this.subTitle,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: kSecondaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: MyText(
                text: title.characters.first,
                size: 16,
                weight: FontWeight.bold,
                color: kSecondaryColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MyText(
                          text: title,
                          size: 14,
                          weight: FontWeight.w500,
                        ),
                      ),
                      MyText(
                        text: time,
                        size: 12,
                        weight: FontWeight.w500,
                        color: kQuaternaryColor,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      spacing: 20,
                      children: [
                        Expanded(
                          child: subTitle.contains('Tap to view')
                              ? RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.3,
                                      fontFamily: AppFonts.SFProDisplay,
                                      fontWeight: FontWeight.w500,
                                      color: kQuaternaryColor,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: subTitle.split('Tap to view')[0],
                                      ),
                                      TextSpan(
                                        text: 'Tap to view',
                                        style: TextStyle(
                                          color: kSecondaryColor,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      if (subTitle.split('Tap to view').length >
                                          1)
                                        TextSpan(
                                          text: subTitle.split(
                                            'Tap to view',
                                          )[1],
                                        ),
                                    ],
                                  ),
                                )
                              : MyText(
                                  paddingTop: 0,
                                  text: subTitle,
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: kQuaternaryColor,
                                ),
                        ),
                        if (unread)
                          Icon(Icons.circle, size: 8, color: kSecondaryColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        Image.asset(Assets.imagesNotificationBell, height: 64),
        MyText(
          text: 'No Notifications Yet!',
          paddingTop: 16,
          weight: FontWeight.w500,
          size: 18,
          textAlign: TextAlign.center,
        ),
        MyText(
          text: 'No Notifications to be shown yet.',
          paddingTop: 6,
          lineHeight: 1.5,
          weight: FontWeight.w500,
          size: 14,
          color: kQuaternaryColor,
          textAlign: TextAlign.center,
          paddingBottom: 20,
        ),
        SizedBox(height: 100),
      ],
    );
  }
}
