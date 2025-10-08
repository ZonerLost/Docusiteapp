import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:intl/intl.dart';
import '../../../view_model/home/home_view_model.dart';

class ProjectInvites extends StatelessWidget {
  final HomeViewModel _viewModel = Get.find<HomeViewModel>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Project Invites'),
      body: StreamBuilder<QuerySnapshot>(
        stream: _viewModel.firestore
            .collection('pending_requests')
            .doc(_viewModel.auth.currentUser?.email ?? '')
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: kSecondaryColor));
          }
          if (snapshot.hasError) {
            return Center(child: MyText(text: 'Error loading invites'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: MyText(text: 'No pending invites'));
          }

          final invites = snapshot.data!.docs;
          return ListView.builder(
            itemCount: invites.length,
            padding: AppSizes.DEFAULT,
            physics: BouncingScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final invite = invites[index].data() as Map<String, dynamic>;
              final inviteId = invites[index].id;
              final projectId = invite['projectId'];

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('projects').doc(projectId).get(),
                builder: (context, projectSnapshot) {
                  if (projectSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kFillColor,
                        border: Border.all(color: kBorderColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(child: CircularProgressIndicator(color: kSecondaryColor)),
                    );
                  }
                  if (projectSnapshot.hasError || !projectSnapshot.hasData || !projectSnapshot.data!.exists) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 10),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kFillColor,
                        border: Border.all(color: kBorderColor, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: MyText(text: 'Project data unavailable'),
                    );
                  }

                  final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;
                  final projectTitle = projectData['title'] ?? 'Untitled Project';
                  final deadline = (projectData['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30));
                  final clientName = projectData['clientName'] ?? 'Unknown Client';
                  final location = projectData['location'] ?? 'Unknown Location';
                  final ownerId = projectData['ownerId'] ?? '';
                  final collaborators = (projectData['collaborators'] as List<dynamic>?) ?? [];
                  final owner = collaborators.firstWhere(
                        (c) => c['uid'] == ownerId,
                    orElse: () => {'name': 'Unknown Admin'},
                  );
                  final ownerName = owner['name'] ?? 'Unknown Admin';

                  return Container(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MyText(
                                    text: projectTitle,
                                    size: 16,
                                    weight: FontWeight.w500,
                                  ),
                                  MyText(
                                    text: 'Deadline: ${DateFormat('yyyy-MM-dd').format(deadline)}',
                                    color: kQuaternaryColor,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 80,
                              child: MyButton(
                                buttonText: 'New Invite',
                                onTap: () {},
                                height: 30,
                                radius: 50,
                                textSize: 12,
                                textColor: kSecondaryColor,
                                bgColor: kSecondaryColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          color: kBorderColor,
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: MyText(
                                    text: 'Client name',
                                    color: kQuaternaryColor,
                                  ),
                                ),
                                MyText(
                                  text: clientName,
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: MyText(
                                    text: 'Project Location',
                                    color: kQuaternaryColor,
                                  ),
                                ),
                                MyText(
                                  text: location,
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: MyText(
                                    text: 'Assigned by',
                                    color: kQuaternaryColor,
                                  ),
                                ),
                                MyText(
                                  text: '$ownerName (Admin)',
                                  weight: FontWeight.w500,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          spacing: 8,
                          children: [
                            Expanded(
                              child: MyBorderButton(
                                borderColor: kBorderColor,
                                bgColor: kGreyColor,
                                textColor: kQuaternaryColor,
                                height: 40,
                                textSize: 14,
                                buttonText: 'Decline',
                                onTap: () => _viewModel.declineInvite(inviteId),
                              ),
                            ),
                            Expanded(
                              child: MyButton(
                                buttonText: 'Accept Invite',
                                onTap: () => _viewModel.acceptInvite(inviteId, projectId),
                                height: 40,
                                textSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}