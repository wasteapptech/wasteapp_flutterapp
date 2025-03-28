import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteapptest/Dasboard_Page/dashboard.dart'; 
import 'package:wasteapptest/Splash_screen/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bool isLoggedIn = await getLoginStatus();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

Future<bool> getLoginStatus() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('isLoggedIn') ?? false;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteApp',
      home: isLoggedIn ? const DashboardScreen() : const SplashScreen(),
    );
  }
}