import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';
import 'package:wasteapptest/Services/notification_service.dart'; 
import 'package:wasteapptest/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await getLoginStatus();

  await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(
    NotificationService.firebaseMessagingBackgroundHandler,
  );
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> getLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'WasteApp',
      home: isLoggedIn ? const DashboardScreen() : const SplashScreen(),
    );
  }
}