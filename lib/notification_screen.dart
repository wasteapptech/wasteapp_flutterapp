import 'package:flutter/material.dart';
import 'package:wasteapptest/Services/notification_service.dart';

class NotificationPermissionPage extends StatefulWidget {
  final Function() onContinue;
  
  const NotificationPermissionPage({
    super.key, 
    required this.onContinue,
  });

  @override
  State<NotificationPermissionPage> createState() => _NotificationPermissionPageState();
}

class _NotificationPermissionPageState extends State<NotificationPermissionPage> {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Only initialize the service but don't request permissions yet
    if (!_isInitialized) {
      try {
        // Just set up the service without requesting permission
        setState(() {
          _isInitialized = true;
        });
        print('Notification service prepared in NotificationPermissionPage');
      } catch (e) {
        print('Error preparing notification service in NotificationPermissionPage: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Notification Image
              Image.asset(
                'assets/images/notif.png',
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              const SizedBox(height: 40),
              
              // Title
              const Text(
                "Aktifkan Notifikasi",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2cac69),
                  fontFamily: 'Poppins',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Description
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "Dapatkan informasi terbaru tentang lokasi tempat sampah, aktivitas lingkungan, dan events di sekitar Anda",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2cac69),
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Enable Notification Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isInitialized) {
                      // Now initialize and request permission when the user taps the button
                      try {
                        // Initialize will trigger the permission request
                        await _notificationService.initialize();
                        print('Notifications initialized and permission requested');
                        
                        // Get and display the token for debugging
                        String? token = await _notificationService.getFcmToken();
                        print('Current FCM token: $token');
                      } catch (e) {
                        print('Error requesting notification permission: $e');
                      }
                    }
                    widget.onContinue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Aktifkan Sekarang",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Skip Button
              TextButton(
                onPressed: widget.onContinue,
                child: const Text(
                  "Nanti Saja",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}