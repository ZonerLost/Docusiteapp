import 'package:flutter/cupertino.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/project/project_detail_controller.dart';
import '../../models/project/project.dart';
import '../../utils/Utils.dart';
import '../../view_model/home/home_view_model.dart';
import 'custom_drop_down_widget.dart';
import 'my_button_widget.dart';
import 'my_text_field_widget.dart';
import 'my_text_widget.dart';


// If you have an InviteNewMember widget, update it similarly:
class InviteNewMember extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = Get.find();

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
                // CHANGED: Replace dropdown with text field for custom role
                SimpleTextField(
                  controller: viewModel.memberRoleController, // Add this controller
                  labelText: 'Role',
                  hintText: 'e.g., Client, Engineer, Project Manager, etc.',
                  onChanged: (value) {
                    viewModel.selectedMemberRole.value = value;
                  },
                ),
                SizedBox(height: 16),
                MyText(
                  text: 'The member will be added to your project with the specified role.',
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