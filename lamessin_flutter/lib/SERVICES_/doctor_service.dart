import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports de modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/rendezvous_model.dart';
import '../MODELS_/notification_model.dart';
import '../MODELS_/plage_horaire_model.dart';
import '../MODELS_/consultation_model.dart';
import '../MODELS_/ordonnance_model.dart';

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

  // ========================= DASHBOARD & STATISTIQUES =========================

  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/dashboard/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getDashboard: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStatistiques() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/statistiques/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getStatistiques: $e");
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
static Future<bool> expirerRendezVous() async {
  try {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/medecin/rendezvous/expirer/'),
      headers: await ApiService.getHeaders(),
    );
    return response.statusCode == 200;
  } catch (e) {
    debugPrint("Erreur expirerRendezVous: $e");
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
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerConsultation: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getConsultation(int consultationId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/consultations/$consultationId/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getConsultation: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getConsultationByRdv(int rdvId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/consultations/by-rdv/$rdvId/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getConsultationByRdv: $e");
      return null;
    }
  }

  // ========================= ORDONNANCES =========================

  static Future<List<dynamic>> getOrdonnances() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/ordonnances/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getOrdonnances: $e");
      return [];
    }
  }

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
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerOrdonnance: $e");
      return null;
    }
  }

  // ========================= DISPONIBILITÉS =========================

  static Future<List<PlageHoraire>> getPlagesHoraires() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/plages-horaires/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => PlageHoraire.fromJson(item)).toList();
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

      return response.statusCode == 200 || response.statusCode == 204;
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

  static Future<Map<String, dynamic>?> getDossierPatient(int patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medecin/patients/$patientId/dossier/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getDossierPatient: $e");
      return null;
    }
  }

  // ========================= DOCUMENTS =========================

  static Future<bool> uploadDocumentMedical({
    required int consultationId,
    required String filePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/medecin/documents/upload/'),
      );

      final headers = await ApiService.getHeaders();
      request.headers.addAll(headers);

      request.fields['consultation_id'] = consultationId.toString();
      request.files.add(await http.MultipartFile.fromPath('document', filePath));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur uploadDocumentMedical: $e");
      return false;
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
}