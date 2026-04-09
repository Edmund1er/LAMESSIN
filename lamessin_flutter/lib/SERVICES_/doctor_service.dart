import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports de modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/rendezvous_model.dart';
import '../MODELS_/notification_model.dart';

class DoctorService {
  // ========================= PROFIL =========================

  static Future<dynamic> getProfil() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/profil/'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data.containsKey('compte_utilisateur')) {
        return Medecin.fromJson(data);
      }
      return Utilisateur.fromJson(data);
    }
    return null;
  }

  // ========================= RENDEZ-VOUS =========================

  static Future<List<RendezVous>> getMesRendezVousMedecin() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/rendezvous/medecin/'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => RendezVous.fromJson(item)).toList();
    }
    return [];
  }

  static Future<bool> confirmerRendezVous(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/rendezvous/$id/confirmer/'),
      headers: await ApiService.getHeaders(),
    );

    return response.statusCode == 200;
  }

  static Future<bool> annulerRendezVous(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiService.baseUrl}/rendezvous/$id/annuler/'),
      headers: await ApiService.getHeaders(),
    );

    return response.statusCode == 200;
  }

  // ========================= NOTIFICATIONS =========================

  static Future<List<NotificationModel>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notifications/'),
      headers: await ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => NotificationModel.fromJson(item)).toList();
    }
    return [];
  }
}
