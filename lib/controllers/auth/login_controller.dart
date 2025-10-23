import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../utils/Utils.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Reactive states
  RxBool loading = false.obs;
  RxBool rememberMe = false.obs;
  RxBool isAppleSignInAvailable = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    // Firebase Auth automatically persists the authentication state
    // No need to manually set persistence as LOCAL is the default

    if (GetPlatform.isIOS) {
      _checkAppleSignInAvailability();
    }
    _loadRememberMePreference();
    autoFillCredentials(); // Auto-fill credentials on init
    super.onInit();
  }

  void _checkAppleSignInAvailability() async {
    isAppleSignInAvailable.value = await SignInWithApple.isAvailable();
  }

  /// Load the remember me preference for auto-fill only
  Future<void> _loadRememberMePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remembered = prefs.getBool('rememberMe') ?? false;
      rememberMe.value = remembered;

      print('Loaded Remember Me preference: $remembered');
    } catch (e) {
      print('Error loading remember me preference: $e');
    }
  }

  /// Auto-fill credentials when returning to login screen
  /// This is for convenience, not for automatic login
  Future<void> autoFillCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMeEnabled = prefs.getBool('rememberMe') ?? false;

      if (rememberMeEnabled) {
        final savedEmail = prefs.getString('savedEmail') ?? '';
        final savedPassword = prefs.getString('savedPassword') ?? '';

        if (savedEmail.isNotEmpty) {
          emailController.text = savedEmail;
          passwordController.text = savedPassword;
          rememberMe.value = true;
          print('Auto-filled credentials for: $savedEmail');
        } else {
          print('No saved credentials found');
        }
      } else {
        print('Remember Me is disabled, skipping auto-fill');
      }
    } catch (e) {
      print('Error auto-filling credentials: $e');
    }
  }

  /// Save remember me preference for auto-fill
  Future<void> _saveRememberMePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', value);
      print('Saved Remember Me preference: $value');
    } catch (e) {
      print('Error saving remember me preference: $e');
    }
  }

  /// Save credentials for auto-fill (only if remember me is enabled)
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (rememberMe.value) {
        await prefs.setString('savedEmail', emailController.text.trim());
        await prefs.setString('savedPassword', passwordController.text.trim());
        print('Credentials saved for auto-fill: ${emailController.text.trim()}');
      } else {
        // Clear credentials if remember me is disabled
        await prefs.remove('savedEmail');
        await prefs.remove('savedPassword');
        print('Credentials cleared - Remember Me disabled');
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  /// Helper to ensure user data exists in Firestore upon successful sign-in
  Future<void> _ensureUserData(User user, {String? name}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final displayName = name ?? user.displayName ?? user.email?.split('@')[0] ?? 'User';
      await docRef.set({
        'uid': user.uid,
        'displayName': displayName,
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // --- Regular Email/Password Sign-In ---
  Future<void> login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Utils.snackBar('Input Required', "Please enter both email and password.");
      return;
    }

    loading.value = true;

    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user != null) {
        // Save remember me preference for auto-fill convenience
        await _saveRememberMePreference(rememberMe.value);

        // Save credentials for auto-fill if remember me is enabled
        await _saveCredentials();

        print('Login successful - Firebase Auth will handle persistence');
        print('Remember Me for auto-fill: ${rememberMe.value}');

        // User logged in successfully, proceed to home page
        // Firebase Auth automatically persists this session
        Get.offAllNamed(RouteName.homePage);
      }
      loading.value = false;
    } on FirebaseAuthException catch (e) {
      loading.value = false;
      String message = "Login failed. Please check your credentials.";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided for that user.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address format.";
      } else if (e.code == 'user-disabled') {
        message = "This user account has been disabled.";
      }
      Utils.snackBar('Login Error', message);
    } catch (e) {
      loading.value = false;
      Utils.snackBar('An unexpected error occurred', e.toString());
    }
  }

  // --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    loading.value = true;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        loading.value = false;
        return; // User cancelled the sign-in
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // For social logins, we don't save email/password but we can save the preference
        await _saveRememberMePreference(rememberMe.value);

        // Ensure data exists in Firestore for the new/existing social user
        await _ensureUserData(userCredential.user!, name: googleUser.displayName);

        print('Google login successful - Firebase Auth persistence active');
        Get.offAllNamed(RouteName.homePage);
      }
      loading.value = false;
    } on FirebaseAuthException catch (e) {
      loading.value = false;
      Utils.snackBar('Google Sign-In Error', e.message.toString());
    } catch (e) {
      loading.value = false;
      Utils.snackBar('An unexpected error occurred', e.toString());
    }
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
    print('Remember Me toggled to: ${rememberMe.value}');
  }

  // Logout method (for completeness)
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      // Clear auto-fill credentials on logout
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);
      await prefs.remove('savedEmail');
      await prefs.remove('savedPassword');
      print('Logged out and cleared auto-fill credentials');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}