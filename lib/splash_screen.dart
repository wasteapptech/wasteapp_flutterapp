import 'package:flutter/material.dart';
import 'package:wasteapptest/Presentasion_page/page/auth_section/signin.dart';
import 'package:wasteapptest/Presentasion_page/page/dashboard_section/dashboard.dart';
import 'package:wasteapptest/onboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final bool isLoggedIn = await getLoginStatus();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            isLoggedIn ? const DashboardScreen() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2cac69),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/grass.png', 
              fit: BoxFit.cover,
              height: 190, 
            ),
          ),
          
          // Main content
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'WasteApp',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Smart Waste, Smart Income',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const Positioned(
            bottom: 165, 
            left: 0,
            right: 0,
            child: Column(
              children:  [
                Text(
                  'Copyright © 2025',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Telecommunication Engineering',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'WasteApp - Telkom University',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
