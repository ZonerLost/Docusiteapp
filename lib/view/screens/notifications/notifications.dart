import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:intl/intl.dart';

import '../home/support_widgets/project_invites.dart';

class Notifications extends StatelessWidget {
  const Notifications({super.key});

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

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
              onTap: () async {
                // Clear all notifications for the user
                final notifications = await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(userEmail)
                    .collection('items')
                    .get();
                for (var doc in notifications.docs) {
                  await doc.reference.delete();
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(userEmail)
            .collection('items')
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kSecondaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: MyText(text: 'Error loading notifications'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState();
          }

          final notifications = snapshot.data!.docs;
          return ListView.separated(
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            padding: AppSizes.DEFAULT,
            itemCount: notifications.length,
            itemBuilder: (ctx, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final title = notification['title'] ?? 'Notification';
              final subTitle = notification['subTitle'] ?? '';
              final time = (notification['time'] as Timestamp?)?.toDate() ?? DateTime.now();
              final unread = notification['unread'] ?? false;
              final type = notification['type'] ?? '';

              return _NotificationTile(
                title: title,
                subTitle: subTitle,
                time: _formatTime(time),
                unread: unread,
                type: type,
                notificationId: notificationId,
                onTap: () {
                  if (type == 'project_invite') {
                    // Navigate to ProjectInvites for project invitation notifications
                    Get.to(() => ProjectInvites());
                    // Mark notification as read
                    FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(userEmail)
                        .collection('items')
                        .doc(notificationId)
                        .update({'unread': false});
                  }
                },
              );
            },
            separatorBuilder: (ctx, index) {
              return Container(
                height: 1,
                color: kBorderColor,
                margin: EdgeInsets.symmetric(vertical: 12),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('yyyy-MM-dd').format(time);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final String title, subTitle, time, type, notificationId;
  final bool unread;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.title,
    required this.subTitle,
    required this.time,
    required this.unread,
    required this.type,
    required this.notificationId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
                                      text: subTitle.split('Tap to view')[1],
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
      ),
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
          text: 'No notifications to be shown yet.',
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