import 'package:docu_site/config/routes/route_names.dart';
import 'package:docu_site/view/screens/auth/forgot_password/forgot_password.dart';
import 'package:docu_site/view/screens/auth/login/login.dart';
import 'package:docu_site/view/screens/auth/register/register.dart';
import 'package:docu_site/view/screens/get_help/help.dart';
import 'package:docu_site/view/screens/home/home.dart';
import 'package:get/get.dart';

import '../../view/screens/launch/splash_screen.dart';

class AppRoutes {
  static final List<GetPage> pages = [
    GetPage(name: RouteName.splashScreen, page: ()=>SplashScreen()),
    GetPage(name: RouteName.loginPage, page: ()=>Login()),
    GetPage(name: RouteName.registerPage, page: ()=>Register()),
    GetPage(name: RouteName.forgotPasswordPage, page: ()=>ForgotPassword()),
    GetPage(name: RouteName.homePage, page: ()=>Home()),
    GetPage(name: RouteName.getHelp, page: ()=>HelpPage()),


  ];
}
