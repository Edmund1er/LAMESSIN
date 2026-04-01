import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Imports de modèles
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/medicament_model.dart';
import '../MODELS_/rendezvous_model.dart';
import '../MODELS_/message_model.dart';
import '../MODELS_/notification_model.dart';
import '../MODELS_/etablissement_model.dart';
import '../MODELS_/commande_model.dart';
import '../MODELS_/ordonnance_model.dart';
import '../MODELS_/consultation_model.dart';
import '../MODELS_/traitement_model.dart';

class ApiService {
  static const bool useNgrok = false;

  static String get baseUrl {
    if (useNgrok) return "https://budlike-kai-unflickering.ngrok-free.dev/api";
    if (kIsWeb) return "http://127.0.0.1:8000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:8000/api";
    return "http://localhost:8000/api";
  }

  // AJOUT : URL de base pour les médias (images)
  static String get mediaBaseUrl {
    if (useNgrok) return "https://budlike-kai-unflickering.ngrok-free.dev";
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (Platform.isAndroid) return "http://10.0.2.2:8000";
    return "http://localhost:8000";
  }

  // ===========================================================================
  // GESTION DES TOKENS & PERSISTANCE (CONNEXION AUTOMATIQUE)
  // ===========================================================================

  // Récupération du Token d'accès
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // VÉRIFICATION DE CONNEXION AUTOMATIQUE (Au démarrage)
  static Future<bool> estConnecte() async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');
    String? refreshToken = prefs.getString('refresh_token');

    if (accessToken == null && refreshToken == null) return false;

    // Si on a un access_token, on vérifie s'il est encore valide avec un appel léger (profil)
    final response = await http.get(
      Uri.parse('$baseUrl/profil/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return true; // Toujours valide
    } else if (response.statusCode == 401 && refreshToken != null) {
      // Access token expiré, on tente de rafraîchir avec le refresh_token
      return await rafraichirLeToken();
    }

    return false;
  }

  // Rafraîchir le token automatiquement
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

  // Gestion des Headers avec injection automatique du Token
  static Future<Map<String, String>> _getHeaders() async {
    String? token = await getToken();
    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "ngrok-skip-browser-warning": "true",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ===========================================================================
  // AUTHENTIFICATION & PROFIL
  // ===========================================================================

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
        final Map<String, dynamic> data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        if (data.containsKey('access'))
          await prefs.setString('access_token', data['access']);
        if (data.containsKey('refresh'))
          await prefs.setString('refresh_token', data['refresh']);
        return data['access'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> inscription(Map<String, dynamic> donnees) async {
    try {
      print("DONNÉES ENVOYÉES: ${jsonEncode(donnees)}"); // ← AJOUTER
      final response = await http.post(
        Uri.parse('$baseUrl/inscription/'),
        headers: {
          "Content-Type": "application/json",
          "ngrok-skip-browser-warning": "true",
        },
        body: jsonEncode(donnees),
      );
      print("INSCRIPTION STATUS: ${response.statusCode}"); // ← AJOUTER
      print("INSCRIPTION BODY: ${response.body}"); // ← AJOUTER
      return response.statusCode == 201;
    } catch (e) {
      print("ERREUR INSCRIPTION: $e"); // ← AJOUTER
      return false;
    }
  }

  // Remplace toute la méthode getProfil par celle-ci
  static Future<dynamic> getProfil() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profil/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        var data = json.decode(utf8.decode(response.bodyBytes));

        // CORRECTION ICI :
        // Si la réponse contient 'compte_utilisateur', c'est que c'est un profil détaillé (Patient/Medecin).
        if (data.containsKey('compte_utilisateur')) {
          // On vérifie si c'est un patient (présence de date_naissance)
          if (data.containsKey('date_naissance')) {
            return Patient.fromJson(data);
          }
          // Sinon on renvoie l'Utilisateur imbriqué (pour Medecin/Pharmacien ou fallback)
          return Utilisateur.fromJson(data['compte_utilisateur']);
        } else {
          // Cas rare : réponse directe Utilisateur
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
      print("TENTATIVE UPDATE PROFIL: $donnees"); // Debug
      final response = await http.patch(
        Uri.parse('$baseUrl/updateProfil/'),
        headers: await _getHeaders(),
        body: jsonEncode(donnees),
      );

      print("UPDATE PROFIL STATUS: ${response.statusCode}");
      print("UPDATE PROFIL BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      print("ERREUR UPDATE PROFIL: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      // Si tu utilises SharedPreferences pour le token, vide-le ici
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.clear();
      print("Déconnexion réussie");
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
    }
  }

  // ===========================================================================
  // NOTIFICATIONS
  // ===========================================================================

  static Future<bool> enregistrerFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/enregistrerToken/'),
        headers: await _getHeaders(),
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
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => NotificationModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // RENDEZ-VOUS
  // ===========================================================================

  static Future<List<Medecin>> getListeMedecins() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/listeMedecins/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Medecin.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getCreneaux(int medecinId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/creneauxDisponible/?medecin=$medecinId&date=$date'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> creerRendezVous(Map<String, dynamic> rdv) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rendezvous/creer/'),
        headers: await _getHeaders(),
        body: jsonEncode(rdv),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<RendezVous>> getMesRendezVous() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rendezvous/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => RendezVous.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> annulerRendezVous(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/rendezvous/$id/'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // COMMANDES & MÉDICAMENTS
  // ===========================================================================

  static Future<List<Medicament>> rechercherMedicaments(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/medicaments/recherche/?q=$query'),
        headers: await _getHeaders(),
      );

      // DEBUG : Affiche ce que le serveur répond pour comprendre pourquoi ça ne vient pas
      print("RECHERCHE MEDOC STATUS: ${response.statusCode}");
      print("RECHERCHE MEDOC BODY: ${response.body}");

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Medicament.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print("ERREUR RECHERCHE MEDOC: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>?> creerCommandeMultiple(
    List<Map<String, dynamic>> articles, {
    String methodeRetrait = "RETRAIT",
  }) async {
    try {
      final response = await http.post(
        // URL CORRIGÉE ICI : Un seul Uri.parse correspondant au backend
        Uri.parse('$baseUrl/commandes/creerEtPayer/'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'articles': articles,
          'methode_retrait': methodeRetrait,
        }),
      );
      return (response.statusCode == 200 || response.statusCode == 201)
          ? json.decode(response.body)
          : null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> obtenirLienPaiement(
    int commandeId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/commandes/$commandeId/genererLien/'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        // Le backend renverra un JSON contenant {'payment_url': '...'}
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        debugPrint(
          "Erreur lors de la génération du lien CinetPay: ${response.statusCode}",
        );
        return null;
      }
    } catch (e) {
      debugPrint("Erreur réseau obtenirLienPaiement: $e");
      return null;
    }
  }

  static Future<List<Commande>> getMesCommandes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commandes/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Commande.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // MÉDICAL & ÉTABLISSEMENTS
  // ===========================================================================

  static Future<List<EtablissementSante>> getEtablissements() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/etablissements/"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => EtablissementSante.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Traitement>> getTraitements() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/traitements/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Traitement.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<Ordonnance>> getMesOrdonnances() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ordonnances/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Ordonnance.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> validerPriseMedicament(int priseId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/traitements/valider-prise/$priseId/'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Consultation>> getMesConsultations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Consultation.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // ASSISTANT (GEMINI)
  // ===========================================================================
  static Future<String?> envoyerMessageAssistant(String prompt) async {
    final response = await http.post(
      Uri.parse("http://127.0.0.1:8000/api/assistant/chat/"),
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
        Uri.parse('$baseUrl/assistant/historique/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Message.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getRecuCommande(int commandeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commandes/$commandeId/recu/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
