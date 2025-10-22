import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/models/project/project.dart';
import 'package:docu_site/models/project/project_file.dart';
import 'package:docu_site/models/project/collaborator.dart';

import '../../../constants/app_images.dart';
import '../../../controllers/project/edit_project_controller.dart';

class EditProjectScreen extends StatelessWidget {
  final String projectId;

  const EditProjectScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFillColor,
      body: GetBuilder<EditProjectController>(
        init: EditProjectController(projectId: projectId),
        builder: (controller) {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator(color: kSecondaryColor));
          }

          if (controller.project.value == null) {
            return Center(
              child: MyText(
                text: 'Project not found',
                size: 16,
                color: kQuaternaryColor,
              ),
            );
          }

          return Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.only(top: 55, bottom: 16, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: kFillColor,
                  border: Border(
                    bottom: BorderSide(color: kBorderColor, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Image.asset(
                        'assets/images/arrow_back.png', // Replace with your back arrow asset
                        height: 24,
                        width: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MyText(
                        text: 'Edit Project',
                        size: 20,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: AppSizes.DEFAULT,
                  children: [
                    // Project Information Section
                    _buildProjectInfoSection(controller),
                    const SizedBox(height: 20),

                    // Files Section
                    _buildFilesSection(controller),
                    const SizedBox(height: 20),

                    // Members Section
                    _buildMembersSection(controller),
                    const SizedBox(height: 20),

                    // Additional Fields Section
                    _buildAdditionalFieldsSection(controller),
                    const SizedBox(height: 20),

                    // Save Button
                    MyButton(
                      buttonText: 'Save Changes',
                      isLoading: controller.isSaving.value,
                      onTap: () => controller.saveChanges(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProjectInfoSection(EditProjectController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            text: 'Project Information',
            size: 18,
            weight: FontWeight.w600,
            paddingBottom: 16,
          ),
          SimpleTextField(
            controller: controller.titleController,
            labelText: 'Project Title',
            hintText: 'Enter project title',
            isRequired: true,
          ),
          const SizedBox(height: 12),
          SimpleTextField(
            controller: controller.clientController,
            labelText: 'Client Name',
            hintText: 'Enter client name',
            isRequired: true,
          ),
          const SizedBox(height: 12),
          SimpleTextField(
            controller: controller.locationController,
            labelText: 'Project Location',
            hintText: 'Enter project location',
            isRequired: true,
          ),
          const SizedBox(height: 12),
          SimpleTextField(
            controller: controller.deadlineController,
            labelText: 'Project Deadline',
            hintText: 'Select deadline',
            isReadOnly: true,
            onTap: () => controller.selectDeadlineDate(),
          ),
          const SizedBox(height: 12),
          // Status Dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Project Status',
                size: 14,
                weight: FontWeight.w500,
                color: kQuaternaryColor,
                paddingBottom: 8,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: kFillColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorderColor),
                ),
                child: DropdownButton<String>(
                  value: controller.selectedStatus.value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: Project.statusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: MyText(
                        text: status,
                        size: 16,
                        weight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      controller.selectedStatus.value = newValue;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MyText(
                text: 'Project Progress: ${(controller.progressValue.value * 100).toInt()}%',
                size: 14,
                weight: FontWeight.w500,
                color: kQuaternaryColor,
                paddingBottom: 8,
              ),
              Slider(
                value: controller.progressValue.value,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                activeColor: kSecondaryColor,
                inactiveColor: kBorderColor,
                onChanged: (double value) {
                  controller.progressValue.value = value;
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilesSection(EditProjectController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: 'Project Files',
                  size: 18,
                  weight: FontWeight.w600,
                ),
              ),
              MyText(
                text: '${controller.project.value?.files.length ?? 0} file(s)',
                size: 14,
                color: kQuaternaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (controller.project.value?.files.isEmpty ?? true)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kFillColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MyText(
                text: 'No files added yet',
                size: 14,
                color: kQuaternaryColor,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...controller.groupedFiles.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MyText(
                    text: entry.key,
                    size: 16,
                    weight: FontWeight.w600,
                    paddingBottom: 8,
                  ),
                  ...entry.value.map((file) {
                    return _buildFileItem(controller, file);
                  }).toList(),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildFileItem(EditProjectController controller, ProjectFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Image.asset(
            Assets.imagesPdf, // Replace with your PDF icon
            height: 24,
            width: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: file.fileName,
                  size: 14,
                  weight: FontWeight.w500,
                ),
                MyText(
                  text: 'Uploaded by ${file.uploadedBy}',
                  size: 12,
                  color: kQuaternaryColor,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showDeleteFileDialog(controller, file),
            icon: Image.asset(
              Assets.imagesDelete, // Replace with your delete icon
              height: 20,
              width: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(EditProjectController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: MyText(
                  text: 'Project Members',
                  size: 18,
                  weight: FontWeight.w600,
                ),
              ),
              MyText(
                text: '${controller.project.value?.collaborators.length ?? 0} member(s)',
                size: 14,
                color: kQuaternaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (controller.project.value?.collaborators.isEmpty ?? true)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kFillColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MyText(
                text: 'No members added yet',
                size: 14,
                color: kQuaternaryColor,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...controller.project.value!.collaborators.map((member) {
              return _buildMemberItem(controller, member);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMemberItem(EditProjectController controller, Collaborator member) {
    final isOwner = member.uid == controller.project.value?.ownerId;
    final canRemove = controller.canRemoveMember(member.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kFillColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          CommonImageView(
            height: 40,
            width: 40,
            radius: 20,
            url: member.photoUrl.isNotEmpty ? member.photoUrl : 'assets/images/dummy_img.png',
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: member.name,
                  size: 14,
                  weight: FontWeight.w500,
                ),
                MyText(
                  text: '${member.role}${isOwner ? ' (Owner)' : ''}',
                  size: 12,
                  color: kQuaternaryColor,
                ),
                MyText(
                  text: member.email,
                  size: 12,
                  color: kQuaternaryColor,
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              onPressed: () => _showRemoveMemberDialog(controller, member),
              icon: Image.asset(
                Assets.imagesDelete, // Replace with your delete icon
                height: 20,
                width: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFieldsSection(EditProjectController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            size: 18,
            weight: FontWeight.w600,
            paddingBottom: 16,
          ),

          // Existing additional fields
          ...controller.additionalFields.entries.map((entry) {
            return _buildAdditionalFieldItem(controller, entry.key, entry.value.toString());
          }).toList(),

          // Show message if no additional fields
          if (controller.additionalFields.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kFillColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: MyText(
                text: 'No additional fields added yet',
                size: 14,
                color: kQuaternaryColor,
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 16),

          // Add new field button
          MyButton(
            buttonText: '+ Add New Field',
            bgColor: kFillColor,
            textColor: kSecondaryColor,
            onTap: () => _showAddFieldDialog(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFieldItem(EditProjectController controller, String key, String value) {
    final keyController = TextEditingController(text: key);
    final valueController = TextEditingController(text: value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: SimpleTextField(
              controller: keyController,
              labelText: 'Field Name',
              onChanged: (newKey) {
                if (newKey.isNotEmpty && newKey != key) {
                  controller.updateAdditionalFieldKey(key, newKey);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: SimpleTextField(
              controller: valueController,
              labelText: 'Field Value',
              onChanged: (newValue) {
                controller.updateAdditionalFieldValue(key, newValue);
              },
            ),
          ),
          IconButton(
            onPressed: () => controller.removeAdditionalField(key),
            icon: Image.asset(
              Assets.imagesDelete,
              height: 20,
              width: 20,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteFileDialog(EditProjectController controller, ProjectFile file) {
    Get.dialog(
      AlertDialog(
        title: MyText(
          text: 'Delete File',
          size: 18,
          weight: FontWeight.w600,
        ),
        content: MyText(
          text: 'Are you sure you want to delete ${file.fileName}? This action cannot be undone.',
          size: 14,
          color: kQuaternaryColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: MyText(
              text: 'Cancel',
              color: kQuaternaryColor,
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteFile(file);
            },
            child: MyText(
              text: 'Delete',
              color: kRedColor,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(EditProjectController controller, Collaborator member) {
    Get.dialog(
      AlertDialog(
        title: MyText(
          text: 'Remove Member',
          size: 18,
          weight: FontWeight.w600,
        ),
        content: MyText(
          text: 'Are you sure you want to remove ${member.name} from the project?',
          size: 14,
          color: kQuaternaryColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: MyText(
              text: 'Cancel',
              color: kQuaternaryColor,
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.removeMember(member.uid);
            },
            child: MyText(
              text: 'Remove',
              color: kRedColor,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFieldDialog(EditProjectController controller) {
    final fieldNameController = TextEditingController();
    final fieldValueController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: MyText(
          text: 'Add New Field',
          size: 18,
          weight: FontWeight.w600,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SimpleTextField(
              controller: fieldNameController,
              labelText: 'Field Name',
              hintText: 'Enter field name',
            ),
            const SizedBox(height: 12),
            SimpleTextField(
              controller: fieldValueController,
              labelText: 'Field Value',
              hintText: 'Enter field value',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: MyText(
              text: 'Cancel',
              color: kQuaternaryColor,
            ),
          ),
          TextButton(
            onPressed: () {
              if (fieldNameController.text.trim().isNotEmpty) {
                controller.addAdditionalField(
                  fieldNameController.text.trim(),
                  fieldValueController.text.trim(),
                );
                Get.back();
              }
            },
            child: MyText(
              text: 'Add',
              color: kSecondaryColor,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}