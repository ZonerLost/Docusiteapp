import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expandable/expandable.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';

class HelpAndSupport extends StatelessWidget {
  const HelpAndSupport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Help & Support'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('app_faqs')
            .orderBy('orderIndex', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: MyText(text: "No FAQs available."));
          }

          final faqDocs = snapshot.data!.docs;

          return ListView.builder(
            padding: AppSizes.DEFAULT,
            physics: BouncingScrollPhysics(),
            itemCount: faqDocs.length,
            itemBuilder: (context, index) {
              final faq = faqDocs[index].data() as Map<String, dynamic>;
              return _Faq(
                title: faq['question'] ?? 'Untitled',
                subTitle: faq['answer'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

class _Faq extends StatefulWidget {
  const _Faq({required this.title, required this.subTitle});
  final String title;
  final String subTitle;

  @override
  State<_Faq> createState() => _FaqState();
}

class _FaqState extends State<_Faq> {
  late ExpandableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ExpandableController(initialExpanded: false);
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 1.0, color: kBorderColor),
      ),
      child: ExpandableNotifier(
        controller: _controller,
        child: ScrollOnExpand(
          child: ExpandablePanel(
            controller: _controller,
            theme: ExpandableThemeData(tapHeaderToExpand: true, hasIcon: false),
            header: Container(
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: MyText(
                      text: widget.title,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ),
                  Image.asset(
                    _controller.expanded
                        ? Assets.imagesShrink
                        : Assets.imagesExpand,
                    height: 24,
                    color: kTertiaryColor,
                  ),
                ],
              ),
            ),
            collapsed: SizedBox(),
            expanded: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  height: 1,
                  color: kBorderColor,
                ),
                MyText(
                  text: widget.subTitle,
                  weight: FontWeight.w500,
                  color: kQuaternaryColor,
                  lineHeight: 1.5,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
