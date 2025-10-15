import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
            return _buildEmptyState();
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
              final invitedBy = invite['invitedByName'] ?? 'Unknown User';
              final role = invite['role'] ?? 'Member';
              final accessLevel = invite['accessLevel'] ?? 'view';

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('projects').doc(projectId).get(),
                builder: (context, projectSnapshot) {
                  if (projectSnapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard();
                  }
                  if (projectSnapshot.hasError || !projectSnapshot.hasData || !projectSnapshot.data!.exists) {
                    return _buildErrorCard(projectId);
                  }

                  final projectData = projectSnapshot.data!.data() as Map<String, dynamic>;
                  final projectTitle = invite['projectTitle'] ?? projectData['title'] ?? 'Untitled Project';
                  final deadline = (projectData['deadline'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 30));
                  final clientName = projectData['clientName'] ?? 'Unknown Client';
                  final location = projectData['location'] ?? 'Unknown Location';

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
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                            _buildInviteBadge(role, accessLevel),
                          ],
                        ),
                        Container(
                          height: 1,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          color: kBorderColor,
                        ),
                        Column(
                          children: [
                            _buildDetailRow('Client name', clientName),
                            _buildDetailRow('Project Location', location),
                            _buildDetailRow('Invited by', invitedBy),
                            _buildDetailRow('Role', role),
                            _buildDetailRow('Access', accessLevel == 'edit' ? 'Can Edit' : 'View Only'),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: kQuaternaryColor),
          SizedBox(height: 16),
          MyText(
            text: 'No Pending Invites',
            size: 18,
            weight: FontWeight.w500,
          ),
          SizedBox(height: 8),
          MyText(
            text: 'You don\'t have any project invitations at the moment.',
            color: kQuaternaryColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
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

  Widget _buildErrorCard(String projectId) {
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
          MyText(
            text: 'Project Unavailable',
            size: 16,
            weight: FontWeight.w500,
            color: kRedColor,
          ),
          MyText(
            text: 'The project associated with this invitation is no longer available.',
            size: 12,
            color: kQuaternaryColor,
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
                  onTap: () => _viewModel.declineInvite(projectId),
                ),
              ),
              Expanded(
                child: MyButton(
                  buttonText: 'Remove',
                  onTap: () => _viewModel.declineInvite(projectId),
                  height: 40,
                  textSize: 14,
                  bgColor: kRedColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: MyText(
              text: label,
              color: kQuaternaryColor,
              size: 12,
            ),
          ),
          MyText(
            text: value,
            weight: FontWeight.w500,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildInviteBadge(String role, String accessLevel) {
    Color badgeColor = accessLevel == 'edit' ? kGreenColor : kSecondaryColor;
    String badgeText = accessLevel == 'edit' ? 'Editor' : 'Viewer';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: MyText(
        text: badgeText,
        size: 10,
        color: badgeColor,
        weight: FontWeight.w600,
      ),
    );
  }
}