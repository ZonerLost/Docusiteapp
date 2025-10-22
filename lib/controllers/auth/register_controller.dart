import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../config/routes/route_names.dart'; // Assuming this is correct
import '../../utils/Utils.dart';

class RegisterViewModel extends GetxController {

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  RxBool loading = false.obs;
  RxBool agreedToTerms = false.obs;
  RxBool isAppleSignInAvailable = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Directly instantiate FirebaseFirestore
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

  /// Helper to save initial user data to Firestore
  Future<void> _saveUserData(String uid, String displayName, String email) async {
    // We are setting the document ID to the user's UID for easy lookup
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': displayName,
      'email': email,
      'photoUrl': '',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // Use merge: true to avoid overwriting existing data if doc exists
  }

// In RegisterViewModel, update the register method to be more specific about validation
  Future<void> register() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String name = nameController.text.trim();

    // Enhanced field validation
    if (name.isEmpty) {
      Utils.snackBar('Name Required', "Please enter your full name.");
      return;
    }

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Utils.snackBar('Valid Email Required', "Please enter a valid email address.");
      return;
    }

    if (password.isEmpty || password.length < 6) {
      Utils.snackBar('Password Required', "Password must be at least 6 characters long.");
      return;
    }

    // Term agreement check
    if (!agreedToTerms.value) {
      Utils.snackBar('Terms & Conditions', "You must agree to the Terms & Conditions to continue.");
      return;
    }

    loading.value = true;

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user != null) {
        final User user = userCredential.user!;
        await user.updateDisplayName(name);

        // Store initial user data in Firestore directly
        await _saveUserData(user.uid, name, email);

        Get.offAllNamed(RouteName.homePage);
      }
      loading.value = false;
    } on FirebaseAuthException catch (e) {
      loading.value = false;
      String message = "Registration failed. Please try again.";
      if (e.code == 'email-already-in-use') {
        message = "An account with this email already exists.";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak. Please choose a stronger password.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address format.";
      }
      Utils.snackBar('Registration Error', message);
    } catch (e) {
      loading.value = false;
      Utils.snackBar('An unexpected error occurred', e.toString());
    }
  }

  // --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    if (!agreedToTerms.value) {
      Utils.snackBar('Terms & Conditions', "You must agree to the Terms & Conditions.");
      return;
    }

    loading.value = true;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        loading.value = false;
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final User user = userCredential.user!;
        final String displayName = googleUser.displayName ?? user.email?.split('@')[0] ?? 'User';
        final String email = user.email ?? '';

        // Update display name if it's null in Firebase but available from Google
        if (user.displayName == null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);
        }

        // Store initial user data in Firestore directly
        await _saveUserData(user.uid, displayName, email);
        Get.offAllNamed(RouteName.homePage);
      }
      loading.value = false;
    } on FirebaseAuthException catch (e) {
      loading.value = false;
      Utils.snackBar('Error Signing up with Google', e.message.toString());
    } catch (e) {
      loading.value = false;
      Utils.snackBar('An unexpected error occurred', e.toString());
    }
  }

  // --- Apple Sign-In ---
  // Future<void> signInWithApple() async {
  //   if (!agreedToTerms.value) {
  //     Utils.snackBar('Terms & Conditions', "You must agree to the Terms & Conditions.");
  //     return;
  //   }
  //
  //   loading.value = true;
  //   try {
  //     final AuthorizationResult<AuthorizationCredentialAppleID> appleResult = await SignInWithApple.get
  //     AuthorizationCredential(
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
  //       final User user = userCredential.user!;
  //       // Apple provides the name/email only on the *first* sign-in
  //       final String displayName =
  //       '${appleResult.fullName?.givenName ?? ''} ${appleResult.fullName?.familyName ?? ''}'.trim().isNotEmpty
  //           ? '${appleResult.fullName!.givenName ?? ''} ${appleResult.fullName!.familyName ?? ''}'.trim()
  //           : user.displayName ?? 'Apple User';
  //
  //       final String email = user.email ?? '';
  //
  //       // Update display name if provided by Apple
  //       if (user.displayName == null && displayName.isNotEmpty) {
  //         await user.updateDisplayName(displayName);
  //       }
  //
  //       // Store initial user data in Firestore directly
  //       await _saveUserData(user.uid, displayName, email);
  //       Get.offAllNamed(RouteName.homePage);
  //     }
  //     loading.value = false;
  //   } on FirebaseAuthException catch (e) {
  //     loading.value = false;
  //     Utils.snackBar('Error Signing up with Apple', e.message.toString());
  //   } catch (e) {
  //     loading.value = false;
  //     Utils.snackBar('An unexpected error occurred with Apple Sign-in', e.toString());
  //   }
  // }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
