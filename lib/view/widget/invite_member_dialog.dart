import 'package:flutter/cupertino.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/home/home_controller.dart';
import 'custom_check_box_widget.dart';
import 'my_button_widget.dart';
import 'my_text_field_widget.dart';
import 'my_text_widget.dart';

class InviteNewMember extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HomeController viewModel = Get.find();

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
            text: 'Invite New Member',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Add a new member to collaborate on projects.',
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
                  controller: viewModel.memberNameController,
                  labelText: 'Member Name',
                  hintText: 'Enter full name',
                ),
                SizedBox(height: 16),
                SimpleTextField(
                  controller: viewModel.memberEmailController,
                  labelText: 'Email Address',
                  hintText: 'Enter email address',
                ),
                SizedBox(height: 16),
                SimpleTextField(
                  controller: viewModel.memberRoleController,
                  labelText: 'Role',
                  hintText: 'e.g., Client, Engineer, Project Manager, etc.',
                ),
                SizedBox(height: 20),

                // ACCESS CONTROLS - MOVED INSIDE THE INVITE DIALOG
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
                            isActive: viewModel.hasViewAccess.value,
                            onTap: () => viewModel.toggleViewAccess(!viewModel.hasViewAccess.value),
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
                            isActive: viewModel.hasEditAccess.value,
                            onTap: viewModel.hasViewAccess.value
                                ? () => viewModel.toggleEditAccess(!viewModel.hasEditAccess.value)
                                : (){}, // Disable if view access is off
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
                                  color: viewModel.hasViewAccess.value ? kTertiaryColor : kQuaternaryColor,
                                ),
                                if (!viewModel.hasViewAccess.value)
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
                        text: viewModel.hasEditAccess.value
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
                  text: 'The member will be added to your project with the specified role and access level.',
                  size: 12,
                  color: kQuaternaryColor,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Add Member',
            isLoading: viewModel.isInvitingMember.value,
            onTap: viewModel.sendMemberInvite,
          ),
        ],
      )),
    );
  }
}