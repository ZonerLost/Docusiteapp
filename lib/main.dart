
import 'package:docu_site/services/project_services/firestore_project_services.dart';
import 'package:docu_site/utils/Utils.dart';
import 'package:docu_site/view/screens/notifications/notifications.dart';
import 'package:docu_site/view_model/edit_profile/edit_profile_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/routes/routes.dart';
import 'config/routes/route_names.dart';
import 'config/theme/light_theme.dart';
import 'firebase_options.dart';

// Background message handler for FCM (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.notification?.title}');
}

// Function to request permission and get the FCM token
Future<void> _initializeFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 1. Request Permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ User granted notification permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('User granted provisional permission'); 
  } else {
    print('❌ User declined or has not accepted permission');
  }

  // 2. Get the FCM token
  final fcmToken = await messaging.getToken();
  print('=======================================');
  print('FCM Token: $fcmToken');
  print('=======================================');
  // NOTE: You must now save this fcmToken to your user's document in Firestore.
  // This is essential for sending targeted notifications from your backend (e.g., Cloud Functions).
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM (Request permissions and get token)
  await _initializeFirebaseMessaging();

  // Set the background messaging handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Handle foreground notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      Utils.snackBar(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? '',
      );
    }
  });

  // Handle notification tap when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['type'] == 'project_invite') {
      Get.to(() => Notifications());
    }
  });

  // Handle notification tap when app is terminated
  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null && initialMessage.data['type'] == 'project_invite') {
    // Delay navigation until GetMaterialApp is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.to(() => Notifications());
    });
  }

  // Initialize GetX controllers
  Get.put(ProjectService());
  Get.put(EditProfileController());

  runApp(MyApp());
}

String dummyImg =
    'https://images.unsplash.com/photo-1558507652-2d9626c4e67a?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=687&q=80';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      title: 'Docu Site',
      theme: lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: RouteName.splashScreen,
      getPages: AppRoutes.pages,
      defaultTransition: Transition.fadeIn,
    );
  }
}