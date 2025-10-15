import 'dart:io';

import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/chat/chat_screen.dart';
import 'package:docu_site/view/screens/project_details/pdf_details.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_drop_down_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docu_site/utils/Utils.dart';
import '../../../controllers/project/project_detail_controller.dart';
import '../../../models/project/collaborator.dart';
import '../../../models/project/project.dart';
import '../../../models/project/project_file.dart';
import '../../../view_model/home/home_view_model.dart';
import '../../widget/invite_member_dialog.dart';
import '../home/invite_to_project_dialog.dart';

class ProjectDetails extends StatelessWidget {
  final String projectId;
  final String tag = UniqueKey().toString();

  ProjectDetails({super.key, required this.projectId}) {
    Get.put(ProjectDetailsController(projectId: projectId), tag: tag);
    // Ensure HomeViewModel is initialized for member invitation
    Get.put(HomeViewModel());
  }

  ProjectDetailsController get controller => Get.find<ProjectDetailsController>(tag: tag);
  HomeViewModel get homeViewModel => Get.find<HomeViewModel>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        body: Obx(() {
          final Project? project = controller.project.value;
          final bool isLoading = project == null;

          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return NestedScrollView(
            physics: BouncingScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  expandedHeight: 480,
                  backgroundColor: kFillColor,
                  titleSpacing: 0.0,
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Get.delete<ProjectDetailsController>(tag: tag);
                          Get.back();
                        },
                        child: Image.asset(Assets.imagesArrowBack, height: 15),
                      ),
                    ],
                  ),
                  title: MyText(
                    text: 'Project Details',
                    size: 18,
                    color: kTertiaryColor,
                    weight: FontWeight.w500,
                  ),
                  elevation: 0,
                  actions: [
                    Center(
                      child: PopupMenuButton(
                        offset: Offset(0, 40),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(maxWidth: 111),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (context) {
                          return [
                            PopupMenuItem(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              value: 'invite',
                              height: 25,
                              onTap: () {
                                // Only allow project owner to invite members
                                if (!controller.isCurrentUserOwner) {
                                  Utils.snackBar('Error', 'Only project owner can invite members.');
                                  return;
                                }
                                controller.memberNameController.clear();
                                controller.memberEmailController.clear();
                                Get.bottomSheet(
                                  InviteToProjectDialog(controller: controller),
                                  isScrollControlled: true,
                                );
                              },
                              child: MyText(
                                text: 'Invite Member',
                                size: 14,
                                weight: FontWeight.w500,
                              ),
                            ),
                            PopupMenuItem(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              value: 'edit',
                              height: 25,
                              onTap: controller.editProject,
                              child: MyText(
                                text: 'Edit Project',
                                size: 14,
                                weight: FontWeight.w500,
                              ),
                            ),
                            PopupMenuItem(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              value: 'delete',
                              height: 25,
                              onTap: () {
                                // Add a small delay to let the popup menu close
                                Future.delayed(Duration(milliseconds: 300), () {
                                  controller.deleteProject();
                                });
                              },
                              child: Obx(() => controller.isDeletingProject.value
                                  ? Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: kRedColor,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  MyText(
                                    text: 'Deleting...',
                                    size: 14,
                                    color: kRedColor,
                                    weight: FontWeight.w500,
                                  ),
                                ],
                              )
                                  : MyText(
                                text: 'Delete Project',
                                size: 14,
                                color: kRedColor,
                                weight: FontWeight.w500,
                              )),
                            ),
                          ];
                        },
                        child: Image.asset(
                          Assets.imagesMoreRounded,
                          height: 40,
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                  ],
                  flexibleSpace: Container(
                    color: kFillColor,
                    child: FlexibleSpaceBar(
                      background: ListView(
                        shrinkWrap: true,
                        padding: AppSizes.DEFAULT,
                        physics: BouncingScrollPhysics(),
                        children: [
                          SizedBox(height: 80),
                          Row(
                            children: [
                              Expanded(
                                child: MyText(
                                  text: project!.title,
                                  size: 28,
                                  weight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(
                                width: 118,
                                child: MyButton(
                                  buttonText: 'Group Chat',
                                  onTap: () {
                                    Get.to(() => ChatScreen(
                                      projectId: project.id,
                                      collaboratorIds: project.collaborators.map((c) => c.uid).toList(),
                                      collaboratorEmails: project.collaborators.map((c) => c.email).toList(),
                                    ));
                                  },
                                  textSize: 14,
                                  weight: FontWeight.w500,
                                  height: 36,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _DetailRows(project: project, controller: controller),
                          Container(height: 1, color: kBorderColor),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(50),
                    child: Container(
                      color: kFillColor,
                      child: TabBar(
                        labelPadding: AppSizes.HORIZONTAL,
                        automaticIndicatorColorAdjustment: false,
                        indicatorColor: kSecondaryColor,
                        indicatorWeight: 3,
                        labelColor: kSecondaryColor,
                        unselectedLabelColor: kQuaternaryColor,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          fontFamily: AppFonts.SFProDisplay,
                        ),
                        unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          fontFamily: AppFonts.SFProDisplay,
                        ),
                        tabs: List.generate(2, (index) {
                          final titles = ['Files & Documents', 'Members'];
                          return Tab(text: titles[index]);
                        }),
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              physics: BouncingScrollPhysics(),
              children: [
                _FilesAndDocuments(controller: controller),
                _Members(controller: controller),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DetailRows extends StatelessWidget {
  final Project project;
  final ProjectDetailsController controller;

  const _DetailRows({required this.project, required this.controller});

  @override
  Widget build(BuildContext context) {
    final details = [
      {'title': 'Client name', 'value': project.clientName},
      {'title': 'Status', 'value': project.status},
      {'title': 'Location', 'value': project.location},
      {'title': 'Project Owner', 'value': controller.projectOwnerName},
      {'title': 'Deadline', 'value': DateFormat('MMM dd, yyyy').format(project.deadline)},
      {'title': 'Members', 'value': '${controller.memberCount} members'},
    ];

    return Column(
      children: List.generate(details.length, (index) {
        final detail = details[index];
        final bool isStatus = detail['title'] == 'Status';
        final bool isLocation = detail['title'] == 'Location';

        return Container(
          height: 48,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: kBorderColor,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: MyText(
                  text: detail['title']!,
                  color: kQuaternaryColor,
                ),
                flex: 3,
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                height: 48,
                width: 1,
                color: kBorderColor,
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLocation)
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kGreyColor2,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              width: 1.0,
                              color: kBorderColor,
                            ),
                          ),
                          child: MyText(
                            text: detail['value']!,
                            size: 12,
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                            color: kTertiaryColor,
                            weight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isStatus
                              ? kOrangeColor.withOpacity(0.08)
                              : kGreyColor2,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            width: 1.0,
                            color: isStatus
                                ? kOrangeColor.withOpacity(0.08)
                                : kBorderColor,
                          ),
                        ),
                        child: MyText(
                          text: detail['value']!,
                          size: 12,
                          color: isStatus ? kOrangeColor : kTertiaryColor,
                          weight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                flex: 7,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _FilesAndDocuments extends StatelessWidget {
  final ProjectDetailsController controller;

  const _FilesAndDocuments({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Map<String, List<ProjectFile>> groupedFiles = controller.groupedFiles;
      final fileCategories = groupedFiles.keys.toList();

      return ListView(
        physics: BouncingScrollPhysics(),
        padding: AppSizes.DEFAULT,
        shrinkWrap: true,
        children: [
          MyText(
            onTap: () {
              Get.bottomSheet(_AddNewPdf(controller: controller), isScrollControlled: true);
            },
            text: '+ Add new PDF',
            size: 16,
            weight: FontWeight.w500,
            color: kSecondaryColor,
            paddingBottom: 10,
          ),

          if (fileCategories.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MyText(
                text: 'No files uploaded yet.',
                color: kQuaternaryColor,
              ),
            ),

          ListView.separated(
            separatorBuilder: (context, index) {
              return SizedBox(height: 8);
            },
            physics: NeverScrollableScrollPhysics(),
            padding: AppSizes.ZERO,
            shrinkWrap: true,
            itemCount: fileCategories.length,
            itemBuilder: (context, index) {
              final category = fileCategories[index];
              final files = groupedFiles[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Row(
                    children: [
                      MyText(
                        text: category,
                        weight: FontWeight.w500,
                      ),
                      MyText(
                        paddingLeft: 6,
                        text: ' (${files.length} files)',
                        color: kQuaternaryColor,
                        size: 12,
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  ...List.generate(files.length, (fileIndex) {
                    final file = files[fileIndex];
                    return GestureDetector(
                      onTap: () {
                        Get.to(() => PdfDetails());
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kFillColor,
                          border: Border.all(color: kBorderColor, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (file.newCommentsCount > 0 || file.newImagesCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (file.newCommentsCount > 0)
                                      _StatusPill(
                                        text: '${file.newCommentsCount} new comments',
                                        color: kRedColor,
                                      ),
                                    if (file.newImagesCount > 0)
                                      _StatusPill(
                                        text: '${file.newImagesCount} new images',
                                        color: kRedColor,
                                        isFirst: file.newCommentsCount == 0,
                                      ),
                                  ],
                                ),
                              ),
                            Row(
                              children: [
                                Image.asset(
                                  Assets.imagesPdf,
                                  height: 40,
                                  width: 40,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      MyText(
                                        size: 14,
                                        weight: FontWeight.w700,
                                        text: file.fileName,
                                      ),
                                      MyText(
                                        paddingTop: 4,
                                        size: 12,
                                        color: kQuaternaryColor,
                                        text: 'Last updated: ${DateFormat('MMM dd, hh:mm a').format(file.lastUpdated)}',
                                      ),
                                    ],
                                  ),
                                ),
                                Image.asset(Assets.imagesArrowNext, height: 24),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final bool isFirst;

  const _StatusPill({required this.text, required this.color, this.isFirst = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: isFirst ? 6 : 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(width: 1.0, color: color.withOpacity(.08)),
        ),
        child: MyText(
          text: text,
          size: 12,
          color: color,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Members extends StatelessWidget {
  final ProjectDetailsController controller;

  const _Members({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final List<Collaborator> members = controller.project.value?.collaborators ?? [];
      final bool isCurrentUserOwner = controller.isCurrentUserOwner;

      return ListView(
        physics: BouncingScrollPhysics(),
        padding: AppSizes.DEFAULT,
        shrinkWrap: true,
        children: [
          // Only show invite button to project owner
          if (isCurrentUserOwner)
            MyText(
              onTap: () {
                controller.memberNameController.clear();
                controller.memberEmailController.clear();
                Get.bottomSheet(
                  InviteToProjectDialog(controller: controller),
                  isScrollControlled: true,
                );
              },
              text: '+ Invite new member',
              size: 16,
              weight: FontWeight.w500,
              color: kSecondaryColor,
              paddingBottom: 12,
            ),

          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: MyText(
                text: 'No collaborators added yet.',
                color: kQuaternaryColor,
              ),
            ),

          ListView.separated(
            separatorBuilder: (context, index) {
              return SizedBox(height: 8);
            },
            physics: NeverScrollableScrollPhysics(),
            padding: AppSizes.ZERO,
            shrinkWrap: true,
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final bool isOwner = member.uid == controller.project.value?.ownerId;
              final bool isCurrentUser = member.uid == controller.auth.currentUser?.uid;

              return GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kFillColor,
                    border: Border.all(color: kBorderColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      CommonImageView(
                        height: 40,
                        width: 40,
                        radius: 100,
                        url: member.photoUrl ?? dummyImg,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                MyText(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  text: member.name,
                                ),
                                if (isOwner)
                                  MyText(
                                    paddingLeft: 6,
                                    size: 10,
                                    color: kSecondaryColor,
                                    text: '(Owner)',
                                    weight: FontWeight.w700,
                                  ),
                                if (isCurrentUser)
                                  MyText(
                                    paddingLeft: 6,
                                    size: 10,
                                    color: kGreenColor,
                                    text: '(You)',
                                    weight: FontWeight.w700,
                                  ),
                              ],
                            ),
                            MyText(
                              paddingTop: 4,
                              size: 12,
                              color: kQuaternaryColor,
                              text: '${member.role} • ${member.canEdit ? 'Can Edit' : 'View Only'}',
                            ),
                          ],
                        ),
                      ),
                      // Only show remove button if:
                      // 1. Current user is project owner
                      // 2. The member is not the owner
                      // 3. The member is not the current user (can't remove yourself)
                      if (isCurrentUserOwner && !isOwner && !isCurrentUser)
                        GestureDetector(
                          onTap: () {
                            _showRemoveMemberConfirmation(member);
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: kRedColor.withOpacity(.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                width: 1.0,
                                color: kRedColor.withOpacity(.08),
                              ),
                            ),
                            child: MyText(
                              text: 'Remove',
                              size: 12,
                              color: kRedColor,
                              weight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  void _showRemoveMemberConfirmation(Collaborator member) {
    Get.dialog(
      AlertDialog(
        title: MyText(
          text: 'Remove Member',
          size: 18,
          weight: FontWeight.w600,
        ),
        content: MyText(
          text: 'Are you sure you want to remove ${member.name} from this project? They will lose access to all project files and data.',
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
}

class _AddNewPdf extends StatefulWidget {
  final ProjectDetailsController controller;

  const _AddNewPdf({required this.controller});

  @override
  State<_AddNewPdf> createState() => _AddNewPdfState();
}

class _AddNewPdfState extends State<_AddNewPdf> {
  String selectedPdfType = 'STRUCTURAL';
  final List<String> pdfCategories = [
    'STRUCTURAL',
    'MVP',
    'Architectural',
    'Electrical',
    'Others',
  ];
  PlatformFile? selectedFile;
  String? fileName;

  @override
  void initState() {
    super.initState();
    selectedPdfType = pdfCategories.first;
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            selectedFile = file;
            fileName = file.name;
          });
          Utils.snackBar('Success', 'Selected: ${file.name}');
        } else {
          Utils.snackBar('Error', 'Could not access file path.');
        }
      }
    } catch (e) {
      print('File picker error: $e');
      Utils.snackBar('Error', 'Failed to pick file: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Get.height * 0.45,
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
            text: 'Upload New PDF',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Choose a category and select a PDF file to upload.',
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
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    decoration: BoxDecoration(
                      color: kGreyColor2,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: MyText(
                      text: fileName ?? 'Tap to select a PDF file',
                      size: 14,
                      color: fileName != null ? kTertiaryColor : kQuaternaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                CustomDropDown(
                  labelText: 'PDF type (Category)',
                  hintText: 'Select PDF type',
                  items: pdfCategories,
                  selectedValue: selectedPdfType,
                  onChanged: (v) {
                    setState(() {
                      selectedPdfType = v;
                    });
                  },
                ),
              ],
            ),
          ),
          MyButton(
            buttonText: 'Upload & Add',
            isLoading: widget.controller.isUploadingFile.value,
            onTap: selectedFile == null
                ? null
                : () async {
              // Close the bottom sheet immediately
              Get.back();

              // Perform upload
              final success = await widget.controller.addNewPdf(
                selectedPdfType,
                selectedFile!.path!,
                fileName!,
              );

              // Show snackbar based on result
              if (success) {
                Utils.snackBar('Success', 'File "$fileName" uploaded successfully.');
              }
            },
          ),

        ],
      ),
    );
  }
}