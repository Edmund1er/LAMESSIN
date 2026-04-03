import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports de modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/medicament_model.dart';
import '../MODELS_/rendezvous_model.dart';
import '../MODELS_/commande_model.dart';
import '../MODELS_/ordonnance_model.dart';
import '../MODELS_/consultation_model.dart';
import '../MODELS_/traitement_model.dart';
import '../MODELS_/etablissement_model.dart';
import '../MODELS_/message_model.dart';

class PatientService {

  // ========================= MÉDECINS & RDV =========================

  static Future<List<Medecin>> getListeMedecins() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/listeMedecins/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Medecin.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getListeMedecins: $e");
      return [];
    }
  }

  static Future<List<dynamic>> getCreneaux(int medecinId, String date) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/creneauxDisponible/?medecin=$medecinId&date=$date',
        ),
        headers: await ApiService.getHeaders(),
      );

      return response.statusCode == 200
          ? jsonDecode(response.body)
          : [];
    } catch (e) {
      debugPrint("Erreur getCreneaux: $e");
      return [];
    }
  }

  static Future<bool> creerRendezVous(Map<String, dynamic> rdv) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/rendezvous/creer/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode(rdv),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Erreur creerRendezVous: $e");
      return false;
    }
  }

  static Future<List<RendezVous>> getMesRendezVous() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/rendezvous/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => RendezVous.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesRendezVous: $e");
      return [];
    }
  }

  static Future<bool> annulerRendezVous(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/rendezvous/$id/'),
        headers: await ApiService.getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur annulerRendezVous: $e");
      return false;
    }
  }

  // ========================= MÉDICAMENTS =========================

  static Future<List<Medicament>> rechercherMedicaments(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/medicaments/recherche/?q=$query'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Medicament.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur rechercherMedicaments: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> creerCommandeMultiple(
    List<Map<String, dynamic>> articles, {
    String methodeRetrait = "RETRAIT",
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/commandes/creerEtPayer/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'articles': articles,
          'methode_retrait': methodeRetrait,
        }),
      );

      return (response.statusCode == 200 || response.statusCode == 201)
          ? json.decode(response.body)
          : null;
    } catch (e) {
      debugPrint("Erreur creerCommandeMultiple: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> obtenirLienPaiement(int commandeId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/commandes/$commandeId/genererLien/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur obtenirLienPaiement: $e");
      return null;
    }
  }

  static Future<List<Commande>> getMesCommandes() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/commandes/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Commande.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesCommandes: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getRecuCommande(int commandeId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/commandes/$commandeId/recu/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getRecuCommande: $e");
      return null;
    }
  }

  // ========================= DOSSIER MÉDICAL =========================

  static Future<List<Traitement>> getTraitements() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/traitements/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Traitement.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getTraitements: $e");
      return [];
    }
  }

  static Future<List<Ordonnance>> getMesOrdonnances() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ordonnances/'),
        headers: await ApiService.getHeaders(),
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

  static Future<bool> validerPriseMedicament(int priseId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/traitements/valider-prise/$priseId/'),
        headers: await ApiService.getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur validerPriseMedicament: $e");
      return false;
    }
  }

  static Future<List<Consultation>> getMesConsultations() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/consultations/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Consultation.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getMesConsultations: $e");
      return [];
    }
  }

  // ========================= ÉTABLISSEMENTS =========================

  static Future<List<EtablissementSante>> getEtablissements() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/etablissements/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => EtablissementSante.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getEtablissements: $e");
      return [];
    }
  }

  // ========================= ASSISTANT =========================

  static Future<String?> envoyerMessageAssistant(String prompt) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/assistant/chat/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"prompt": prompt}),
    );

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes))['reponse'];
    }
    return null;
  }

  static Future<List<Message>> getHistoriqueAssistant() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/assistant/historique/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Message.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur historique assistant: $e");
      return [];
    }
  }
}