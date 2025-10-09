import 'package:flutter/material.dart';
import 'package:docu_site/constants/app_images.dart';
import 'package:docu_site/constants/app_sizes.dart';
import 'package:docu_site/view/widget/custom_app_bar.dart';
import 'package:docu_site/view/widget/my_button_widget.dart';
import 'package:docu_site/view/widget/my_text_field_widget.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePassword extends StatefulWidget {
  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  Future<void> _updatePassword() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(cred);

      if (_newPasswordController.text.trim() !=
          _confirmPasswordController.text.trim()) {
        throw Exception("New passwords do not match");
      }

      await user.updatePassword(_newPasswordController.text.trim());

      Get.back();
      Get.snackbar("Success", "Password updated successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar(title: 'Change Password'),
      body: ListView(
        padding: AppSizes.DEFAULT,
        physics: const BouncingScrollPhysics(),
        children: [
          MyTextField(
            labelText: 'Current Password',
            hintText: '********',
            isObSecure: !_showCurrent,
            controller: _currentPasswordController,
            suffix: GestureDetector(
              onTap: () {
                setState(() => _showCurrent = !_showCurrent);
              },
              child: Icon(
                _showCurrent ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
          ),
          MyTextField(
            labelText: 'Create New Password',
            hintText: '********',
            isObSecure: !_showNew,
            controller: _newPasswordController,
            suffix: GestureDetector(
              onTap: () {
                setState(() => _showNew = !_showNew);
              },
              child: Icon(
                _showNew ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
          ),
          MyTextField(
            labelText: 'Confirm New Password',
            hintText: '********',
            isObSecure: !_showConfirm,
            controller: _confirmPasswordController,
            suffix: GestureDetector(
              onTap: () {
                setState(() => _showConfirm = !_showConfirm);
              },
              child: Icon(
                _showConfirm ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppSizes.DEFAULT,
        child: MyButton(
          buttonText: _isLoading ? 'Updating...' : 'Update',
          onTap: _isLoading ? null : _updatePassword,
        ),
      ),
    );
  }
}
