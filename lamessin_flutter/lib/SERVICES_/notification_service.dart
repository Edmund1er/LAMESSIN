import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialiser() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(settings:initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notification cliquee : ${response.payload}");
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'paiement_channel_id',
      'Paiements Lamessin',
      description: 'Notifications de validation de paiement',
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    try {
      String? token = await _messaging.getToken();
      print("FCM Token recupere : $token");
      if (token != null) {
        bool success = await ApiService.enregistrerFCMToken(token);
        print("Enregistrement token : ${success ? 'OK' : 'ECHEC'}");
      }
    } catch (e) {
      print("Erreur Token FCM : $e");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _afficherNotificationLocale(message);
    });
  }

  static void _afficherNotificationLocale(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'paiement_channel_id',
            'Paiements Lamessin',
            channelDescription: 'Notifications de validation de paiement',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }
}