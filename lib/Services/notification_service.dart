import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await NotificationService()._handleBackgroundMessage(message);
  }

  Future<void> initialize() async {
    // Set background handler first
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    await _requestNotificationPermissions();
    await _configureLocalNotifications();
    _setupFirebaseMessaging();
    await _registerDeviceToken();
    
    // Handle any initial notification when app is opened from terminated state
    await _handleInitialNotification();
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined or has not accepted notification permission');
      }
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
        // Handle notification tap here
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  void _setupFirebaseMessaging() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(
          message.notification?.title ?? 'WasteApp Update',
          message.notification?.body ?? 'New content available',
          payload: json.encode(message.data),
        );
      }
    });

    // When app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background via notification');
      _handleNotification(message);
    });
  }

  Future<void> _handleInitialNotification() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification');
      _handleNotification(initialMessage);
    }
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    
    // Initialize plugins in background isolate
    WidgetsFlutterBinding.ensureInitialized();
    await _configureLocalNotifications();

    if (message.notification != null) {
      _showLocalNotification(
        message.notification?.title ?? 'WasteApp Update',
        message.notification?.body ?? 'New content available',
        payload: json.encode(message.data),
      );
    }
  }

  void _handleNotification(RemoteMessage message) {
    // Handle navigation or other actions based on message data
    print('Notification data: ${message.data}');
    
    // Example: You might want to navigate to specific screen based on data
    // Navigator.of(context).pushNamed('/some-route');
  }

  Future<void> _registerDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        final registeredToken = prefs.getString(_fcmTokenKey);

        if (registeredToken != token) {
          print('Registering new token with server...');
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/notification/register-token'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'token': token}),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            await prefs.setString(_fcmTokenKey, token);
            print('Successfully registered FCM token with server');
          } else {
            throw Exception(
                'Failed with status ${response.statusCode}: ${response.body}');
          }
        } else {
          print('Token already registered');
        }
      }
    } catch (e) {
      print('Error registering device token: $e');
      // Consider retry logic here
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'wasteapp_channel',
      'WasteApp Updates',
      channelDescription: 'Channel for WasteApp notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      platformDetails,
      payload: payload,
    );
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

  // Additional utility methods
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> unsubscribeFromAll() async {
    await _firebaseMessaging.deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fcmTokenKey);
  }
}