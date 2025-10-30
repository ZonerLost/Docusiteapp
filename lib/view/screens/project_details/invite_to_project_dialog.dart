import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/project/project_detail_controller.dart';

class InviteToProjectDialog extends StatelessWidget {
  final ProjectDetailsController controller;

  const InviteToProjectDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.7, // Increased height to accommodate access controls
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
                ),
                SizedBox(height: 16),
                SimpleTextField(
                  controller: controller.memberRoleController,
                  labelText: 'Role',
                  hintText: 'e.g., Client, Engineer, Project Manager, etc.',
                ),
                SizedBox(height: 20),

                // ACCESS CONTROLS - ADDED SECTION
                MyText(
                  text: 'Access Level',
                  size: 16,
                  weight: FontWeight.w600,
                  paddingBottom: 12,
                ),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kFillColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // View Access Checkbox
                      Row(
                        children: [
                          CustomCheckBox(
                            circularRadius: 5,
                            isActive: controller.hasViewAccess.value,
                            onTap: () => controller.toggleViewAccess(!controller.hasViewAccess.value),
                            radius: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: MyText(
                              text: 'View Access',
                              size: 14,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Edit Access Checkbox
                      Row(
                        children: [
                          CustomCheckBox(
                            circularRadius: 5,
                            isActive: controller.hasEditAccess.value,
                            onTap: controller.hasViewAccess.value
                                ? () => controller.toggleEditAccess(!controller.hasEditAccess.value)
                                : () {}, // Empty function when disabled
                            radius: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MyText(
                                  text: 'Edit Access',
                                  size: 14,
                                  weight: FontWeight.w500,
                                  color: controller.hasViewAccess.value ? kTertiaryColor : kQuaternaryColor,
                                ),
                                if (!controller.hasViewAccess.value)
                                  MyText(
                                    text: 'Requires View Access',
                                    size: 10,
                                    color: kQuaternaryColor,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      MyText(
                        text: controller.hasEditAccess.value
                            ? 'Member can view and edit project details'
                            : 'Member can only view project details',
                        size: 12,
                        color: kQuaternaryColor,
                      ),
                    ],
                  ),
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