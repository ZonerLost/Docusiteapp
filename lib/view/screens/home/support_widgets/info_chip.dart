

import 'package:flutter/cupertino.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_fonts.dart';

class InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const InfoChip({required this.label, required this.value});

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


