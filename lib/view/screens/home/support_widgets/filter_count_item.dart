// Helper widget for file count items
import 'package:flutter/cupertino.dart';

import '../../../../constants/app_colors.dart';
import '../../../widget/my_text_widget.dart';

class FileCountItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;

  const FileCountItem({
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


