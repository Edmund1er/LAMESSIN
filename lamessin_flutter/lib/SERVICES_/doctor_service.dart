import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports de modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/rendezvous_model.dart';
import '../MODELS_/notification_model.dart';

class DoctorService {
  
  // ========================= PROFIL =========================

  static Future<dynamic> getProfil() async {
    try {
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
    } catch (e) {
      debugPrint("Erreur getProfil: $e");
      return null;
    }
  }

  // ========================= RENDEZ-VOUS =========================

  static Future<List<RendezVous>> getMesRendezVousMedecin() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/rendezvous/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => RendezVous.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesRendezVousMedecin: $e");
      return [];
    }
  }

  static Future<bool> updateRendezVousStatut(int rdvId, String statut) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/medecin/rendezvous/$rdvId/statut/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'statut': statut}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur updateRendezVousStatut: $e");
      return false;
    }
  }

  // ========================= CONSULTATIONS =========================

  static Future<Map<String, dynamic>?> creerConsultation({
    required int rdvId,
    required String diagnostic,
    required String actesEffectues,
    String? notesMedecin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/medecin/consultations/creer/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'rdv_id': rdvId,
          'diagnostic': diagnostic,
          'actes_effectues': actesEffectues,
          'notes_medecin': notesMedecin ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerConsultation: $e");
      return null;
    }
  }

  // ========================= ORDONNANCES =========================

  static Future<Map<String, dynamic>?> creerOrdonnance({
    required int consultationId,
    required int patientId,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/medecin/ordonnances/creer/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'consultation_id': consultationId,
          'patient_id': patientId,
          'details': details,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerOrdonnance: $e");
      return null;
    }
  }

  // ========================= DISPONIBILITÉS =========================

  static Future<List<dynamic>> getPlagesHoraires() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/plages-horaires/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getPlagesHoraires: $e");
      return [];
    }
  }

  static Future<bool> ajouterPlageHoraire({
    required String date,
    required String heureDebut,
    required String heureFin,
    int dureeConsultation = 60,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/medecin/plages-horaires/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'date': date,
          'heure_debut': heureDebut,
          'heure_fin': heureFin,
          'duree_consultation': dureeConsultation,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Erreur ajouterPlageHoraire: $e");
      return false;
    }
  }

  static Future<bool> supprimerPlageHoraire(int plageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiService.baseUrl}/medecin/plages-horaires/$plageId/'),
        headers: await ApiService.getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur supprimerPlageHoraire: $e");
      return false;
    }
  }

  // ========================= PATIENTS =========================

  static Future<List<dynamic>> getMesPatients() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/patients/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesPatients: $e");
      return [];
    }
  }

  // ========================= NOTIFICATIONS =========================

  static Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notifications/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getNotifications: $e");
      return [];
    }
  }

  // ========================= STATISTIQUES =========================

  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/dashboard/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getDashboard: $e");
      return null;
    }
  }
}