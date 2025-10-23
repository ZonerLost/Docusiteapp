import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:docu_site/constants/app_colors.dart';
import 'package:docu_site/constants/app_fonts.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/utils/utils.dart';
import 'package:docu_site/view/screens/chat/support_screens/file_viewer_screen.dart';
import 'package:docu_site/view/screens/chat/support_screens/image_viewer_screen.dart';
import 'package:docu_site/view/screens/chat/support_screens/video_player_screen.dart';
import 'package:docu_site/view/widget/common_image_view_widget.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_emoji/flutter_emoji.dart';
import 'package:get/Get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import '../../../main.dart';
import '../../../services/chat_services/firestor_chat_services.dart';

class ChatScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<String> collaboratorIds;
  final List<String> collaboratorEmails;
  final Map<String, String> collaboratorNames;

  const ChatScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.collaboratorIds,
    required this.collaboratorEmails,
    required this.collaboratorNames,
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
  List<String> _typingUsers = [];
  List<Map<String, dynamic>> _pendingAttachments = [];

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
        _groupChatExists = false;
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
        widget.collaboratorNames,
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
    if (text.isEmpty && _pendingAttachments.isEmpty) return;

    // Stop typing when sending message
    if (_isTyping) {
      _chatServices.setTypingStatus(widget.projectId, false);
      _isTyping = false;
    }

    try {
      // If we have pending attachments, send them first
      if (_pendingAttachments.isNotEmpty) {
        await _sendPendingAttachments(text);
      } else {
        // Send regular text message
        await _chatServices.sendMessage(
          widget.projectId,
          text,
          replyTo: _replyingTo,
        );
      }

      _controller.clear();
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } catch (e) {
      Utils.snackBar('Error', 'Failed to send message: $e');
    }
  }

  Future<void> _sendPendingAttachments(String text) async {
    final List<Map<String, dynamic>> attachments = [];

    for (final attachment in _pendingAttachments) {
      if (attachment['url'] != null) {
        attachments.add({
          'name': attachment['name'],
          'url': attachment['url'],
          'size': attachment['size'],
          'type': attachment['extension'],
        });
      }
    }

    if (attachments.isNotEmpty) {
      await _chatServices.sendMessage(
        widget.projectId,
        text.isNotEmpty ? text : 'Sent ${attachments.length} file(s)',
        messageType: attachments.length == 1 ? 'file' : 'files',
        attachments: attachments,
        replyTo: _replyingTo,
      );

      // Clear pending attachments after sending
      setState(() {
        _pendingAttachments.clear();
      });
    }
  }

  void _scrollToBottom() {
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

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- CAMERA OPTION ---
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.blueAccent),
              title: const Text('Camera (Photo / Video)'),
              onTap: () async {
                Navigator.pop(ctx);

                // nested bottom sheet
                final type = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx2) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () => Navigator.pop(ctx2, 'photo'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.videocam),
                          title: const Text('Record Video'),
                          onTap: () => Navigator.pop(ctx2, 'video'),
                        ),
                      ],
                    ),
                  ),
                );

                if (type == 'photo' || type == 'video') {
                  final isVideo = type == 'video';
                  final downloadUrl = await _chatServices.pickAndUploadMedia(
                    widget.projectId,
                    source: ImageSource.camera,
                    isVideo: isVideo,
                  );

                  if (downloadUrl != null) {
                    await _chatServices.sendMessage(
                      widget.projectId,
                      '',
                      messageType: isVideo ? 'video' : 'image',
                      mediaUrl: downloadUrl,
                      replyTo: _replyingTo,
                    );
                    setState(() => _replyingTo = null);
                    _scrollToBottom();
                  }
                }
              },
            ),

            // --- GALLERY OPTION ---
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery (Photo / Video)'),
              onTap: () async {
                Navigator.pop(ctx);

                final type = await showModalBottomSheet<String>(
                  context: context,
                  builder: (ctx2) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo),
                          title: const Text('Pick Photo'),
                          onTap: () => Navigator.pop(ctx2, 'photo'),
                        ),
                        ListTile(
                          leading: const Icon(Icons.videocam),
                          title: const Text('Pick Video'),
                          onTap: () => Navigator.pop(ctx2, 'video'),
                        ),
                      ],
                    ),
                  ),
                );

                if (type == 'photo' || type == 'video') {
                  final isVideo = type == 'video';
                  final downloadUrl = await _chatServices.pickAndUploadMedia(
                    widget.projectId,
                    source: ImageSource.gallery,
                    isVideo: isVideo,
                  );

                  if (downloadUrl != null) {
                    await _chatServices.sendMessage(
                      widget.projectId,
                      '',
                      messageType: isVideo ? 'video' : 'image',
                      mediaUrl: downloadUrl,
                      replyTo: _replyingTo,
                    );
                    setState(() => _replyingTo = null);
                    _scrollToBottom();
                  }
                }
              },
            ),

            // --- FILES OPTION ---
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.deepPurple),
              title: const Text('Attach Files'),
              onTap: () async {
                Navigator.pop(ctx);
                await _pickAndSendFiles();
              },
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _pickAndSendFiles() async {
    try {
      final files = await _chatServices.pickFiles();
      if (files == null || files.isEmpty) return;

      // Show uploading indicator
      setState(() {
        _pendingAttachments = files.map((file) => {
          'name': file.name,
          'size': file.size,
          'extension': file.extension ?? 'file',
          'uploading': true,
          'url': null,
        }).toList();
      });

      // Upload files one by one
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final downloadUrl = await _chatServices.uploadFileAttachment(widget.projectId, file);

        if (downloadUrl != null) {
          setState(() {
            _pendingAttachments[i] = {
              'name': file.name,
              'size': file.size,
              'extension': file.extension ?? 'file',
              'uploading': false,
              'url': downloadUrl,
            };
          });
        } else {
          setState(() {
            _pendingAttachments[i] = {
              'name': file.name,
              'size': file.size,
              'extension': file.extension ?? 'file',
              'uploading': false,
              'url': null,
              'error': true,
            };
          });
        }
      }

      // Auto-send if all uploads are complete
      final allUploaded = _pendingAttachments.every((att) => att['url'] != null);
      if (allUploaded) {
        await _sendPendingAttachments(_controller.text.trim());
        _controller.clear();
        _scrollToBottom();
      }

    } catch (e) {
      setState(() {
        _pendingAttachments.clear();
      });
      Utils.snackBar('Error', 'Failed to send files: ${e.toString()}');
    }
  }

  void _removePendingAttachment(int index) {
    setState(() {
      _pendingAttachments.removeAt(index);
    });
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
                'sender': data['userName'] ?? data['sentBy'],
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

  String _getUserName(String userId) {
    return widget.collaboratorNames[userId] ??
        _user?.displayName ??
        _user?.email?.split('@')[0] ??
        'Unknown User';
  }

  void _handleTextChange(String value) {
    if (value.isNotEmpty && !_isTyping) {
      _chatServices.setTypingStatus(widget.projectId, true);
      _isTyping = true;

      Future.delayed(Duration(seconds: 2), () {
        if (_isTyping && _controller.text.isEmpty) {
          _chatServices.setTypingStatus(widget.projectId, false);
          _isTyping = false;
        }
      });
    } else if (value.isEmpty && _isTyping) {
      _chatServices.setTypingStatus(widget.projectId, false);
      _isTyping = false;
    }
  }

  bool _isUserTypingRecently(Timestamp? timestamp) {
    if (timestamp == null) return false;
    final now = DateTime.now();
    final typingTime = timestamp.toDate();
    return now.difference(typingTime).inSeconds < 3;
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return "Today";
    } else if (messageDay == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('EEEE, MMMM d, yyyy').format(date);
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void testFileOpening() async {
    print('=== TESTING FILE OPENING ===');

    // Test 1: Public URL
    final publicUrl = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
    print('Testing public URL: $publicUrl');

    try {
      final uri = Uri.parse(publicUrl);
      bool canLaunch = await canLaunchUrl(uri);
      print('Can launch public URL: $canLaunch');

      if (canLaunch) {
        bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('Public URL launched: $launched');
      }
    } catch (e) {
      print('Public URL error: $e');
    }

    // Test 2: Your Firebase URL (replace with actual URL from your logs)
    final firebaseUrl = 'your-actual-firebase-url-here';
    print('Testing Firebase URL: $firebaseUrl');

    try {
      final uri = Uri.parse(firebaseUrl);
      bool canLaunch = await canLaunchUrl(uri);
      print('Can launch Firebase URL: $canLaunch');

      if (canLaunch) {
        bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('Firebase URL launched: $launched');
      }
    } catch (e) {
      print('Firebase URL error: $e');
    }

    print('=== TEST COMPLETE ===');
  }

  Future<void> _openFile(String url, String fileName) async {
    debugPrint('Attempting to open file: $fileName');
    debugPrint('URL: $url');

    try {
      final Uri uri = Uri.parse(url);

      final canLaunch = await canLaunchUrl(uri);
      debugPrint('Can launch: $canLaunch');

      if (!canLaunch) {
        Utils.snackBar('Error', 'Cannot open file. No compatible app found.');
        return;
      }

      // Use external mode on Android, webview for iOS/macOS
      final mode = Theme.of(context).platform == TargetPlatform.android
          ? LaunchMode.externalApplication
          : LaunchMode.inAppWebView;

      final launched = await launchUrl(uri, mode: mode);
      debugPrint('Launch result: $launched');

      if (!launched) {
        Utils.snackBar('Error', 'Could not open file externally.');
      }
    } catch (e, stack) {
      debugPrint('=== ERROR OPENING FILE ===');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('=== END ERROR ===');
      Utils.snackBar('Error', 'Failed to open file.');
    }
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
        appBar: simpleAppBar(title: widget.projectName),
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.projectName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _chatServices.getTypingStatus(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox.shrink();

                final List<String> typers = snapshot.data!.docs
                    .where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isTyping'] == true &&
                      doc.id != _user?.uid &&
                      _isUserTypingRecently(data['timestamp']);
                })
                    .map<String>((doc) => doc['userName'] ?? _getUserName(doc.id))
                    .toList();

                if (!_listsEqual(typers, _typingUsers)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _typingUsers = typers;
                    });
                  });
                }

                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: typers.isNotEmpty ? 16 : 0,
                  child: Text(
                    typers.isNotEmpty ? '${typers.join(', ')} ${typers.length > 1 ? 'are' : 'is'} typing...' : '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: buildGroupedChatList()),

          // Pending attachments section
          if (_pendingAttachments.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: kFillColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Attachments',
                        style: TextStyle(fontSize: 12, color: kQuaternaryColor, fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          if (_pendingAttachments.any((att) => !att['uploading'] && att['url'] != null)) {
                            _sendPendingAttachments(_controller.text.trim());
                            _controller.clear();
                          }
                        },
                        child: Text(
                          'Send',
                          style: TextStyle(
                            fontSize: 12,
                            color: _pendingAttachments.any((att) => !att['uploading'] && att['url'] != null)
                                ? kSecondaryColor
                                : kQuaternaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  ..._pendingAttachments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final attachment = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 6),
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getFileIcon(attachment['extension']),
                            color: attachment['error'] == true ? Colors.red : kSecondaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attachment['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: kTertiaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  attachment['uploading']
                                      ? 'Uploading...'
                                      : attachment['error'] == true
                                      ? 'Upload failed'
                                      : _formatFileSize(attachment['size']),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: attachment['error'] == true ? Colors.red : kQuaternaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (attachment['uploading'])
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            GestureDetector(
                              onTap: () => _removePendingAttachment(index),
                              child: Icon(Icons.close, size: 16, color: kQuaternaryColor),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

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
                              child: Icon(Icons.add),
                              // child: Image.asset(Assets.imagesCam, height: 20),
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
                      onChanged: _handleTextChange,
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

        final sortedMessages = messages.toList()
          ..sort((a, b) {
            final aTime = (a.data() as Map<String, dynamic>)['sentAt'] as Timestamp?;
            final bTime = (b.data() as Map<String, dynamic>)['sentAt'] as Timestamp?;
            final aDate = aTime?.toDate() ?? DateTime.now();
            final bDate = bTime?.toDate() ?? DateTime.now();
            return aDate.compareTo(bDate);
          });

        for (var message in sortedMessages) {
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
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: kFillColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDateHeader(msgDate),
                      style: TextStyle(
                        color: kQuaternaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
            lastDate = msgDate;
          }

          final userName = data['userName'] ?? _getUserName(data['userId']);
          final replyToUserName = data['replyTo'] != null
              ? _getUserName(data['replyTo']['userId'] ?? '')
              : data['replyTo']?['sender'] ?? '';

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
                        'Replying to $replyToUserName: ${data['replyTo']['message']}',
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
                          if (!isUser && userName != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                userName,
                                style: TextStyle(
                                  color: kSecondaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),

                          if (data['type'] == 'image' && data['mediaUrl'] != null)
                            GestureDetector(
                              onTap: () {
                                final tag = 'img_${message.id}';
                                Get.to(() => ImageViewerScreen(url: data['mediaUrl'], heroTag: tag));
                              },
                              child: Hero(
                                tag: 'img_${message.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    data['mediaUrl'],
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    // (keep your loading/error builders if you like)
                                  ),
                                ),
                              ),
                            ),


                          if (data['type'] == 'video' && data['mediaUrl'] != null)
                            GestureDetector(
                              onTap: () => Get.to(() => VideoPlayerScreen(url: data['mediaUrl'])),
                              child: Container(
                                width: 200,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: kGreyColor2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.play_circle_filled, size: 40, color: Colors.black54),
                              ),
                            ),


                          // In the attachments section of buildGroupedChatList:
                          if (data['attachments'] != null && (data['attachments'] as List).isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: (data['attachments'] as List<dynamic>).map((attachment) {
                                final att = attachment as Map<String, dynamic>;
                                return GestureDetector(

                                  onTap: () {
                                    final url = att['url'] as String;
                                    final name = att['name'] as String? ?? 'file';
                                    final ext  = (att['type'] as String? ?? '').toLowerCase();

                                    final isImage = ['jpg','jpeg','png','gif','webp','bmp','heic','heif'].contains(ext);
                                    final isVideo = ['mp4','mov','m4v','avi','webm','3gp','mkv'].contains(ext);
                                    final isPdf   = ext == 'pdf';

                                    if (isImage) {
                                      Get.to(() => ImageViewerScreen(url: url));
                                    } else if (isVideo) {
                                      Get.to(() => VideoPlayerScreen(url: url));
                                    } else if (isPdf) {
                                      Get.to(() => FileViewerScreen(
                                        url: url,
                                        fileName: name,
                                        ext: ext,
                                      ));
                                    } else {
                                      // fallback for other docs
                                      Get.to(() => FileViewerScreen(url: url, fileName: name, ext: ext));
                                    }
                                  },


                                  // onTap: () {
                                  //   print('Attempting to open file:');
                                  //   print(att['url']);
                                  //   // testFileOpening();
                                  //   // _openFile('https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', 'dummy.pdf');
                                  //
                                  //
                                  //   _openFile(att['url'], att['name']);
                                  // },
                                  child: Container(
                                    width: 250,
                                    margin: EdgeInsets.only(bottom: 8),
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: kFillColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: kBorderColor),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: kSecondaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            _getFileIcon(att['type']),
                                            color: kSecondaryColor,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                att['name'],
                                                style: TextStyle(
                                                  color: kTertiaryColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _formatFileSize(att['size']),
                                                style: TextStyle(
                                                  color: kQuaternaryColor,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.open_in_new, color: kSecondaryColor, size: 20),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
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

                          if (data['reactions'] != null && (data['reactions'] as Map).isNotEmpty)
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
          reverse: false,
          physics: BouncingScrollPhysics(),
          padding: AppSizes.DEFAULT,
          children: chatWidgets,
        );
      },
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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