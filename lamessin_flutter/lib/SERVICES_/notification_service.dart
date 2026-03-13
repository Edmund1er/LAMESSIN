import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../SERVICES_/api_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialisation complète des notifications au démarrage
  static Future<void> initialiser() async {
    // 1. Demander la permission (Android 13+ et iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission accordée pour les notifications');
    }

    // 2. Configuration des notifications locales pour le premier plan (Foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );


  await _localNotifications.initialize(
        settings: initializationSettings, // Ici, le nom du paramètre est 'settings'
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print("Notification cliquée : ${response.payload}");
        },
      );
    // 3. Récupération et enregistrement du Token FCM
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print("Token FCM récupéré : $token");
        // Envoi au backend Django pour l'utilisateur connecté
        await ApiService.enregistrerFCMToken(token);
      }
    } catch (e) {
      print("Erreur lors de la récupération du token FCM : $e");
    }

    // 4. Écoute des messages quand l'application est ouverte (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message reçu en premier plan !");
      _afficherNotificationLocale(message);
    });
  }

  /// Affiche la bannière de notification
  static void _afficherNotificationLocale(RemoteMessage message) {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      _localNotifications.show(
        // Utilisation des paramètres nommés corrects
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
            ticker: 'ticker',
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  }
}