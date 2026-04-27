import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

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

  static Future<bool> expirerRendezVous() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/patient/rendezvous/expirer/'),
        headers: await ApiService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur expirerRendezVous: $e");
      return false;
    }
  }

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

      return response.statusCode == 200 ? jsonDecode(response.body) : [];
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
        Uri.parse('${ApiService.baseUrl}/commandes/creer/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'articles': articles,
          'methode_retrait': methodeRetrait,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur creerCommandeMultiple: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> initierPaiementMobileMoney({
    required int commandeId,
    required String telephone,
    required String operateur,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/paiement/initier/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          'commande_id': commandeId,
          'telephone': telephone,
          'operateur': operateur,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur initierPaiementMobileMoney: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> verifierStatutPaiement(
    int commandeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/paiement/verifier/$commandeId/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur verifierStatutPaiement: $e");
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

  // ========================= ANCIEN ASSISTANT =========================

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

  // ========================= NOUVEAU IA GROQ =========================

  static Future<Map<String, dynamic>?> getIAStatut() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/ia/statut/'),
        headers: await ApiService.getHeaders(),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getIAStatut: $e");
      return null;
    }
  }

  static Future<String?> envoyerMessageIAMedical(String message) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ia/chatbot/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['reponse'];
      }
      debugPrint("Erreur IA: ${response.statusCode} - ${response.body}");
      return null;
    } catch (e) {
      debugPrint("Erreur envoyerMessageIAMedical: $e");
      return null;
    }
  }

  static Future<String?> envoyerMessageIAvecHistorique(String message, List<Map<String, String>> historique) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ia/chatbot/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({
          "message": message,
          "historique": historique,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['reponse'];
      }
      return null;
    } catch (e) {
      debugPrint("Erreur envoyerMessageIAvecHistorique: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> analyserOrdonnanceTexte(String texteOrdonnance) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ia/analyse-ordonnance/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({"texte_ordonnance": texteOrdonnance}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur analyserOrdonnanceTexte: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> verifierInteractions(List<String> medicaments) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ia/interactions/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({"medicaments": medicaments}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur verifierInteractions: $e");
      return null;
    }
  }

  static Future<String?> resumerTexteMedical(String longTexte) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/ia/resume/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({"texte": longTexte}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['resume'];
      }
      return null;
    } catch (e) {
      debugPrint("Erreur resumerTexteMedical: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> envoyerMessageAssistantNew(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/assistant-ia/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"prompt": prompt}),
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur envoyerMessageAssistantNew: $e");
      return null;
    }
  }
}