import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileController extends GetxController {
  var isLoading = false.obs;
  var imageFile = Rx<File?>(null);
  var networkImageUrl = ''.obs;

  late TextEditingController nameController;
  late TextEditingController emailController;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    loadUserData();
  }

  // Fetch user data from Firestore
  Future<void> loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          // Use 'displayName' for consistency
          nameController.text = data['displayName'] ?? '';
          emailController.text = data['email'] ?? '';
          networkImageUrl.value = data['photoUrl'] ?? '';
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data: $e');
    }
  }

  // Pick an image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(source: source);
    if (pickedFile != null) {
      imageFile.value = File(pickedFile.path);
    }
  }

  // Upload image to Firebase Storage and get the URL
  Future<String?> _uploadImage(File file) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Reference file with user's UID
      final ref = _storage.ref().child('profile_pictures').child('${user.uid}.jpg');

      // Upload the file
      final uploadTask = ref.putFile(file);

      // Await the completion of the upload task
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      Get.snackbar('Error', 'Image upload failed: $e');
      return null;
    }
  }

  // Update profile in Firestore AND Firebase Auth
  Future<void> updateProfile() async {
    isLoading.value = true;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        isLoading.value = false;
        return;
      }

      String? newPhotoUrl;

      // 1. UPLOAD IMAGE if a new one was selected
      if (imageFile.value != null) {
        newPhotoUrl = await _uploadImage(imageFile.value!);
        if (newPhotoUrl == null) {
          // Stop if upload failed
          isLoading.value = false;
          return;
        }
      }

      // 2. PREPARE Firestore update data
      final Map<String, dynamic> dataToUpdate = {
        // Use 'displayName' for consistency
        'displayName': nameController.text.trim(),
        'email': emailController.text.trim(),
        // Only include photoUrl if a new one was uploaded
        if (newPhotoUrl != null) 'photoUrl': newPhotoUrl,
      };

      // 3. UPDATE Firestore document
      await _firestore.collection('users').doc(user.uid).update(dataToUpdate);

      // 4. UPDATE Firebase Authentication profile (crucial for Auth functions)
      if (user.displayName != nameController.text.trim()) {
        await user.updateDisplayName(nameController.text.trim());
      }

      if (newPhotoUrl != null) {
        await user.updatePhotoURL(newPhotoUrl);
        // Update the reactive variable for immediate UI refresh if needed
        networkImageUrl.value = newPhotoUrl;
      }

      // Clear the local file reference after successful update
      imageFile.value = null;


      Get.snackbar('Success', 'Profile updated successfully!');
      Get.back();

    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}