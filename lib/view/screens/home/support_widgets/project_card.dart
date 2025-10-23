


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:intl/intl.dart';

import '../../../../constants/app_colors.dart';
import '../../../../main.dart';
import '../../../../models/project/project.dart';
import '../../../../models/project/project_update.dart';
import '../../../widget/common_image_view_widget.dart';
import '../../../widget/my_text_widget.dart';
import '../../project_details/project_details.dart';
import 'filter_count_item.dart';
import 'info_chip.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  const ProjectCard({required this.project});

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
                  child: InfoChip(
                    label: 'Last updated:',
                    value: lastUpdated,
                  ),
                ),
                Expanded(
                  child: InfoChip(
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
                      FileCountItem(
                        icon: Icons.picture_as_pdf, // PDF icon
                        count: pdfCount,
                        label: 'PDFs',
                      ),
                      FileCountItem(
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
