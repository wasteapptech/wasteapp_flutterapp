import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:wasteapptest/Presentasion_page/page/nav_section/news_page.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String _apiBaseUrl = 'https://api-wasteapp.vercel.app/api';
  static const String _fcmTokenKey = 'registeredFcmToken';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await NotificationService()._handleBackgroundMessage(message);
  }

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _requestNotificationPermissions();

      String? token = await _firebaseMessaging.getToken();
      print('Initial FCM Token: $token');

      await _configureLocalNotifications();
      _setupFirebaseMessaging();
      await _handleInitialNotification();

      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotification);
    } catch (e) {
      print('Error initializing Firebase: $e');
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        announcement: true,
        carPlay: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
    } catch (e) {
      print('Error requesting permissions: $e');
      throw Exception('Failed to request permissions: $e');
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

    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NewsPage()),
      );
    }
  }

  Future<bool> registerDeviceToken() async {
    try {
      if (!Firebase.apps.isNotEmpty) {
        await Firebase.initializeApp();
      }

      String? token = await _firebaseMessaging.getToken();
      print('FCM Token: $token');

      if (token == null) {
        throw Exception('Failed to get FCM token');
      }

      final prefs = await SharedPreferences.getInstance();
      final registeredToken = prefs.getString(_fcmTokenKey);

      if (registeredToken != token) {
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
          return true;
        } else {
          throw Exception('Failed to register token: ${response.statusCode}');
        }
      }

      return true;
    } catch (e) {
      print('Error in registerDeviceToken: $e');
      throw Exception('Failed to register device token: $e');
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'wasteapp_channel',
      'WasteApp Updates',
      channelDescription: 'Channel for WasteApp notifications',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      vibrationPattern: Int64List.fromList([1000, 1000, 1000, 1000]),
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
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

  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> cleanupToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final oldToken = prefs.getString(_fcmTokenKey);

      if (oldToken != null) {
        final response = await http
            .post(
              Uri.parse('$_apiBaseUrl/notification/cleanup'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode({
                'tokens': [oldToken]
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          await prefs.remove(_fcmTokenKey);
          await _firebaseMessaging.deleteToken();
          print('Token cleaned up successfully');
        }
      }
    } catch (e) {
      print('Error cleaning up token: $e');
    }
  }

  Future<void> unsubscribeFromAll() async {
    await cleanupToken();
  }
}
