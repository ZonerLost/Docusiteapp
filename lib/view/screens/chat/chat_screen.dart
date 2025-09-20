import 'package:docu_site/main.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
// Removed unused imports

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      "role": "user",
      "text":
          "I only have 5 minutes to place a bet, give me the best bet for today!",
      "time": _formatTime(DateTime.now()),
    },
    {
      "role": "assistant",
      "text":
          "Lamine Yamal is currently averaging 6 regular shots and 2.7 Shots on target per game playing at home. Real Madrid allows most shots per goal to right wingers in La Liga, they concede 7 Shots on target playing away",
      "time": _formatTime(DateTime.now()),
    },
  ];

  static String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $ampm';
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _messages.add({
        "role": "user",
        "text": text,
        "time": _formatTime(now),
        "date": DateTime(now.year, now.month, now.day),
      });
      _controller.clear();
      _messages.add({
        "role": "assistant",
        "text": "(AI response placeholder)",
        "time": _formatTime(now),
        "date": DateTime(now.year, now.month, now.day),
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Back'),
      body: Column(
        children: [
          Expanded(child: buildGroupedChatList()),
          Container(
            padding: AppSizes.DEFAULT,
            decoration: BoxDecoration(
              color: kFillColor,
              border: Border(top: BorderSide(color: kBorderColor, width: 1.0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TextFormField(
                      controller: _controller,
                      cursorColor: kTertiaryColor,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        color: kTertiaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.SFProDisplay,
                      ),
                      decoration: InputDecoration(
                        suffixIcon: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [Image.asset(Assets.imagesCam, height: 20)],
                        ),
                        hintText: 'Type here...',
                        hintStyle: TextStyle(
                          color: kQuaternaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: AppFonts.SFProDisplay,
                        ),
                        filled: true,
                        fillColor: Color(0xffF4F4F4),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Image.asset(Assets.imagesSend, height: 44),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildGroupedChatList() {
    if (_messages.isEmpty) return SizedBox.shrink();
    final List<Widget> chatWidgets = [];
    DateTime? lastDate;
    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final isUser = msg["role"] == "user";
      final DateTime msgDate = msg["date"] ?? DateTime.now();
      final bool showDate = lastDate == null || !isSameDay(lastDate, msgDate);
      if (showDate) {
        chatWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: kFillColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatDate(msgDate),
                  style: TextStyle(
                    color: kQuaternaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
        lastDate = msgDate;
      }
      chatWidgets.add(
        Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.fromLTRB(
                  isUser ? 60 : 0,
                  0,
                  isUser ? 0 : 60,
                  4,
                ),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? kSecondaryColor : kFillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  msg["text"] ?? '',
                  style: TextStyle(
                    color: isUser ? kFillColor : kTertiaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 60.0 : 0.0,
                right: isUser ? 0.0 : 60.0,
                bottom: 12.0,
                top: 2.0,
              ),
              child: Row(
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isUser)
                    CommonImageView(
                      height: 20,
                      width: 20,
                      radius: 100,
                      url: dummyImg,
                      fit: BoxFit.cover,
                    ),
                  if (!isUser) SizedBox(width: 4),
                  Text(
                    msg['time']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: kQuaternaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Image.asset(
                    Assets.imagesDoubleTick,
                    height: 16,
                    color: kSecondaryColor,
                  ),
                  if (isUser) SizedBox(width: 4),
                  if (isUser)
                    CommonImageView(
                      height: 20,
                      width: 20,
                      radius: 100,
                      url: dummyImg,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      controller: _scrollController,
      shrinkWrap: true,
      physics: BouncingScrollPhysics(),
      padding: AppSizes.DEFAULT,
      children: chatWidgets,
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) return "Today";
    if (isSameDay(date, now.subtract(Duration(days: 1)))) return "Yesterday";
    return DateFormat('MMM d, yyyy').format(date);
  }
}
