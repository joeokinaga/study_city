import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Service that sends browser notifications for review reminders.
///
/// Uses the Web Notification API so it works purely client-side without a
/// server or FCM push infrastructure.
class NotificationService {
  NotificationService();

  /// Request the user's permission to show browser notifications.
  /// Returns `true` if permission was granted.
  Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    try {
      final permission =
          (await web.Notification.requestPermission().toDart).toDart;
      return permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  /// Whether the user has already granted notification permission.
  bool get isPermissionGranted {
    if (!kIsWeb) return false;
    try {
      return web.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  /// Show a browser notification for pending review items.
  ///
  /// Does nothing when the count is zero, when the tab is in the foreground,
  /// or when notification permission has not been granted.
  void showReviewReminder(int pendingCount) {
    if (pendingCount <= 0) return;
    if (!isPermissionGranted) return;

    final body = pendingCount == 1
        ? 'You have 1 item to review today.'
        : 'You have $pendingCount items to review today.';

    try {
      web.Notification(
        'Study City - Review Reminder',
        web.NotificationOptions(body: body, icon: 'icons/Icon-192.png'),
      );
    } catch (_) {
      // Silently ignore – some browsers restrict Notification in certain
      // contexts (e.g. iframes).
    }
  }
}
