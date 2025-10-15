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
    this.keyboardType,
  }) : super(key: key);

  String? labelText, hintText;
  TextEditingController? controller;
  ValueChanged<String>? onChanged;
  bool? isObSecure, isReadOnly;
  double? marginBottom;
  int? maxLines;
  Widget? suffix;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;

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

    _effectiveController = widget.controller ?? TextEditingController();
    _createdController = widget.controller == null;
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

    return Container(
      margin: EdgeInsets.only(bottom: widget.marginBottom!),
      decoration: BoxDecoration(
        color: kFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1.0,
          color: isFocused ? kSecondaryColor : kInputBorderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Label
                  MyText(
                    text: widget.labelText ?? '',
                    size: 12,
                    color: isFocused ? kSecondaryColor : kQuaternaryColor,
                    weight: FontWeight.w500,
                  ),
                  // Text Field
                  SizedBox(
                    height: 30,
                    child: TextFormField(
                      focusNode: _focusNode,
                      controller: _effectiveController,
                      onChanged: widget.onChanged,
                      onTap: widget.onTap,
                      readOnly: widget.isReadOnly ?? false,
                      obscureText: widget.isObSecure!,
                      obscuringCharacter: '*',
                      maxLines: widget.maxLines,
                      keyboardType: widget.keyboardType,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: kTertiaryColor,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: kTertiaryColor.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
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
    this.keyboardType,
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
  final TextInputType? keyboardType;

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
            controller: controller,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: isReadOnly ?? false,
            obscureText: isObSecure!,
            obscuringCharacter: '*',
            maxLines: maxLines,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.next,
            textAlignVertical: prefix != null || suffix != null
                ? TextAlignVertical.center
                : null,
            cursorColor: kTertiaryColor,
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
                color: kTertiaryColor.withOpacity(0.6),
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