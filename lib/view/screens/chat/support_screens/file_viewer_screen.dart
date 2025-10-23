import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // PDF
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../constants/app_colors.dart';
import '../../../../constants/app_fonts.dart';         // WebView

class FileViewerScreen extends StatelessWidget {
  final String url;
  final String fileName;
  final String ext; // extension without dot, e.g. "pdf","docx","jpg","png","mp4"

  const FileViewerScreen({
    super.key,
    required this.url,
    required this.fileName,
    required this.ext,
  });

  bool get _isPdf    => ext == 'pdf';
  bool get _isImage  => const ['jpg','jpeg','png','gif','bmp','webp','svg'].contains(ext);
  bool get _isVideo  => const ['mp4','mov','m4v','webm'].contains(ext);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          fileName,
          style:  TextStyle(
            fontFamily: AppFonts.SFProDisplay,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isPdf) return _PdfView(url: url);
    if (_isImage) return _ImageView(url: url);
    if (_isVideo) return _VideoView(url: url);

    // Office docs or “other” → in-app WebView (Google Docs Viewer wrapper)
    final googleDocsUrl = 'https://docs.google.com/gview?embedded=1&url=$url';
    return _WebDocView(url: googleDocsUrl);
  }
}

/// PDF (network)
class _PdfView extends StatelessWidget {
  final String url;
  const _PdfView({required this.url});

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.network(
      url,
      canShowScrollHead: true,
      canShowPaginationDialog: true,
    );
  }
}

/// Image (network) with pinch to zoom
class _ImageView extends StatelessWidget {
  final String url;
  const _ImageView({required this.url});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: Center(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (c, child, p) {
            if (p == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}

/// Video (network)
class _VideoView extends StatefulWidget {
  final String url;
  const _VideoView({required this.url});

  @override
  State<_VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<_VideoView> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() => _ready = true);
        _controller.play();
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio == 0
            ? 16 / 9
            : _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.small(
                backgroundColor: Colors.black54,
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// WebView (for Office docs or “others”)
class _WebDocView extends StatelessWidget {
  final String url;
  const _WebDocView({required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..loadRequest(Uri.parse(url));

    return WebViewWidget(controller: controller);
  }
}
