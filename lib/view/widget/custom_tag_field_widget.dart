import 'dart:math';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:textfield_tags/textfield_tags.dart';

class CustomTagField extends StatefulWidget {
  const CustomTagField({Key? key, this.labelText, this.marginBottom = 12,this.readOnly,this.tags})
    : super(key: key);

  final String? labelText;
  final double? marginBottom;
  final bool? readOnly;
  final List<String>? tags;

  @override
  State<CustomTagField> createState() => _CustomTagFieldState();
}

class _CustomTagFieldState extends State<CustomTagField> {
  late double _distanceToField;
  late DynamicTagController<DynamicTagData> _dynamicTagController;
  final random = Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _distanceToField = MediaQuery.of(context).size.width;
  }

  @override
  void dispose() {
    super.dispose();
    _dynamicTagController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _dynamicTagController = DynamicTagController<DynamicTagData>();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: widget.marginBottom!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.labelText != null)
            MyText(
              text: widget.labelText ?? '',
              paddingBottom: 4,
              size: 14,
              weight: FontWeight.w500,
              color: kQuaternaryColor,
            ),
          TextFieldTags(
            textfieldTagsController: _dynamicTagController,
            textSeparators: const [' ', ','],
            letterCase: LetterCase.normal,
            validator: (DynamicTagData tag) {
              if (_dynamicTagController.getTags!.any(
                (element) => element.tag == tag.tag,
              )) {
                return '';
              }
              return null;
            },
            inputFieldBuilder: (context, inputFieldValues) {
              return TextField(
                style: TextStyle(
                  fontSize: 16,
                  color: kTertiaryColor,
                  fontWeight: FontWeight.w500,
                ),
                controller: inputFieldValues.textEditingController,
                focusNode: inputFieldValues.focusNode,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: kFillColor,
                  suffixIcon: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(Assets.imagesSearchIcon, height: 20),
                    ],
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: inputFieldValues.tags.isEmpty ? 15 : 0,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: kTertiaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: inputFieldValues.tags.isNotEmpty ? '' : '',
                  errorText: inputFieldValues.error,
                  prefixIconConstraints: BoxConstraints(
                    maxWidth: _distanceToField * 0.5,
                  ),
                  prefixIcon: inputFieldValues.tags.isNotEmpty
                      ? SizedBox(
                          height: 30,
                          child: ListView.separated(
                            controller: inputFieldValues.tagScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            itemCount: inputFieldValues.tags.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 5.0),
                            itemBuilder: (context, index) {
                              final tag = inputFieldValues.tags[index];
                              return Container(
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: kSecondaryColor.withValues(alpha: 0.1),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${tag.tag}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: kSecondaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4.0),
                                    GestureDetector(
                                      onTap: () {
                                        inputFieldValues.onTagRemoved(tag);
                                      },
                                      child: Image.asset(
                                        Assets.imagesCancelBlue,
                                        height: 10,
                                        width: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : null,
                ),
                onChanged: (value) {
                  final tagData = DynamicTagData(value, null);
                  inputFieldValues.onTagChanged(tagData);
                },
                onSubmitted: (value) {
                  final tagData = DynamicTagData(value, null);
                  inputFieldValues.onTagSubmitted(tagData);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
