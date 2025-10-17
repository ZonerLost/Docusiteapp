import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/project/project_detail_controller.dart';
import '../../../models/project/project.dart';
import '../../widget/custom_drop_down_widget.dart';

class InviteToProjectDialog extends StatelessWidget {
  final ProjectDetailsController controller;

  const InviteToProjectDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.6,
      margin: EdgeInsets.only(top: 55),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            text: 'Invite Member to Project',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Invite a member to collaborate on this project.',
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
                  controller: controller.memberNameController,
                  labelText: 'Member Name',
                  hintText: 'Enter full name',
                ),
                SizedBox(height: 16),
                SimpleTextField(
                  controller: controller.memberEmailController,
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                  // keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),
                // CHANGED: Replace dropdown with text field for custom role
                SimpleTextField(
                  controller: controller.memberRoleController, // Add this controller
                  labelText: 'Role',
                  hintText: 'e.g., Client, Engineer, Project Manager, etc.',
                  onChanged: (value) {
                    controller.selectedMemberRole.value = value;
                  },
                ),
                SizedBox(height: 16),
                MyText(
                  text: 'The member will receive an invitation email and can accept to join this project.',
                  size: 12,
                  color: kQuaternaryColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Send Invitation',
            isLoading: controller.isInvitingMember.value,
            onTap: controller.inviteMemberToProject,
          ),
        ],
      )),
    );
  }
}