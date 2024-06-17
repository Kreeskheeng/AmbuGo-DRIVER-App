import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotification {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission for iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('User granted provisional permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get the token each time the application loads
    String? token = await _fcm.getToken();
    if (token != null) {
      // Send the token to your backend
      await sendTokenToBackend(token);
    }

    // Handle token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      sendTokenToBackend(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });

    // Handle messages when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationData(message.data);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> sendTokenToBackend(String token) async {
    // Replace with your backend endpoint
    final url = 'https://your-backend.example.com/register-token';
    await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );
  }

  void _handleNotificationData(Map<String, dynamic> data) async {
    // Handle your notification data here
    print("Notification data: $data");
    // Example: Parse the data and take appropriate actions based on the notification content
    if (data.containsKey('title') && data.containsKey('body')) {
      String title = data['title'];
      String body = data['body'];
      // Example: Show notification to user or navigate to a specific screen based on the notification
      print('Received notification - Title: $title, Body: $body');
    }
  }

  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    // Handle background messages
    print("Background message: ${message.data}");
    _handleNotificationData(message.data);
  }
}
