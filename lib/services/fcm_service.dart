import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await requestPermission();
  }

  Future<String?> getToken() async {
    return await _messaging.getToken(
      vapidKey: 'YOUR_VAPID_KEY',
    );
  }

  Future<void> requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void onMessage(Function(RemoteMessage) handler) {
    FirebaseMessaging.onMessage.listen(handler);
  }
}
