import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/utils/utils.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:get/Get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../main.dart';
import '../../../services/chat_services/firestor_chat_services.dart';

class ChatScreen extends StatefulWidget {
  final String projectId;
  final List<String> collaboratorIds;
  final List<String> collaboratorEmails;

  const ChatScreen({
    super.key,
    required this.projectId,
    required this.collaboratorIds,
    required this.collaboratorEmails,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreChatServices _chatServices = FirestoreChatServices();
  final User? _user = FirebaseAuth.instance.currentUser;
  final EmojiParser _emojiParser = EmojiParser();
  late Stream<QuerySnapshot> _messagesStream;
  Map<String, dynamic>? _replyingTo;
  bool _isTyping = false;
  bool _isLoading = true;
  bool _groupChatExists = false;

  @override
  void initState() {
    super.initState();
    _checkGroupChat();
  }

  Future<void> _checkGroupChat() async {
    try {
      final exists = await _chatServices.groupChatExists(widget.projectId);
      setState(() {
        _groupChatExists = exists;
        _isLoading = false;
        if (exists) {
          _messagesStream = _chatServices.getMessages(widget.projectId);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _groupChatExists = false; // Treat error as no group chat
      });
    }
  }

  Future<void> _createGroupChat() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _chatServices.initializeGroupChat(
        widget.projectId,
        widget.collaboratorIds,
        widget.collaboratorEmails,
      );
      setState(() {
        _groupChatExists = true;
        _messagesStream = _chatServices.getMessages(widget.projectId);
        _isLoading = false;
      });
    } catch (e) {
      Utils.snackBar('Error', 'Failed to create group chat: $e');
      print(e.toString());
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await _chatServices.sendMessage(
        widget.projectId,
        text,
        replyTo: _replyingTo,
      );
      _controller.clear();
      setState(() => _replyingTo = null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      Utils.snackBar('Error', 'Failed to send message: $e');
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Image from Gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              final downloadUrl = await _chatServices.pickAndUploadMedia(
                widget.projectId,
                source: ImageSource.gallery,
                isVideo: false,
              );
              if (downloadUrl != null) {
                await _chatServices.sendMessage(
                  widget.projectId,
                  '',
                  messageType: 'image',
                  mediaUrl: downloadUrl,
                  replyTo: _replyingTo,
                );
                setState(() => _replyingTo = null);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Image from Camera'),
            onTap: () async {
              Navigator.pop(ctx);
              final downloadUrl = await _chatServices.pickAndUploadMedia(
                widget.projectId,
                source: ImageSource.camera,
                isVideo: false,
              );
              if (downloadUrl != null) {
                await _chatServices.sendMessage(
                  widget.projectId,
                  '',
                  messageType: 'image',
                  mediaUrl: downloadUrl,
                  replyTo: _replyingTo,
                );
                setState(() => _replyingTo = null);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Video from Gallery'),
            onTap: () async {
              Navigator.pop(ctx);
              final downloadUrl = await _chatServices.pickAndUploadMedia(
                widget.projectId,
                source: ImageSource.gallery,
                isVideo: true,
              );
              if (downloadUrl != null) {
                await _chatServices.sendMessage(
                  widget.projectId,
                  '',
                  messageType: 'video',
                  mediaUrl: downloadUrl,
                  replyTo: _replyingTo,
                );
                setState(() => _replyingTo = null);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam),
            title: const Text('Video from Camera'),
            onTap: () async {
              Navigator.pop(ctx);
              final downloadUrl = await _chatServices.pickAndUploadMedia(
                widget.projectId,
                source: ImageSource.camera,
                isVideo: true,
              );
              if (downloadUrl != null) {
                await _chatServices.sendMessage(
                  widget.projectId,
                  '',
                  messageType: 'video',
                  mediaUrl: downloadUrl,
                  replyTo: _replyingTo,
                );
                setState(() => _replyingTo = null);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isMe = data['userId'] == _user?.uid;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              setState(() => _replyingTo = {
                'messageId': message.id,
                'message': data['message'],
                'sender': data['sentBy'],
              });
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions),
            title: const Text('Add Reaction'),
            onTap: () {
              Navigator.pop(ctx);
              _showEmojiPicker(message.id);
            },
          ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete Message'),
              onTap: () async {
                await _chatServices.deleteMessage(widget.projectId, message.id);
                Navigator.pop(ctx);
              },
            ),
        ],
      ),
    );
  }

  void _showEmojiPicker(String messageId) {
    final emojis = ['😊', '👍', '❤️', '😂', '😢'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        spacing: 8,
        children: emojis
            .map((emoji) => GestureDetector(
          onTap: () async {
            await _chatServices.addReaction(widget.projectId, messageId, emoji);
            Navigator.pop(ctx);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ))
            .toList(),
      ),
    );
  }

  static String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour < 12 ? 'am' : 'pm';
    return '$hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_groupChatExists) {
      return Scaffold(
        appBar: simpleAppBar(title: 'Back'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No group chat exists for this project.',
                style: TextStyle(
                  color: kTertiaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFonts.SFProDisplay,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createGroupChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSecondaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  'Start Group Chat',
                  style: TextStyle(
                    color: kFillColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: AppFonts.SFProDisplay,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: simpleAppBar(title: 'Back'),
      body: Column(
        children: [
          Expanded(child: buildGroupedChatList()),
          if (_replyingTo != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kFillColor,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!['sender']}: ${_replyingTo!['message']}',
                      style: TextStyle(color: kQuaternaryColor, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: Icon(Icons.close, color: kQuaternaryColor, size: 20),
                  ),
                ],
              ),
            ),
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
                          children: [
                            GestureDetector(
                              onTap: _showMediaPicker,
                              child: Image.asset(Assets.imagesCam, height: 20),
                            ),
                          ],
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
                      onChanged: (value) {
                        if (value.isNotEmpty && !_isTyping) {
                          _chatServices.setTypingStatus(widget.projectId, true);
                          _isTyping = true;
                        } else if (value.isEmpty && _isTyping) {
                          _chatServices.setTypingStatus(widget.projectId, false);
                          _isTyping = false;
                        }
                      },
                      onEditingComplete: () {
                        _chatServices.setTypingStatus(widget.projectId, false);
                        _isTyping = false;
                        _sendMessage();
                      },
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
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading chats. Please try again.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No chats yet. Start a conversation!'));
        }

        final messages = snapshot.data!.docs;
        final List<Widget> chatWidgets = [];
        DateTime? lastDate;

        for (var message in messages) {
          final data = message.data() as Map<String, dynamic>;
          final isUser = data['userId'] == _user?.uid;
          final timestamp = data['sentAt'] as Timestamp?;
          final msgDate = timestamp?.toDate() ?? DateTime.now();
          final showDate = lastDate == null || !isSameDay(lastDate, msgDate);

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
            GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (data['replyTo'] != null)
                    Container(
                      margin: EdgeInsets.fromLTRB(isUser ? 60 : 8, 0, isUser ? 8 : 60, 4),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kFillColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Replying to ${data['replyTo']['sender']}: ${data['replyTo']['message']}',
                        style: TextStyle(color: kQuaternaryColor, fontSize: 12),
                      ),
                    ),
                  Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(
                        isUser ? 60 : 8,
                        0,
                        isUser ? 8 : 60,
                        4,
                      ),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? kSecondaryColor : kFillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser && data['sentBy'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                data['sentBy'],
                                style: TextStyle(
                                  color: kSecondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (data['type'] == 'image' && data['mediaUrl'] != null)
                            Image.network(
                              data['mediaUrl'],
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return CircularProgressIndicator();
                              },
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                            ),
                          if (data['type'] == 'video' && data['mediaUrl'] != null)
                            Text(
                              '[Video] Tap to view',
                              style: TextStyle(
                                color: isUser ? kFillColor : kTertiaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (data['message']?.isNotEmpty ?? false)
                            Text(
                              data['message'],
                              style: TextStyle(
                                color: isUser ? kFillColor : kTertiaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (data['reactions'] != null)
                            Wrap(
                              spacing: 4,
                              children: (data['reactions'] as Map<String, dynamic>)
                                  .entries
                                  .map((entry) => GestureDetector(
                                onTap: () => _chatServices.removeReaction(
                                  widget.projectId,
                                  message.id,
                                  entry.key,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kFillColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${entry.key} ${(entry.value as List<dynamic>).length}'),
                                ),
                              ))
                                  .toList(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: isUser ? 60.0 : 8.0,
                      right: isUser ? 8.0 : 60.0,
                      bottom: 12.0,
                      top: 2.0,
                    ),
                    child: Row(
                      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!isUser)
                          CommonImageView(
                            height: 20,
                            width: 20,
                            radius: 100,
                            url: data['photoUrl'] ?? dummyImg,
                            fit: BoxFit.cover,
                          ),
                        if (!isUser) SizedBox(width: 4),
                        Text(
                          _formatTime(data['sentAt']),
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
                          color: (data['status'] == 'read' &&
                              (data['readBy'] as List<dynamic>).length == widget.collaboratorIds.length + 1)
                              ? kSecondaryColor
                              : kQuaternaryColor,
                        ),
                        if (isUser) SizedBox(width: 4),
                        if (isUser)
                          CommonImageView(
                            height: 20,
                            width: 20,
                            radius: 100,
                            url: _user?.photoURL ?? dummyImg,
                            fit: BoxFit.cover,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          controller: _scrollController,
          shrinkWrap: true,
          reverse: true,
          physics: BouncingScrollPhysics(),
          padding: AppSizes.DEFAULT,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _chatServices.getTypingStatus(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox.shrink();
                final typers = snapshot.data!.docs
                    .where((doc) => doc['isTyping'] == true && doc.id != _user?.uid)
                    .map((doc) => doc['userName'])
                    .toList();
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    typers.isNotEmpty ? '${typers.join(', ')} ${typers.length > 1 ? 'are' : 'is'} typing...' : '',
                    style: TextStyle(fontSize: 12, color: kQuaternaryColor),
                  ),
                );
              },
            ),
            ...chatWidgets,
          ],
        );
      },
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    if (_groupChatExists) {
      _chatServices.setTypingStatus(widget.projectId, false);
    }
    super.dispose();
  }
}