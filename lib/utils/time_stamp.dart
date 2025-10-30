
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';


class TimestampUtils {
  static Future<String> addTimestampToImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (!imageFile.existsSync()) return imagePath;

      // Read the image
      final originalImage = img.decodeImage(await imageFile.readAsBytes());
      if (originalImage == null) return imagePath;

      // Create a copy to draw on
      final imageWithTimestamp = img.copyResize(originalImage, width: originalImage.width);

      // Get current date and time
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final timestamp = dateFormat.format(now);

      // Calculate font size based on image width (2-3% of image width)
      final baseFontSize = (imageWithTimestamp.width * 0.025).round();
      final fontSize = baseFontSize.clamp(24, 72); // Min 24px, max 72px

      // Choose font based on calculated size
      final font = _getFontForSize(fontSize);

      // Calculate text position with proper padding
      final textWidth = _estimateTextWidth(timestamp, fontSize);
      final x = imageWithTimestamp.width - textWidth - 20;
      final y = 20;

      // Draw timestamp with background for better visibility
      _drawTextWithBackground(
        imageWithTimestamp,
        timestamp,
        x: x,
        y: y,
        fontSize: fontSize,
      );

      // Create a new file path
      final String timestampedPath = '${imagePath}_timestamped.jpg';
      final File timestampedFile = File(timestampedPath);

      // Save the new image
      await timestampedFile.writeAsBytes(img.encodeJpg(imageWithTimestamp));

      return timestampedPath;
    } catch (e) {
      debugPrint('Error adding timestamp to image: $e');
      return imagePath;
    }
  }

  static img.BitmapFont _getFontForSize(int size) {
    // Use the largest available font that's close to our desired size
    if (size >= 48) return img.arial48;
    if (size >= 24) return img.arial24;
    return img.arial14;
  }

  static int _estimateTextWidth(String text, int fontSize) {
    // Rough estimation: each character takes about 0.6 * fontSize pixels
    return (text.length * fontSize * 0.6).round();
  }

  static void _drawTextWithBackground(
      img.Image image,
      String text, {
        required int x,
        required int y,
        required int fontSize,
      }) {
    final font = _getFontForSize(fontSize);
    final textWidth = _estimateTextWidth(text, fontSize);
    final textHeight = fontSize;

    // Draw semi-transparent background
    img.drawRect(
      image,
      x1: x - 10,
      y1: y - 5,
      x2: textWidth + 20,
      y2: textHeight + 10,
      color: img.ColorRgba8(0, 0, 0, 150), // Semi-transparent black
    );

    // Draw the text
    img.drawString(
      image,
      text,
      font: font,
      x: x,
      y: y,
      color: img.ColorRgb8(255, 255, 255), // White text
    );
  }
}