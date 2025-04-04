import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasteapptest/Support_Page/news_page.dart';
import 'package:wasteapptest/main.dart';
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String _apiBaseUrl = 'https://api-wasteapp.vercel.app/api';
  static const String _fcmTokenKey = 'registeredFcmToken';

  // Background message handler (must be static or top-level)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await NotificationService()._handleBackgroundMessage(message);
  }

  Future<void> initialize() async {
    // Set background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestNotificationPermissions();
    await _configureLocalNotifications();
    _setupFirebaseMessaging();
    await _registerDeviceToken();
    await _handleInitialNotification();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permissions: $e');
    }
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (context) => const NewsPage()),
          );
        }
      },
    );
  }

  void _setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      if (message.notification != null) {
        _showLocalNotification(
          message.notification?.title ?? 'WasteApp Update',
          message.notification?.body ?? 'New content available',
          payload: json.encode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background via notification');
      _handleNotification(message);
    });
  }

  Future<void> _handleInitialNotification() async {
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification');
      _handleNotification(initialMessage);
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    await _configureLocalNotifications();

    if (message.notification != null) {
      await _showLocalNotification(
        message.notification?.title ?? 'WasteApp Update',
        message.notification?.body ?? 'New content available',
        payload: json.encode(message.data),
      );
    }
  }

  void _handleNotification(RemoteMessage message) {
    print('Notification data: ${message.data}');

    // Check if the app is in a state where navigation is possible
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => const NewsPage()),
      );
    }
  }

  Future<void> _registerDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final registeredToken = prefs.getString(_fcmTokenKey);

        if (registeredToken != token) {
          print('Registering new token...');
          final response = await http
              .post(
                Uri.parse('$_apiBaseUrl/notification/register-token'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: json.encode({'token': token}),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            await prefs.setString(_fcmTokenKey, token);
            print('Token registered successfully');
          } else {
            throw Exception(
                'Failed: ${response.statusCode} - ${response.body}');
          }
        } else {
          print('Token already registered');
        }
      }
    } catch (e) {
      print('Error registering token: $e');
    }
  }

  Future<void> _showLocalNotification(
  String title,
  String body, {
  String? payload,
}) async {
  Map<String, dynamic> data = {};
  String? imageUrl;
  
  // Parse payload to extract image URL if available
  if (payload != null && payload.isNotEmpty) {
    try {
      data = json.decode(payload);
      // Check for image URL in different possible locations
      imageUrl = data['image_url'] ?? 
                (data['notification'] != null ? data['notification']['image'] : null) ??
                (data['android'] != null && data['android']['notification'] != null ? 
                  data['android']['notification']['imageUrl'] : null);
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }

  AndroidNotificationDetails androidDetails;
  
  if (imageUrl != null && imageUrl.isNotEmpty) {
    // Create a notification with big picture style using URL directly
    final BigPictureStyleInformation bigPictureStyle = BigPictureStyleInformation(
      ByteArrayAndroidBitmap(await _getImageBytesFromUrl(imageUrl)),
      contentTitle: title,
      summaryText: body,
    );
    
    androidDetails = AndroidNotificationDetails(
      'wasteapp_channel',
      'WasteApp Updates',
      channelDescription: 'Channel for WasteApp notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: bigPictureStyle,
    );
  } else {
    // Default notification without image
    androidDetails = const AndroidNotificationDetails(
      'wasteapp_channel',
      'WasteApp Updates',
      channelDescription: 'Channel for WasteApp notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
  }

  DarwinNotificationDetails iosDetails;
  
  if (imageUrl != null && imageUrl.isNotEmpty) {
    // For iOS notification with image (using attachment URL)
    iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: [
        DarwinNotificationAttachment(
          imageUrl,
          identifier: 'image',
        )
      ],
    );
  } else {
    // Default iOS notification
    iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
  }

  final NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );

  await _flutterLocalNotificationsPlugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    platformDetails,
    payload: payload,
  );
}

// Helper function to get image bytes from URL without saving
Future<Uint8List> _getImageBytesFromUrl(String url) async {
  final http.Response response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

  Future<List<Map<String, dynamic>>> fetchNews() async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/news'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
      throw Exception('Failed to load news');
    }
  }

  Future<List<Map<String, dynamic>>> fetchKegiatan() async {
    try {
      final response = await http.get(Uri.parse('$_apiBaseUrl/kegiatan'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load activities');
      }
    } catch (e) {
      print('Error fetching activities: $e');
      throw Exception('Failed to load activities');
    }
  }

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> unsubscribeFromAll() async {
    await _firebaseMessaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }
}
