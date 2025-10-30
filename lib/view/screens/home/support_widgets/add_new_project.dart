import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_images.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../controllers/home/home_controller.dart';
import '../../../widget/custom_check_box_widget.dart';
import '../../../widget/invite_member_dialog.dart';
import '../../../widget/my_button_widget.dart';
import '../../../widget/my_text_field_widget.dart';
import '../../../widget/my_text_widget.dart';

class AddNewProject extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HomeController viewModel = Get.find();

    return Container(
      height: Get.height * 0.8,
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
              text: 'Create new project',
              size: 18,
              weight: FontWeight.w500,
              paddingBottom: 8,
            ),
            MyText(
              text: 'Please enter the correct information to add a new project.',
              color: kQuaternaryColor,
              weight: FontWeight.w500,
              size: 13,
            ),
            Container(height: 1, color: kBorderColor, margin: const EdgeInsets.symmetric(vertical: 12)),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: AppSizes.ZERO,
                physics: const BouncingScrollPhysics(),
                children: [
                  // ----- Base fields -----
                  SimpleTextField(
                    controller: viewModel.titleController,
                    labelText: 'Project Title',
                    hintText: '200sq ft 4 bedroom Villa',
                    errorText: viewModel.fieldErrors['title'],
                    isRequired: true,
                    onChanged: (_) => viewModel.clearFieldError('title'),
                  ),
                  SimpleTextField(
                    controller: viewModel.clientController,
                    labelText: 'Client name',
                    hintText: 'John Smith',
                    errorText: viewModel.fieldErrors['client'],
                    isRequired: true,
                    onChanged: (_) => viewModel.clearFieldError('client'),
                  ),
                  SimpleTextField(
                    controller: viewModel.locationController,
                    labelText: 'Project location',
                    hintText: 'St 3 Wilsons Road, California, USA',
                    errorText: viewModel.fieldErrors['location'],
                    isRequired: true,
                    onChanged: (_) => viewModel.clearFieldError('location'),
                  ),
                  SimpleTextField(
                    controller: viewModel.deadlineController,
                    labelText: 'Project Deadline',
                    hintText: 'Select date',
                    isReadOnly: true,
                    errorText: viewModel.fieldErrors['deadline'],
                    isRequired: true,
                    onTap: () {
                      viewModel.clearFieldError('deadline');
                      viewModel.selectDeadlineDate();
                    },
                  ),
                  const SizedBox(height: 16),

                  // ----- Additional Fields (CREATE) -----
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MyText(
                          text: 'Additional Fields',
                          size: 16,
                          weight: FontWeight.w600,
                          paddingBottom: 10,
                        ),

                        // List current extra fields
                        if (viewModel.createExtraFields.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: kFillColor, borderRadius: BorderRadius.circular(8)),
                            child: MyText(
                              text: 'No additional fields added yet',
                              size: 14,
                              color: kQuaternaryColor,
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ...viewModel.createExtraFields.entries.map((e) {
                            final key = e.key;
                            final value = e.value?.toString() ?? '';
                            final keyCtl = viewModel.createKeyControllers[key] ?? TextEditingController(text: key);
                            final valCtl = viewModel.createValueControllers[key] ?? TextEditingController(text: value);
                            viewModel.createKeyControllers[key] = keyCtl;
                            viewModel.createValueControllers[key] = valCtl;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: SimpleTextField(
                                      controller: keyCtl,
                                      labelText: 'Field Name',
                                      onChanged: (newKey) {
                                        if (newKey.isNotEmpty && newKey != key) {
                                          viewModel.updateCreateExtraFieldKey(key, newKey);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: SimpleTextField(
                                      controller: valCtl,
                                      labelText: 'Field Value',
                                      onChanged: (newVal) {
                                        viewModel.updateCreateExtraFieldValue(keyCtl.text, newVal);
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => viewModel.removeCreateExtraField(keyCtl.text),
                                    icon: Image.asset(Assets.imagesDelete, height: 20, width: 20),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: MyButton(
                            buttonText: '+ Add New Field',
                            bgColor: kFillColor,
                            textColor: kSecondaryColor,
                            height: 36,
                            onTap: () {
                              final nameCtl = TextEditingController();
                              final valueCtl = TextEditingController();
                              Get.dialog(
                                AlertDialog(
                                  title: MyText(text: 'Add New Field', size: 18, weight: FontWeight.w600),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SimpleTextField(controller: nameCtl, labelText: 'Field Name', hintText: 'e.g. Budget'),
                                      const SizedBox(height: 12),
                                      SimpleTextField(controller: valueCtl, labelText: 'Field Value', hintText: 'e.g. \$100,000'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: MyText(text: 'Cancel', color: kQuaternaryColor),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        final k = nameCtl.text.trim();
                                        final v = valueCtl.text.trim();
                                        if (k.isNotEmpty) {
                                          viewModel.addCreateExtraField(k, v);
                                          Get.back();
                                        }
                                      },
                                      child: MyText(text: 'Add', color: kSecondaryColor, weight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ----- Members & Access (unchanged) -----
                  Row(
                    children: [
                      Expanded(
                        child: MyText(
                          text: 'Assign Members',
                          size: 14,
                          weight: FontWeight.w500,
                          color: kQuaternaryColor,
                        ),
                      ),
                      MyText(
                        onTap: () {
                          viewModel.memberNameController.clear();
                          viewModel.memberEmailController.clear();
                          Get.bottomSheet(
                            InviteNewMember(),
                            isScrollControlled: true,
                          );
                        },
                        text: '+ Invite new member',
                        size: 14,
                        weight: FontWeight.w500,
                        color: kSecondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Obx(() {
                    if (viewModel.assignedMembers.isEmpty) {
                      return Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: kFillColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            MyText(
                              text: 'No members assigned yet',
                              size: 16,
                              color: kQuaternaryColor,
                              weight: FontWeight.w500,
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kFillColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: viewModel.assignedMembers.map((member) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: kSecondaryColor.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MyText(
                                  text: member.name,
                                  size: 14,
                                  color: kSecondaryColor,
                                  weight: FontWeight.w500,
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () => viewModel.assignedMembers.remove(member),
                                  child: Image.asset(Assets.imagesCancelBlue, height: 12, width: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  MyText(
                    text: 'Assigned: ${viewModel.assignedMembers.length} member(s)',
                    size: 12,
                    color: kQuaternaryColor,
                  ),
                  const SizedBox(height: 4),
                  // Row(
                  //   spacing: 20,
                  //   children: [
                  //     Row(
                  //       spacing: 4,
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         CustomCheckBox(
                  //           circularRadius: 5,
                  //           isActive: viewModel.hasViewAccess.value,
                  //           onTap: () => viewModel.toggleAccess(false),
                  //           radius: 20,
                  //         ),
                  //         MyText(text: 'View Access', size: 14, weight: FontWeight.w500),
                  //       ],
                  //     ),
                  //     Row(
                  //       spacing: 4,
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         CustomCheckBox(
                  //           circularRadius: 5,
                  //           isActive: viewModel.hasEditAccess.value,
                  //           onTap: () => viewModel.toggleAccess(true),
                  //           radius: 20,
                  //         ),
                  //         MyText(text: 'Edit Access', size: 14, weight: FontWeight.w500),
                  //       ],
                  //     ),
                  //   ],
                  // ),
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kSecondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: MyText(
                      text: '* indicates required field',
                      size: 12,
                      color: kSecondaryColor,
                      weight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            MyButton(
              buttonText: 'Add',
              isLoading: viewModel.isSavingProject.value,
              onTap: () {
                if (!viewModel.isSavingProject.value) {
                  // DO NOT close here; controller will close on success
                  viewModel.createNewProject();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
