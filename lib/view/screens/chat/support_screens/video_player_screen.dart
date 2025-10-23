// lib/view/screens/chat/support_screens/video_player_screen.dart
import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  String? _localPath;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initNetworkThenFile();
  }

  Future<void> _initNetworkThenFile() async {
    try {
      // 1) Try streaming first
      final c1 = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c1.initialize();
      _controller = c1;
    } catch (e) {
      // 2) Fallback: download to temp file and play from file
      try {
        final dir = await getTemporaryDirectory();
        final out = File('${dir.path}/vid_${DateTime.now().millisecondsSinceEpoch}.mp4');
        final dio = Dio();
        // Firebase Storage URLs: ensure direct media (add alt=media if needed)
        final uri = widget.url.contains('alt=media') ? widget.url : '${widget.url}${widget.url.contains('?') ? '&' : '?'}alt=media';
        await dio.download(uri, out.path);
        _localPath = out.path;

        final c2 = VideoPlayerController.file(out);
        await c2.initialize();
        _controller = c2;
      } catch (e2) {
        _error = 'Cannot play this video on this device.';
      }
    }

    if (_controller != null) {
      _chewie = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        allowFullScreen: true,
        looping: false,
        // helpful on some devices with rotation metadata
        showControlsOnInitialize: true,
      );
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chewie?.dispose();
    _controller?.dispose();
    // optionally delete temp file
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.white))
            : (_chewie != null && (_controller?.value.isInitialized ?? false))
            ? Chewie(controller: _chewie!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}
