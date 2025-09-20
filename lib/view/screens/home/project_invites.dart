import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';

class ProjectInvites extends StatelessWidget {
  const ProjectInvites({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Project Invites'),
      body: ListView.builder(
        itemCount: 2,
        padding: AppSizes.DEFAULT,
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(12),
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
                        spacing: 4,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MyText(
                            text: '2 Bedrooms Flat + Interior',
                            size: 16,
                            weight: FontWeight.w500,
                          ),
                          MyText(
                            text: 'Deadline : June 23, 2025',
                            color: kQuaternaryColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: MyButton(
                        buttonText: 'New Invites',
                        onTap: () {},
                        height: 30,
                        radius: 50,
                        textSize: 12,
                        textColor: kSecondaryColor,
                        bgColor: kSecondaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: 1,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  color: kBorderColor,
                ),
                Column(
                  spacing: 10,
                  children: List.generate(3, (index) {
                    final info = [
                      {'label': 'Client name', 'value': 'John Smith'},
                      {
                        'label': 'Project Location',
                        'value': 'St3 Wilson road, New York',
                      },
                      {'label': 'Assign by', 'value': 'Chris Taylor (Admin)'},
                    ];
                    return Row(
                      children: [
                        Expanded(
                          child: MyText(
                            text: info[index]['label']!,
                            color: kQuaternaryColor,
                          ),
                        ),
                        MyText(
                          text: info[index]['value']!,
                          weight: FontWeight.w500,
                        ),
                      ],
                    );
                  }),
                ),
                SizedBox(height: 16),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: MyBorderButton(
                        borderColor: kBorderColor,
                        bgColor: kGreyColor,
                        textColor: kQuaternaryColor,
                        height: 40,
                        textSize: 14,
                        buttonText: 'Decline',
                        onTap: () {},
                      ),
                    ),
                    Expanded(
                      child: MyButton(
                        buttonText: 'Accept Invite',
                        onTap: () {},
                        height: 40,
                        textSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
