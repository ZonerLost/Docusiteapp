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


class InviteNewMember extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = Get.find();

    return Container(
      height: Get.height * 0.6,
      margin: const EdgeInsets.only(top: 55),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Obx(
            () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MyText(
              text: 'Invite new member',
              size: 18,
              weight: FontWeight.w500,
              paddingBottom: 8,
            ),
            MyText(
              text:
              'Please enter the correct information to add a new member.',
              color: kQuaternaryColor,
              weight: FontWeight.w500,
              size: 13,
            ),
            Container(
              height: 1,
              color: kBorderColor,
              margin: const EdgeInsets.symmetric(vertical: 12),
            ),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: AppSizes.ZERO,
                physics: const BouncingScrollPhysics(),
                children: [
                  SimpleTextField(
                    controller: viewModel.memberNameController,
                    labelText: 'Member Name',
                    hintText: 'Chris Taylor',
                  ),
                  SimpleTextField(
                    controller: viewModel.memberEmailController,
                    labelText: 'Member email address',
                    hintText: 'chris345@gmail.com',
                  ),
                  Obx(
                        () => CustomDropDown(
                      labelText: 'Member Role',
                      hintText: 'Select Role',
                      items: Project.roleOptions,
                      selectedValue: viewModel.selectedMemberRole.value,
                      onChanged: (v) {
                        viewModel.selectedMemberRole.value = v;
                      },
                    ),
                  ),
                ],
              ),
            ),
            MyButton(
              buttonText: 'Send Invite',
              isLoading: viewModel.isInvitingMember.value,
              onTap: viewModel.isInvitingMember.value
                  ? null
                  : viewModel.sendMemberInvite,
            ),
          ],
        ),
      ),
    );
  }
}