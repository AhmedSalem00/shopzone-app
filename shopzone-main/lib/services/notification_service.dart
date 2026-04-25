// Push Notification Service
// Requires: firebase_messaging and flutter_local_notifications packages
// Add to pubspec.yaml:
//   firebase_messaging: ^14.7.0
//   flutter_local_notifications: ^17.0.0
//
// Setup:
// 1. Create a Firebase project at console.firebase.google.com
// 2. Add your Android/iOS app
// 3. Download google-services.json → android/app/
// 4. Download GoogleService-Info.plist → ios/Runner/
// 5. Follow Firebase Flutter setup: https://firebase.flutter.dev

import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  // final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> init() async {
    // ── 1. Request permission ──
    // final settings = await _fcm.requestPermission(
    //   alert: true, badge: true, sound: true,
    // );
    // if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

    // ── 2. Get token & register with backend ──
    // final token = await _fcm.getToken();
    // if (token != null) {
    //   await ApiService.registerDeviceToken(token);
    // }

    // ── 3. Listen for token refresh ──
    // _fcm.onTokenRefresh.listen((newToken) {
    //   ApiService.registerDeviceToken(newToken);
    // });

    // ── 4. Initialize local notifications ──
    // const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const iosSettings = DarwinInitializationSettings();
    // await _localNotifications.initialize(
    //   const InitializationSettings(android: androidSettings, iOS: iosSettings),
    //   onDidReceiveNotificationResponse: _onNotificationTap,
    // );

    // ── 5. Handle foreground messages ──
    // FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // ── 6. Handle background/terminated messages ──
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    // final initialMessage = await _fcm.getInitialMessage();
    // if (initialMessage != null) _handleNotificationTap(initialMessage);
  }

// void _handleForegroundMessage(RemoteMessage message) {
//   final notification = message.notification;
//   if (notification == null) return;
//
//   _localNotifications.show(
//     notification.hashCode,
//     notification.title,
//     notification.body,
//     const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'shopzone_orders', 'Order Updates',
//         channelDescription: 'Notifications for order status updates',
//         importance: Importance.high,
//         priority: Priority.high,
//         icon: '@mipmap/ic_launcher',
//       ),
//       iOS: DarwinNotificationDetails(),
//     ),
//     payload: jsonEncode(message.data),
//   );
// }

// void _handleNotificationTap(RemoteMessage message) {
//   final orderId = message.data['order_id'];
//   if (orderId != null) {
//     // Navigate to order tracking screen
//     // Use a global navigator key or event bus
//   }
// }

// void _onNotificationTap(NotificationResponse response) {
//   if (response.payload != null) {
//     final data = jsonDecode(response.payload!);
//     final orderId = data['order_id'];
//     // Navigate to order tracking
//   }
// }
}

// ── Background message handler (must be top-level function) ──
// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // Handle background messages
//   print('Background message: ${message.messageId}');
// }