import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final String url;
  final String? heroTag;
  const ImageViewerScreen({super.key, required this.url, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final image = Image.network(url);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (heroTag != null)
            Hero(tag: heroTag!, child: PhotoView(imageProvider: image.image))
          else
            PhotoView(imageProvider: image.image),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
