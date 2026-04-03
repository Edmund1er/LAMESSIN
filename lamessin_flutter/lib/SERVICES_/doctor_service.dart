import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports de modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/rendezvous_model.dart';
import '../MODELS_/consultation_model.dart';
import '../MODELS_/ordonnance_model.dart';
import '../MODELS_/plage_horaire_model.dart';
import '../MODELS_/statistiques_medecin_model.dart';

class DoctorService {
  
  // ==================== BASE URL ====================
  static String get _baseUrl => ApiService.baseUrl;
  static Future<Map<String, String>> get _headers => ApiService.getHeaders();

  // ==================== 1. TABLEAU DE BORD ====================
  
  /// Récupère les statistiques du tableau de bord médecin
  static Future<StatistiquesMedecin?> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/dashboard/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return StatistiquesMedecin.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getDashboard: $e");
      return null;
    }
  }

  /// Récupère les statistiques détaillées
  static Future<Map<String, dynamic>?> getStatistiques() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/statistiques/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getStatistiques: $e");
      return null;
    }
  }

  // ==================== 2. GESTION DES RENDEZ-VOUS ====================

  /// Récupère la liste des rendez-vous du médecin
  /// [filtre] : 'tous', 'aujourdhui', 'a_venir', 'passe'
  static Future<List<RendezVous>> getRendezVous({String filtre = 'tous'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/rendezvous/?filtre=$filtre'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => RendezVous.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getRendezVous: $e");
      return [];
    }
  }

  /// Modifie le statut d'un rendez-vous
  /// Statuts possibles: 'en_attente', 'confirme', 'annule', 'termine'
  static Future<bool> updateRendezVousStatut(int rdvId, String statut) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/medecin/rendezvous/$rdvId/statut/'),
        headers: await _headers,
        body: jsonEncode({'statut': statut}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur updateRendezVousStatut: $e");
      return false;
    }
  }

  // ==================== 3. GESTION DES CONSULTATIONS ====================

  /// Crée une nouvelle consultation après un rendez-vous
  static Future<Consultation?> creerConsultation({
    required int rdvId,
    required String diagnostic,
    required String actesEffectues,
    String? notesMedecin,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/medecin/consultations/creer/'),
        headers: await _headers,
        body: jsonEncode({
          'rdv_id': rdvId,
          'diagnostic': diagnostic,
          'actes_effectues': actesEffectues,
          'notes_medecin': notesMedecin ?? '',
        }),
      );

      if (response.statusCode == 201) {
        return Consultation.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerConsultation: $e");
      return null;
    }
  }

  /// Récupère les détails d'une consultation
  static Future<Consultation?> getConsultation(int consultationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/consultations/$consultationId/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return Consultation.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getConsultation: $e");
      return null;
    }
  }

  // ==================== 4. GESTION DES ORDONNANCES ====================

  /// Crée une nouvelle ordonnance
  static Future<Ordonnance?> creerOrdonnance({
    required int consultationId,
    required int patientId,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/medecin/ordonnances/creer/'),
        headers: await _headers,
        body: jsonEncode({
          'consultation_id': consultationId,
          'patient_id': patientId,
          'details': details,
        }),
      );

      if (response.statusCode == 201) {
        return Ordonnance.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerOrdonnance: $e");
      return null;
    }
  }

  /// Récupère toutes les ordonnances du médecin
  static Future<List<Ordonnance>> getMesOrdonnances() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/ordonnances/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Ordonnance.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesOrdonnances: $e");
      return [];
    }
  }

  // ==================== 5. GESTION DES DISPONIBILITÉS ====================

  /// Récupère toutes les plages horaires du médecin
  static Future<List<PlageHoraire>> getPlagesHoraires() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/plages-horaires/'),
        headers: await _headers,
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

  /// Ajoute une nouvelle plage horaire
  static Future<PlageHoraire?> ajouterPlageHoraire({
    required String date,
    required String heureDebut,
    required String heureFin,
    int dureeConsultation = 60,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/medecin/plages-horaires/'),
        headers: await _headers,
        body: jsonEncode({
          'date': date,
          'heure_debut': heureDebut,
          'heure_fin': heureFin,
          'duree_consultation': dureeConsultation,
        }),
      );

      if (response.statusCode == 201) {
        return PlageHoraire.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur ajouterPlageHoraire: $e");
      return null;
    }
  }

  /// Supprime une plage horaire
  static Future<bool> supprimerPlageHoraire(int plageId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/medecin/plages-horaires/$plageId/'),
        headers: await _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur supprimerPlageHoraire: $e");
      return false;
    }
  }

  // ==================== 6. GESTION DES PATIENTS ====================

  /// Récupère la liste des patients du médecin
  static Future<List<Patient>> getMesPatients() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/patients/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Patient.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesPatients: $e");
      return [];
    }
  }

  /// Récupère le dossier médical complet d'un patient
  static Future<Map<String, dynamic>?> getDossierPatient(int patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medecin/patients/$patientId/dossier/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getDossierPatient: $e");
      return null;
    }
  }

  // ==================== 7. GESTION DES DOCUMENTS ====================

  /// Upload d'un document médical (analyse, radio, etc.)
  static Future<String?> uploadDocumentMedical({
    required int consultationId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/medecin/documents/upload/'),
      );
      
      request.headers.addAll(await _headers);
      request.fields['consultation_id'] = consultationId.toString();
      request.files.add(
        await http.MultipartFile.fromPath('document', filePath, filename: fileName),
      );

      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = json.decode(responseData);
        return jsonData['document_url'];
      }
      return null;
    } catch (e) {
      debugPrint("Erreur uploadDocumentMedical: $e");
      return null;
    }
  }
}