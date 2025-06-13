import 'package:flutter/material.dart';
import 'Domain_page/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;

  Future<void> _showSuccessDialog({
    String title = 'Berhasil',
    String message = 'Notifikasi berhasil diaktifkan!',
    String buttonText = 'Lanjutkan',
    VoidCallback? onPressed,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => Center(
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/congrats.png',
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
                const SizedBox(height: 40),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: onPressed ?? () => Navigator.of(ctx).pop(),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF2cac69),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _enableNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Initialize notification service
      await _notificationService.initialize();
      print('Notifications initialized successfully');

      // Step 2: Register FCM token to your backend
      bool tokenRegistered = await _notificationService.registerDeviceToken();
      
      if (tokenRegistered) {
        // Show success dialog
        await _showSuccessDialog(
          title: 'Notifikasi Diaktifkan',
          message:
              'Notifikasi berhasil diaktifkan! Anda akan menerima informasi terbaru.',
          buttonText: 'Lanjutkan',
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            widget.onContinue(); // Call the onContinue callback
          },
        );
      } else {
        throw Exception('Gagal mendapatkan FCM token');
      }
    } catch (e) {
      print('Error enabling notifications: $e');
      await _showSuccessDialog(
        title: 'Gagal',
        message: 'Gagal mengaktifkan notifikasi: $e',
        buttonText: 'Coba Lagi',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                  "Dapatkan informasi terbaru tentang lokasi tempat sampah, aktivitas lingkungan, dan events di sekitar Anda.",
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

              // Enable Notifications Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _enableNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2cac69),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Nyalakan Notifikasi',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
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