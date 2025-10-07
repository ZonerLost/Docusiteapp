import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../config/routes/route_names.dart';
import '../../../../utils/Utils.dart';

class LoginViewModel extends GetxController {
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
    if (GetPlatform.isIOS) {
      _checkAppleSignInAvailability();
    }
    super.onInit();
  }

  void _checkAppleSignInAvailability() async {
    isAppleSignInAvailable.value = await SignInWithApple.isAvailable();
  }

  /// Helper to ensure user data exists in Firestore upon successful sign-in,
  /// especially for social logins where the user might not have manually registered.
  Future<void> _ensureUserData(User user, {String? name}) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final displayName = name ?? user.displayName ?? user.email?.split('@')[0] ?? 'User';
      // Create user data if it doesn't exist (e.g., first time social sign-in)
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
        // User logged in successfully, proceed to home page
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
        // Ensure data exists in Firestore for the new/existing social user
        await _ensureUserData(userCredential.user!, name: googleUser.displayName);
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

  // // --- Apple Sign-In ---
  // Future<void> signInWithApple() async {
  //   loading.value = true;
  //   try {
  //     final AuthorizationCredentialAppleID appleResult = await SignInWithApple.getCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //     );
  //
  //     final OAuthCredential credential = OAuthProvider('apple.com').credential(
  //       idToken: appleResult.identityToken,
  //       accessToken: appleResult.authorizationCode,
  //     );
  //
  //     final UserCredential userCredential = await _auth.signInWithCredential(credential);
  //
  //     if (userCredential.user != null) {
  //       final String displayName =
  //       '${appleResult.fullName?.givenName ?? ''} ${appleResult.fullName?.familyName ?? ''}'.trim();
  //
  //       // Ensure data exists in Firestore for the new/existing social user
  //       await _ensureUserData(userCredential.user!, name: displayName);
  //       Get.offAllNamed(RouteName.homePage);
  //     }
  //     loading.value = false;
  //   } on FirebaseAuthException catch (e) {
  //     loading.value = false;
  //     Utils.snackBar('Apple Sign-In Error', e.message.toString());
  //   } catch (e) {
  //     loading.value = false;
  //     Utils.snackBar('An unexpected error occurred with Apple Sign-in', e.toString());
  //   }
  // }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
    // You would typically save this preference (e.g., in SharedPreferences)
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
