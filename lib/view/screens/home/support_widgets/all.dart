import 'package:docu_site/view/screens/home/support_widgets/project_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_images.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../controllers/home/home_controller.dart';
import '../../../widget/my_button_widget.dart';
import '../../../widget/my_text_widget.dart';
import 'project_invites.dart';
import 'add_new_project.dart';
import 'empty_state.dart';
import 'search_empty_state.dart';



class All extends StatelessWidget {
  final String? filterStatus;
  const All({super.key, this.filterStatus});

  @override
  Widget build(BuildContext context) {
    final HomeController viewModel = Get.find();

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
        // (Optional) You can also make this refreshable; keeping simple loader here.
        return const Center(child: CircularProgressIndicator(color: kSecondaryColor));
      }

      // Build a scrollable child for RefreshIndicator
      Widget scrollableChild;

      if (filteredProjects.isEmpty) {
        // Empty states need a scrollable container for pull-to-refresh.
        final Widget empty = (viewModel.isSearching.value && viewModel.searchQuery.isNotEmpty)
            ? SearchEmptyState(query: viewModel.searchQuery.value)
            : const EmptyState();

        scrollableChild = ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            empty,
            const SizedBox(height: 120),
          ],
        );
      } else {
        scrollableChild = ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: AppSizes.DEFAULT,
          children: [
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
                      Image.asset(Assets.imagesPendingInvites, height: 40, width: 40),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MyText(
                              size: 14,
                              weight: FontWeight.w700,
                              text:
                              '${viewModel.pendingInvitesCount.value} Pending Invite${viewModel.pendingInvitesCount.value == 1 ? '' : 's'}',
                            ),
                            MyText(
                              paddingTop: 4,
                              size: 12,
                              color: kQuaternaryColor,
                              text:
                              'You have received ${viewModel.pendingInvitesCount.value} new project${viewModel.pendingInvitesCount.value == 1 ? '' : 's'} invite${viewModel.pendingInvitesCount.value == 1 ? '' : 's'}.',
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
            // Projects list
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: AppSizes.ZERO,
              shrinkWrap: true,
              itemCount: filteredProjects.length,
              itemBuilder: (context, index) {
                final project = filteredProjects.elementAt(index);
                return ProjectCard(
                  project: project,
                  index: index, // 👈 add this line
                );              },
            ),
            const SizedBox(height: 80),
          ],
        );
      }

      return Stack(
        children: [
          RefreshIndicator(
            color: kSecondaryColor,
            backgroundColor: kFillColor,
            displacement: 24,
            strokeWidth: 2.2,
            onRefresh: () => viewModel.refreshProjects(),
            child: scrollableChild,
          ),
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
                  Get.bottomSheet(AddNewProject(), isScrollControlled: true);
                },
              ),
            ),
        ],
      );
    });
  }

}