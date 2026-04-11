import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Imports modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/notification_model.dart';

class ApiService {
  static const bool useNgrok = false;

  static String get baseUrl {
    if (useNgrok) return "https://budlike-kai-unflickering.ngrok-free.dev/api";
    if (kIsWeb) return "http://127.0.0.1:8000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:8000/api";
    return "http://localhost:8000/api";
  }

  static String get mediaBaseUrl {
    if (useNgrok) return "https://budlike-kai-unflickering.ngrok-free.dev";
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://localhost:8000";
  }

  // ========================= TOKEN =========================

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<bool> estConnecte() async {
    final prefs = await SharedPreferences.getInstance();
    String? refreshToken = prefs.getString('refresh_token');

    final response = await http.get(
      Uri.parse('$baseUrl/profil/'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) return true;

    if (response.statusCode == 401 && refreshToken != null) {
      return await rafraichirLeToken();
    }

    return false;
  }

  static Future<bool> rafraichirLeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/token/refresh/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    String? token = await getToken();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "ngrok-skip-browser-warning": "true",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ========================= AUTH =========================

  static Future<String?> login(String telephone, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode({"numero_telephone": telephone, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);

        // Sauvegarde du rôle pour une utilisation future dans l'app
        String role = data['role'] ?? 'INCONNU';
        await prefs.setString('user_role', role);

        return role;
      }

      print("Erreur Login: ${response.body}");
      return null;
    } catch (e) {
      print("Erreur Connexion: $e");
      return null;
    }
  }

  static Future<bool> inscription(Map<String, dynamic> donnees) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscription/'),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode(donnees),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("DÉTAIL ERREUR DJANGO : ${response.body}");
        return false;
      }
    } catch (e) {
      print("ERREUR RÉSEAU : $e");
      return false;
    }
  }

  static Future<dynamic> getProfil() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profil/'),
        headers: await getHeaders(),
      );

      if (response.statusCode == 200) {
        var data = json.decode(utf8.decode(response.bodyBytes));

        if (data.containsKey('compte_utilisateur')) {
          if (data.containsKey('date_naissance')) {
            return Patient.fromJson(data);
          }
          return Utilisateur.fromJson(data['compte_utilisateur']);
        } else {
          return Utilisateur.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateProfil(Map<String, dynamic> donnees) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/updateProfil/'),
        headers: await getHeaders(),
        body: jsonEncode(donnees),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ========================= NOTIFICATIONS =========================

  static Future<bool> enregistrerFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/enregistrerToken/'),
        headers: await getHeaders(),
        body: jsonEncode({"token": fcmToken}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: await getHeaders(),
      );

      print("NOTIFS STATUS: ${response.statusCode}");
      print("NOTIFS BODY: ${response.body}");

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        print("NOTIFS COUNT: ${data.length}");
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("NOTIFS ERREUR: $e");
      return [];
    }
  }
}
