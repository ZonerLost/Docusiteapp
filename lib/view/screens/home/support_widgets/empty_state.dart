import 'package:flutter/cupertino.dart';
import 'package:get/Get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_images.dart';
import '../../../widget/my_button_widget.dart';
import '../../../widget/my_text_widget.dart';
import 'project_invites.dart';
import 'add_new_project.dart';

class EmptyState extends StatelessWidget {
  const EmptyState();

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
                  Get.bottomSheet(AddNewProject(), isScrollControlled: true);
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