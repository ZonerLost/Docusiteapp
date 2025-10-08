import 'package:flutter/cupertino.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/project/project_detail_controller.dart';
import '../../models/project/project.dart';
import '../../utils/Utils.dart';
import 'custom_drop_down_widget.dart';
import 'my_button_widget.dart';
import 'my_text_field_widget.dart';
import 'my_text_widget.dart';

class AddMember extends StatelessWidget {
  final ProjectDetailsController controller;

  AddMember({required this.controller});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final RxString selectedRole = Project.roleOptions.first.obs;


  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.55,
      margin: EdgeInsets.only(top: 55),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            text: 'Add new member',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Please enter the correct information to add a new member.',
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
                  labelText: 'Member Name',
                  hintText: 'Chris Taylor',
                  controller: nameController,
                ),
                SimpleTextField(
                  labelText: 'Email Address',
                  hintText: 'chris.taylor@email.com',
                  controller: emailController,
                ),
                Obx(() => CustomDropDown(
                  labelText: 'Member role',
                  hintText: 'Select Role',
                  items: Project.roleOptions,
                  selectedValue: selectedRole.value,
                  onChanged: (v) {
                    selectedRole.value = v;
                  },
                )),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Add',
            isLoading: controller.isAddingMember.value,
            onTap: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty && GetUtils.isEmail(emailController.text)) {
                controller.addMember(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  selectedRole.value,
                );
                Get.back();
              } else {
                Utils.snackBar('Validation', 'Please enter a valid name and email address.');
              }
            },
          ),
        ],
      ),
    );
  }
}