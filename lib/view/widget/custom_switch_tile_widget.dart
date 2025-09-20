// import 'package:flutter/cupertino.dart';
// import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
// import 'package:docu_site/constants/app_colors.dart';
// import 'package:docu_site/constants/app_images.dart';
// import 'package:docu_site/view/widget/my_text_widget.dart';

// class CustomSwitchTile extends StatelessWidget {
//   final String title;
//   final bool value;
//   final ValueChanged<bool>? onChanged;

//   const CustomSwitchTile({
//     required this.title,
//     this.value = false,
//     this.onChanged,
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final controller = ValueNotifier<bool>(value);
//     return Row(
//       children: [
//         Expanded(
//           child: MyText(text: title, weight: FontWeight.w500, size: 14),
//         ),
//         AdvancedSwitch(
//           controller: controller,
//           activeColor: kSecondaryColor,
//           inactiveColor: const Color(0xffDADADA),
//           activeChild: Image.asset(Assets.imagesOn, height: 8),
//           inactiveChild: Padding(
//             padding: const EdgeInsets.only(right: 2),
//             child: Image.asset(Assets.imagesOff, height: 8),
//           ),
//           borderRadius: BorderRadius.circular(50),
//           width: 40.0,
//           height: 24.0,
//           enabled: true,
//           disabledOpacity: 0.5,
//           onChanged: (newValue) {
//             if (onChanged != null) {
//               onChanged!(newValue);
//             }
//           },
//         ),
//       ],
//     );
//   }
// }
