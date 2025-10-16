import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Service to handle push notifications
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase and request notification permissions
  Future<void> initialize() async {
    try {
      // Request permission (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('📬 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();
        debugPrint('📱 FCM Token: $_fcmToken');

        // Listen for token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('📱 FCM Token refreshed: $newToken');
        });

        // Setup message handlers
        _setupMessageHandlers();
      }
    } catch (e) {
      debugPrint('❌ Notification service error: $e');
    }
  }

  /// Setup handlers for different message states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Message received (foreground): ${message.notification?.title}');

      if (message.notification != null) {
        debugPrint('Notification Title: ${message.notification!.title}');
        debugPrint('Notification Body: ${message.notification!.body}');
      }
    });

    // Handle notification taps (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📬 Notification opened: ${message.notification?.title}');
      _handleNotificationTap(message);
    });

    // Handle initial message if app was opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('📭 App opened from terminated state via notification');
        _handleNotificationTap(message);
      }
    });
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // You can navigate to specific screens based on message data
    debugPrint('Handling notification tap with data: ${message.data}');

    // Example: Navigate to specific URL from notification data
    if (message.data.containsKey('url')) {
      final url = message.data['url'];
      debugPrint('Navigate to URL: $url');
      // You can emit an event here to navigate the WebView to this URL
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('📌 Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('📍 Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (for logout, etc.)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('🗑️ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📩 Background message: ${message.notification?.title}');
}
