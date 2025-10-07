import 'package:docu_site/services/project_services/firestore_project_services.dart';
import 'package:docu_site/view/screens/profile/profile.dart';
import 'package:docu_site/view_model/edit_profile/edit_profile_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:docu_site/config/routes/routes.dart';
import 'package:get/get.dart';
import 'config/routes/route_names.dart';
import 'config/theme/light_theme.dart';
import 'firebase_options.dart';

void main()async {

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
