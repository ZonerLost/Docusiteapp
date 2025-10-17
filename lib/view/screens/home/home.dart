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
import 'package:intl/intl.dart';
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
              // Search App Bar - Shows when searching
              Obx(() {
                final viewModel = Get.find<HomeViewModel>();
                if (viewModel.isSearching.value) {
                  return _buildSearchAppBar(viewModel);
                }
                return _buildNormalAppBar(viewModel);
              }),
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

  SliverAppBar _buildNormalAppBar(HomeViewModel viewModel) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 160,
      backgroundColor: kFillColor,
      automaticallyImplyLeading: false,
      titleSpacing: 20.0,
      title: Obx(() {
        final user = viewModel.currentUserId.value;
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
              GestureDetector(
                onTap: () {
                  viewModel.startSearch();
                },
                child: Image.asset(Assets.imagesSearch, height: 40),
              ),
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
    );
  }

  SliverAppBar _buildSearchAppBar(HomeViewModel viewModel) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      backgroundColor: kFillColor,
      automaticallyImplyLeading: false,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: kFillColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorderColor),
        ),
        child: TextField(
          controller: viewModel.searchController,
          autofocus: true,
          style: TextStyle(
            fontSize: 16,
            color: kTertiaryColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search projects by title...',
            hintStyle: TextStyle(
              fontSize: 16,
              color: kQuaternaryColor,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: IconButton(
              icon: Image.asset(Assets.imagesCancelBlue, height: 16),
              onPressed: () {
                viewModel.searchController.clear();
                viewModel.updateSearchQuery('');
              },
            ),
          ),
          onChanged: (value) {
            viewModel.updateSearchQuery(value);
          },
          onSubmitted: (value) {
            viewModel.updateSearchQuery(value);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            viewModel.stopSearch();
          },
          child: MyText(
            text: 'Cancel',
            color: kSecondaryColor,
            weight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
      ],
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
      // First filter by status tab
      final statusFilteredProjects = viewModel.projects.where((p) {
        if (filterStatus == null || filterStatus == 'All') return true;
        return p.status == filterStatus;
      }).toList();

      // Then apply search filter if searching
      final filteredProjects = statusFilteredProjects.where((project) {
        if (viewModel.isSearching.value && viewModel.searchQuery.isNotEmpty) {
          return project.title.toLowerCase().contains(viewModel.searchQuery.value.toLowerCase());
        }
        return true;
      }).toList();

      if (viewModel.isLoadingProjects.value) {
        return const Center(child: CircularProgressIndicator(color: kSecondaryColor));
      }

      if (filteredProjects.isEmpty) {
        // Show different empty state when searching
        if (viewModel.isSearching.value && viewModel.searchQuery.isNotEmpty) {
          return _SearchEmptyState(query: viewModel.searchQuery.value);
        }
        return const _EmptyState();
      }

      return Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: AppSizes.DEFAULT,
            shrinkWrap: true,
            children: [
              // Only show invites when not searching
              if (!viewModel.isSearching.value) ...[
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
              ],
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: AppSizes.ZERO,
                shrinkWrap: true,
                itemCount: filteredProjects.length,
                itemBuilder: (context, index) {
                  final project = filteredProjects.elementAt(index);
                  return _ProjectCard(project: project);
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
          // Only show add project button when not searching
          if (!viewModel.isSearching.value)
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

class _SearchEmptyState extends StatelessWidget {
  final String query;
  const _SearchEmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Image.asset(Assets.imagesNoProjects, height: 64),
        MyText(
          text: 'No Projects Found',
          paddingTop: 16,
          weight: FontWeight.w500,
          size: 18,
          textAlign: TextAlign.center,
        ),
        MyText(
          text: 'No projects found for "$query".\nTry different keywords.',
          paddingTop: 6,
          lineHeight: 1.5,
          weight: FontWeight.w500,
          size: 14,
          color: kQuaternaryColor,
          textAlign: TextAlign.center,
          paddingBottom: 20,
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  // Helper function to format the date
  String get formattedDeadlineDate {
    return DateFormat('yyyy-MM-dd').format(project.deadline);
  }

  // Helper function to get the latest update message
  String get latestUpdateMessage {
    if (project.lastUpdates.isEmpty) {
      return 'Project created';
    }

    // Sort updates by timestamp to get the latest one
    final sortedUpdates = List<ProjectUpdate>.from(project.lastUpdates)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return sortedUpdates.first.message;
  }

  // Helper function to get time ago for the latest update
  String get latestUpdateTime {
    if (project.lastUpdates.isEmpty) {
      return 'Just now';
    }

    // Sort updates by timestamp to get the latest one
    final sortedUpdates = List<ProjectUpdate>.from(project.lastUpdates)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final latestUpdate = sortedUpdates.first;
    final timeDifference = DateTime.now().difference(latestUpdate.timestamp);

    if (timeDifference.inMinutes < 1) {
      return 'Just now';
    } else if (timeDifference.inMinutes < 60) {
      return '${timeDifference.inMinutes}m ago';
    } else if (timeDifference.inHours < 24) {
      return '${timeDifference.inHours}h ago';
    } else {
      return '${timeDifference.inDays}d ago';
    }
  }

  // Count PDF files
  int get pdfCount {
    return project.files.where((file) => file.fileName.toLowerCase().endsWith('.pdf')).length;
  }

  // Count image files (common image extensions)
  int get imageCount {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    return project.files.where((file) {
      final fileName = file.fileName.toLowerCase();
      return imageExtensions.any((ext) => fileName.endsWith(ext));
    }).length;
  }

  // Count other files (non-PDF, non-image)
  int get otherFilesCount {
    return project.files.length - pdfCount - imageCount;
  }

  @override
  Widget build(BuildContext context) {
    final timeDifference = DateTime.now().difference(project.updatedAt);
    String lastUpdated = timeDifference.inMinutes < 60
        ? '${timeDifference.inMinutes}m ago'
        : '${timeDifference.inHours}h ago';

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
                        text: '${project.clientName} | ${project.location}',
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
                    value: formattedDeadlineDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Combined section for Latest Update and File Counts
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: kGreyColor2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Latest Update Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MyText(
                        text: 'Latest Update',
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                      MyText(
                        text: latestUpdateTime,
                        size: 10,
                        color: kQuaternaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: kFillColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: MyText(
                      text: latestUpdateMessage,
                      size: 11,
                      color: kTertiaryColor,
                      maxLines: 2,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // File Counts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FileCountItem(
                        icon: Icons.picture_as_pdf, // PDF icon
                        count: pdfCount,
                        label: 'PDFs',
                      ),
                      _FileCountItem(
                        icon: Icons.photo_library, // Photos icon
                        count: imageCount,
                        label: 'Photos',
                      ),
                      // _FileCountItem(
                      //   icon: Icons.insert_drive_file, // Document icon for other files
                      //   count: otherFilesCount,
                      //   label: 'Others',
                      // ),
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

// Helper widget for file count items
class _FileCountItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const _FileCountItem({
    required this.icon,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: kSecondaryColor,
            ),
            const SizedBox(width: 4),
            MyText(
              text: '$count',
              size: 12,
              weight: FontWeight.w600,
              color: kSecondaryColor,
            ),
          ],
        ),
        const SizedBox(height: 2),
        MyText(
          text: label,
          size: 10,
          color: kQuaternaryColor,
        ),
      ],
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
  final TextEditingController clientController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController pdfController = TextEditingController();
  final RxString selectedProgress = ''.obs;

  @override
  Widget build(BuildContext context) {
    final HomeViewModel viewModel = Get.find();

    // Initialize controllers with current filter values
    clientController.text = viewModel.filterClient.value;
    locationController.text = viewModel.filterLocation.value;
    selectedProgress.value = viewModel.filterProgress.value;

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
                CustomTagField(
                  labelText: 'Search by Client',
                  controller: clientController,
                  onChanged: (value) {},
                ),
                CustomTagField(
                  labelText: 'Search by Location',
                  controller: locationController,
                  onChanged: (value) {},
                ),
                Obx(() => CustomDropDown(
                  labelText: 'Search by progress',
                  hintText: 'Select progress',
                  items: const ['', '0%', '25%', '50%', '75%', '100%'],
                  selectedValue: selectedProgress.value,
                  onChanged: (value) {
                    selectedProgress.value = value ?? '';
                  },
                )),
                CustomTagField(
                  labelText: 'Search by PDF',
                  controller: pdfController,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: MyBorderButton(
                  buttonText: 'Reset',
                  onTap: () {
                    clientController.clear();
                    locationController.clear();
                    pdfController.clear();
                    selectedProgress.value = '';
                    viewModel.clearFilters();
                    Get.back();
                  },
                  textColor: kQuaternaryColor,
                  bgColor: kFillColor,
                  borderColor: kBorderColor,
                ),
              ),
              Expanded(
                child: MyButton(
                  buttonText: 'Apply Filters',
                  onTap: () {
                    viewModel.applyFilters(
                      client: clientController.text,
                      location: locationController.text,
                      progress: selectedProgress.value,
                      pdf: pdfController.text,
                    );
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
                    errorText: viewModel.fieldErrors['title'],
                    isRequired: true,
                    onChanged: (value) {
                      viewModel.clearFieldError('title');
                    },
                  ),
                  SimpleTextField(
                    controller: viewModel.clientController,
                    labelText: 'Client name',
                    hintText: 'John Smith',
                    errorText: viewModel.fieldErrors['client'],
                    isRequired: true,
                    onChanged: (value) {
                      viewModel.clearFieldError('client');
                    },
                  ),
                  SimpleTextField(
                    controller: viewModel.locationController,
                    labelText: 'Project location',
                    hintText: 'St 3 Wilsons Road, California, USA',
                    errorText: viewModel.fieldErrors['location'],
                    isRequired: true,
                    onChanged: (value) {
                      viewModel.clearFieldError('location');
                    },
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

                  const SizedBox(height: 4),
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
// Display assigned members as tags
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
                                  onTap: () {
                                    viewModel.assignedMembers.remove(member);
                                  },
                                  child: Image.asset(
                                    Assets.imagesCancelBlue,
                                    height: 12,
                                    width: 12,
                                  ),
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
                  // Required fields note
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
