import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Utils {
  /// Displays a customizable snackbar notification using GetX.
  /// Used for showing success, warning, or error messages.
  static void snackBar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black54,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      isDismissible: true,
      duration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
