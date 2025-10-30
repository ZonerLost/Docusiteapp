import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../constants/app_colors.dart';
import '../../../../main.dart';
import '../../../../models/project/project.dart';
import '../../../../models/project/project_update.dart';
import '../../../widget/common_image_view_widget.dart';
import '../../../widget/my_text_widget.dart';
import '../../project_details/project_details.dart';
import 'filter_count_item.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final int index;
  const ProjectCard({required this.project, required this.index, super.key});

  // ---- Helpers ----
  String get _deadline => DateFormat('dd/MM/yy').format(project.deadline);

  String get _lastUpdated {
    final d = DateTime.now().difference(project.updatedAt);
    if (d.inDays > 0) return '${d.inDays} days ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  String get _latestMsg {
    if (project.lastUpdates.isEmpty) return 'Project created';
    final s = List<ProjectUpdate>.from(project.lastUpdates)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return s.first.message;
  }

  String get _latestWhen {
    if (project.lastUpdates.isEmpty) return 'Just now';
    final s = List<ProjectUpdate>.from(project.lastUpdates)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final d = DateTime.now().difference(s.first.timestamp);
    if (d.inDays > 0) return '${d.inDays} days';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'Just now';
  }

  int get _pdfs =>
      project.files.where((f) => f.fileName.toLowerCase().endsWith('.pdf')).length;

  int get _images {
    const exts = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    return project.files
        .where((f) => exts.any((e) => f.fileName.toLowerCase().endsWith(e)))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final headerColors = [
      const Color(0xFF77DD77),
      const Color(0xFFFF746C),
      const Color(0xFFFFC067),
      const Color(0xFFB39EB5),
      const Color(0xFFAFD5F0),
    ];
    final headerColor = headerColors[index % headerColors.length];

    return GestureDetector(
      onTap: () => Get.to(() => ProjectDetails(projectId: project.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kFillColor,
          border: Border.all(color: kBorderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== TITLE BAR =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.45),
                borderRadius: BorderRadius.circular(6),
              ),
              child: MyText(
                text: project.title,
                size: 15,
                weight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            // ===== INFO SECTIONS =====
            _infoRowWithDivider('Location', project.location),
            _memberRowWithDivider(),
            _infoRowWithDivider('Deadline', _deadline),
            _infoRowWithDivider('Last Updated', _lastUpdated),

            // ===== LATEST UPDATE =====
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyText(
                  text: 'Latest Update:',
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: kTertiaryColor,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: kGreyColor2,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: MyText(
                    text: _latestMsg,
                    size: 11.5,
                    color: kTertiaryColor,
                    maxLines: 2,
                    textOverflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ===== FILE COUNTS =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: kGreyColor2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  FileCountItem(icon: Icons.picture_as_pdf, count: _pdfs),
                  FileCountItem(icon: Icons.camera_alt_outlined, count: _images),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helper Widgets =====

  Widget _infoRowWithDivider(String label, String value) {
    return Column(
      children: [
        _infoRow(label, value),
        const Divider(
          color: Colors.black12,
          height: 8,
          thickness: 0.7,
        ),
      ],
    );
  }

  Widget _memberRowWithDivider() {
    return Column(
      children: [
        _memberRow(),
        const Divider(
          color: Colors.black12,
          height: 8,
          thickness: 0.7,
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            text: '$label:',
            size: 12.5,
            weight: FontWeight.w600,
            color: kTertiaryColor,
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: MyText(
                text: value.isEmpty ? '—' : value,
                size: 12.5,
                color: kQuaternaryColor,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberRow() {
    final members = project.collaborators.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyText(
            text: 'Members:',
            size: 12.5,
            weight: FontWeight.w600,
            color: kTertiaryColor,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(members.length, (i) {
              final member = members[i];
              return Padding(
                padding: const EdgeInsets.only(left: 3),
                child: CommonImageView(
                  height: 20,
                  width: 20,
                  radius: 100,
                  url: member.photoUrl.isNotEmpty ? member.photoUrl : dummyImg,
                  fit: BoxFit.cover,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
