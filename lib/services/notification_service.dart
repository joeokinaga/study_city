import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/review_item.dart';
import 'fcm_service.dart';

class NotificationService {
  final FCMService _fcm;

  NotificationService(this._fcm);

  Future<void> initialize() async {
    await _fcm.initialize();
    _fcm.onMessage(_handleMessage);
  }

  Future<void> scheduleReviewReminder(List<ReviewItem> itemsDueToday) async {
    if (itemsDueToday.isEmpty) return;
    final count = itemsDueToday.length;
    // For web, we use the Notification API via FCM's onMessage
    // Server-side scheduling would send the actual push notification.
    // Here we request permission and register the handler so the app
    // is ready to receive notifications.
    await _fcm.requestPermission();
  }

  void _handleMessage(RemoteMessage message) {
    // Handle incoming notification while app is in foreground
  }
}
