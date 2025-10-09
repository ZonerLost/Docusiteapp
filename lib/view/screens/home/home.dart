import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/main.dart';
import 'package:docu_site/view/screens/home/project_invites.dart';
import 'package:docu_site/view/screens/notifications/notifications.dart';
import 'package:docu_site/view/screens/profile/profile.dart';
import 'package:docu_site/view/screens/project_details/project_details.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/custom_check_box_widget.dart';
import 'package:docu_site/view/widget/custom_drop_down_widget.dart';
import 'package:docu_site/view/widget/custom_tag_field_widget.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../models/project/project.dart';
import '../../../view_model/home/home_view_model.dart';
import '../../widget/invite_member_dialog.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(HomeViewModel());

    return DefaultTabController(
      length: 4,
      initialIndex: 0,
      child: Scaffold(
        body: NestedScrollView(
          physics: const BouncingScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 160,
                backgroundColor: kFillColor,
                automaticallyImplyLeading: false,
                titleSpacing: 20.0,
                title: Obx(() {
                  final user = Get.find<HomeViewModel>().currentUserId.value;
                  final photoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';
                  return GestureDetector(
                    onTap: () {
                      Get.to(() => const Profile());
                    },
                    child: CommonImageView(
                      height: 40,
                      width: 40,
                      radius: 100,
                      url: photoUrl.isNotEmpty ? photoUrl : dummyImg,
                      imagePath: photoUrl.isNotEmpty ? photoUrl : dummyImg,
                      fit: BoxFit.cover,
                    ),
                  );
                }),
                shape: Border(
                  bottom: BorderSide(color: kBorderColor, width: 1.0),
                ),
                actions: [
                  Center(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Get.bottomSheet(
                              _Filter(),
                              isScrollControlled: true,
                            );
                          },
                          child: Image.asset(Assets.imagesFilter, height: 40),
                        ),
                        Image.asset(Assets.imagesSearch, height: 40),
                        GestureDetector(
                          onTap: () {
                            Get.to(() => const Notifications());
                          },
                          child: Image.asset(
                            Assets.imagesNotifications,
                            height: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
                flexibleSpace: Container(
                  color: kFillColor,
                  child: FlexibleSpaceBar(
                    background: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MyText(
                          paddingTop: 40,
                          paddingLeft: 20,
                          text: 'The Site. Simplified.',
                          size: 28,
                          weight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50),
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
                      isScrollable: true,
                      tabs: List.generate(4, (index) {
                        final titles = [
                          'All',
                          'In progress',
                          'Completed',
                          'Cancelled',
                        ];
                        return Tab(text: titles[index]);
                      }),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            physics: const BouncingScrollPhysics(),
            children: const [
              All(),
              All(filterStatus: 'In progress'),
              All(filterStatus: 'Completed'),
              All(filterStatus: 'Cancelled'),
            ],
          ),
        ),
      ),
    );
  }
}

class All extends StatelessWidget {
  final String? filterStatus;
  const All({super.key, this.filterStatus});

  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = Get.find();

    return Obx(() {
      final filteredProjects = viewModel.projects.where((p) {
        if (filterStatus == null || filterStatus == 'All') return true;
        return p.status == filterStatus;
      }).toList();

      if (viewModel.isLoadingProjects.value) {
        return const Center(child: CircularProgressIndicator(color: kSecondaryColor));
      }

      if (filteredProjects.isEmpty) {
        return const _EmptyState();
      }

      return Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: AppSizes.DEFAULT,
            shrinkWrap: true,
            children: [
              GestureDetector(
                onTap: () {
                  Get.to(() => ProjectInvites());
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kFillColor,
                    border: Border.all(color: kBorderColor, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        Assets.imagesPendingInvites,
                        height: 40,
                        width: 40,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MyText(
                              size: 14,
                              weight: FontWeight.w700,
                              text: '${viewModel.pendingInvitesCount.value} Pending Invite${viewModel.pendingInvitesCount.value == 1 ? '' : 's'}',
                            ),
                            MyText(
                              paddingTop: 4,
                              size: 12,
                              color: kQuaternaryColor,
                              text: 'You have received ${viewModel.pendingInvitesCount.value} new project${viewModel.pendingInvitesCount.value == 1 ? '' : 's'} invite${viewModel.pendingInvitesCount.value == 1 ? '' : 's'}.',
                            ),
                          ],
                        ),
                      ),
                      Image.asset(Assets.imagesArrowNext, height: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: AppSizes.ZERO,
                shrinkWrap: true,
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects[index];
                  return _ProjectCard(project: project);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 70,
            right: 70,
            child: MyButton(
              buttonText: '+ Add new project',
              onTap: () {
                viewModel.assignedMembers.clear();
                viewModel.hasEditAccess.value = false;
                Get.bottomSheet(_AddNewProject(), isScrollControlled: true);
              },
            ),
          ),
        ],
      );
    });
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final timeDifference = DateTime.now().difference(project.updatedAt);
    String lastUpdated = timeDifference.inMinutes < 60
        ? '${timeDifference.inMinutes} mins ago'
        : '${timeDifference.inHours} hours ago';

    return GestureDetector(
      onTap: () {
        Get.to(() => ProjectDetails(projectId: project.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
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
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MyText(
                        text: project.title,
                        size: 14,
                        weight: FontWeight.w500,
                      ),
                      MyText(
                        text: '${project.clientName}  |  ${project.location}',
                        color: kQuaternaryColor,
                        size: 12,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Stack(
                    children: List.generate(
                      project.collaborators.take(3).length,
                          (index) {
                        final member = project.collaborators[index];
                        return Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 0 : index * 16.0,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: kFillColor,
                              width: 1,
                            ),
                          ),
                          child: CommonImageView(
                            height: 24,
                            width: 24,
                            radius: 100,
                            url: member.photoUrl.isNotEmpty ? member.photoUrl : dummyImg,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _InfoChip(
                    label: 'Last updated:',
                    value: lastUpdated,
                  ),
                ),
                Expanded(
                  child: _InfoChip(
                    label: 'Deadline:',
                    value: project.deadline.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: kGreyColor2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyText(
                    text: 'Progress',
                    size: 12,
                    paddingBottom: 5,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: LinearPercentIndicator(
                          lineHeight: 8.0,
                          percent: project.progress,
                          padding: AppSizes.ZERO,
                          backgroundColor: kFillColor,
                          progressColor: kSecondaryColor,
                          barRadius: const Radius.circular(50),
                        ),
                      ),
                      MyText(
                        text: '${(project.progress * 100).toInt()}%',
                        paddingLeft: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: kGreyColor2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          width: 1.0,
          color: kBorderColor,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            fontFamily: AppFonts.SFProDisplay,
            color: kGreyColor3.withValues(alpha: 0.7),
          ),
          children: [
            TextSpan(text: label),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: kTertiaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(Assets.imagesNoProjects, height: 64),
        MyText(
          text: 'No Projects Added Yet!',
          paddingTop: 16,
          weight: FontWeight.w500,
          size: 18,
          textAlign: TextAlign.center,
        ),
        MyText(
          text: 'Your projects will be shown up here.\nTap to add new project.',
          paddingTop: 6,
          lineHeight: 1.5,
          weight: FontWeight.w500,
          size: 14,
          color: kQuaternaryColor,
          textAlign: TextAlign.center,
          paddingBottom: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            SizedBox(
              width: 125,
              child: MyButton(
                bgColor: kFillColor,
                height: 40,
                buttonText: 'View Invites',
                onTap: () {
                  Get.to(() => ProjectInvites());
                },
                radius: 12,
                textSize: 14,
                textColor: kQuaternaryColor,
              ),
            ),
            SizedBox(
              width: 125,
              child: MyButton(
                height: 40,
                buttonText: '+ Add new',
                onTap: () {
                  Get.bottomSheet(_AddNewProject(), isScrollControlled: true);
                },
                radius: 12,
                textSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class _Filter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyText(
            text: 'Select Filters',
            size: 18,
            weight: FontWeight.w500,
            paddingBottom: 8,
          ),
          MyText(
            text: 'Please select the filters as per your preferences.',
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
                CustomTagField(labelText: 'Search by Client'),
                CustomTagField(labelText: 'Search by Location'),
                CustomDropDown(
                  labelText: 'Search by progress',
                  hintText: '50%',
                  items: const ['0%', '25%', '50%', '75%', '100%'],
                  selectedValue: '50%',
                  onChanged: (v) {},
                ),
                CustomTagField(labelText: 'Search by PDF'),
              ],
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: MyBorderButton(
                  buttonText: 'Reset',
                  onTap: () {},
                  textColor: kQuaternaryColor,
                  bgColor: kFillColor,
                  borderColor: kBorderColor,
                ),
              ),
              Expanded(
                child: MyButton(
                  buttonText: 'Apply Filters',
                  onTap: () {
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddNewProject extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = Get.find();

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
                    controller: viewModel.titleController,
                    labelText: 'Project Title',
                    hintText: '200sq ft 4 bedroom Villa',
                  ),
                  SimpleTextField(
                    controller: viewModel.clientController,
                    labelText: 'Client name',
                    hintText: 'John Smith',
                  ),
                  SimpleTextField(
                    controller: viewModel.locationController,
                    labelText: 'Project location',
                    hintText: 'St 3 Wilsons Road, California, USA',
                  ),
                  SimpleTextField(
                    controller: viewModel.deadlineController,
                    labelText: 'Project Deadline',
                    hintText: 'Select date',
                    isReadOnly: true,
                    onTap: viewModel.selectDeadlineDate,
                  ),
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
                  CustomTagField(
                    tags: viewModel.assignedMembers.map((c) => c.name).toList(),
                    labelText: 'Assigned: ${viewModel.assignedMembers.length} member(s)',
                    readOnly: true,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    spacing: 20,
                    children: [
                      Row(
                        spacing: 4,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomCheckBox(
                            circularRadius: 5,
                            isActive: viewModel.hasViewAccess.value,
                            onTap: () => viewModel.toggleAccess(false),
                            radius: 20,
                          ),
                          MyText(
                            text: 'View Access',
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                      Row(
                        spacing: 4,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CustomCheckBox(
                            circularRadius: 5,
                            isActive: viewModel.hasEditAccess.value,
                            onTap: () => viewModel.toggleAccess(true),
                            radius: 20,
                          ),
                          MyText(
                            text: 'Edit Access',
                            size: 14,
                            weight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MyButton(
              buttonText: 'Add',
              isLoading: viewModel.isSavingProject.value,
              onTap: () {
                if (!viewModel.isSavingProject.value) {
                  viewModel.createNewProject();
                }
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

