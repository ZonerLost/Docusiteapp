import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/view/widget/my_text_widget.dart';

// ignore: must_be_immutable
class MyTextField extends StatefulWidget {
  MyTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.isObSecure = false,
    this.marginBottom = 8.0,
    this.maxLines = 1,
    this.suffix,
    this.isReadOnly,
    this.onTap,
  }) : super(key: key);

  String? labelText, hintText;
  TextEditingController? controller;
  ValueChanged<String>? onChanged;
  bool? isObSecure, isReadOnly;
  double? marginBottom;
  int? maxLines;
  Widget? suffix;
  final VoidCallback? onTap;

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late FocusNode _focusNode;
  late TextEditingController _effectiveController;
  bool _createdController = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));

    if (widget.controller == null) {
      _effectiveController = TextEditingController();
      _createdController = true;
    } else {
      _effectiveController = widget.controller!;
    }
    _effectiveController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    if (_createdController) _effectiveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFocused = _focusNode.hasFocus;
    final bool hasValue = _effectiveController.text.isNotEmpty;
    final bool showField = isFocused || hasValue;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _focusNode.requestFocus();
        if (widget.onTap != null) widget.onTap!();
      },
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          margin: EdgeInsets.only(bottom: widget.marginBottom!),
          decoration: BoxDecoration(
            color: kFillColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(width: 1.0, color: kInputBorderColor),
          ),
          child: AnimatedPadding(
            padding: EdgeInsets.fromLTRB(14, 12, 0, 12),
            duration: Duration(milliseconds: 180),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MyText(
                        text: widget.labelText ?? '',
                        size: 12,
                        color: isFocused ? kQuaternaryColor : kTertiaryColor,
                        weight: FontWeight.w500,
                      ),
                      if (showField)
                        SizedBox(
                          height: 30,
                          child: TextFormField(
                            onTap: widget.onTap,
                            cursorColor: kTertiaryColor,
                            maxLines: widget.maxLines,
                            readOnly: widget.isReadOnly ?? false,
                            controller: _effectiveController,
                            onChanged: widget.onChanged,
                            textInputAction: TextInputAction.next,
                            obscureText: widget.isObSecure!,
                            obscuringCharacter: '*',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: kTertiaryColor,
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              hintText: widget.hintText,
                              hintStyle: TextStyle(
                                fontSize: 16,
                                color: kTertiaryColor.withValues(alpha: 0.4),
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (widget.suffix != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: widget.suffix!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleTextField extends StatelessWidget {
  SimpleTextField({
    Key? key,
    this.controller,
    this.hintText,
    this.labelText,
    this.onChanged,
    this.isObSecure = false,
    this.marginBottom = 12.0,
    this.maxLines = 1,
    this.labelSize,
    this.prefix,
    this.suffix,
    this.isReadOnly,
    this.onTap,
  }) : super(key: key);

  final String? labelText, hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool? isObSecure, isReadOnly;
  final double? marginBottom;
  final int? maxLines;
  final double? labelSize;
  final Widget? prefix, suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: marginBottom!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (labelText != null)
            MyText(
              text: labelText ?? '',
              paddingBottom: 4,
              size: 14,
              weight: FontWeight.w500,
              color: kQuaternaryColor,
            ),
          TextFormField(
            onTap: onTap,
            textAlignVertical: prefix != null || suffix != null
                ? TextAlignVertical.center
                : null,
            cursorColor: kTertiaryColor,
            maxLines: maxLines,
            readOnly: isReadOnly ?? false,
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.next,
            obscureText: isObSecure!,
            obscuringCharacter: '*',
            style: TextStyle(
              fontSize: 16,
              color: kTertiaryColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: kFillColor,
              prefixIcon: prefix,
              suffixIcon: suffix,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 15,
                vertical: maxLines! > 1 ? 15 : 0,
              ),
              hintText: hintText,
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
            ),
          ),
        ],
      ),
    );
  }
}
