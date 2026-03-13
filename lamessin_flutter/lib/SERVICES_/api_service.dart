import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const bool useNgrok = false; 

  static String get baseUrl {
    if (useNgrok) {
      return "https://budlike-kai-unflickering.ngrok-free.dev/api";
    }

    if (kIsWeb) {
      return "http://127.0.0.1:8000/api";
    }
    if (Platform.isAndroid) {

      return "http://10.0.2.2:8000/api"; 
    } else if (Platform.isIOS) {
      return "http://localhost:8000/api";
    }

    return "http://127.0.0.1:8000/api";
  }
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

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
  // NOTIFICATIONS (FIREBASE FCM)
  // ===========================================================================

  static Future<bool> enregistrerFCMToken(String fcmToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications/enregistrerToken/'),
        headers: await _getHeaders(),
        body: jsonEncode({"token": fcmToken}), 
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
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
        body: jsonEncode({
          "numero_telephone": telephone,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
// On décode la réponse du serveur
        final Map<String, dynamic> data = jsonDecode(response.body);

// On récupère l'instance des préférences locales
        final prefs = await SharedPreferences.getInstance();

// Sauvegarde des tokens
        if (data.containsKey('access')) {
          await prefs.setString('access_token', data['access']);
        }
        if (data.containsKey('refresh')) {
          await prefs.setString('refresh_token', data['refresh']);
        }

        print("Connexion réussie ! Token récupéré.");
        return data['access'];
      } else {
// Affiche l'erreur exacte renvoyée par Django dans ta console Flutter
        print("Échec connexion (${response.statusCode}): ${response.body}");
        return null;
      }
    } catch (e) {
      print("Erreur lors de l'appel API Login: $e");
      return null;
    }
  }

  static Future<bool> inscription(Map<String, dynamic> donnees) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscription/'),
        headers: {"Content-Type": "application/json", "ngrok-skip-browser-warning": "true"},
        body: jsonEncode(donnees),
      );
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<Map<String, dynamic>?> getProfil() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profil/'), headers: await _getHeaders());
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
      return null;
    } catch (e) { return null; }
  }

  static Future<bool> updateProfil(Map<String, dynamic> donnees) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/updateProfil/'), headers: await _getHeaders(), body: jsonEncode(donnees));
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // ===========================================================================
  // RENDEZ-VOUS
  // ===========================================================================

  static Future<List<dynamic>> getListeMedecins() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/listeMedecins/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getCreneaux(int medecinId, String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/creneauxDisponible/?medecin=$medecinId&date=$date'), headers: await _getHeaders());
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) { return []; }
  }

  static Future<bool> creerRendezVous(Map<String, dynamic> rdv) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/rendezvous/creer/'), headers: await _getHeaders(), body: jsonEncode(rdv));
      return response.statusCode == 201;
    } catch (e) { return false; }
  }

  static Future<List<dynamic>> getMesRendezVous() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rendezvous/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
  }

  static Future<bool> annulerRendezVous(int id) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/rendezvous/$id/'), headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // ===========================================================================
  // COMMANDES & PAIEMENT avec FedaPay
  // ===========================================================================

  static Future<Map<String, dynamic>?> creerCommandeEtPayer(int medicamentId, int quantite) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/commandes/creerEtPayer/'), 
        headers: await _getHeaders(),
        body: json.encode({'medicament_id': medicamentId, 'quantite': quantite}),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>?> obtenirLienPaiement(int commandeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/commandes/$commandeId/genererLien/'), 
        headers: await _getHeaders()
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<List<dynamic>> getMesCommandes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/commandes/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
  }
  static Future<Map<String, dynamic>?> creerCommandeMultiple(List<Map<String, dynamic>> articles) async {
    try {
      final List<Map<String, dynamic>> formattedArticles = articles.map((item) {
        return {
// .toString() puis int.parse sécurise si c'est déjà un int ou un String
          'id': int.parse((item['id'] ?? item['idMedoc']).toString()),
          'qte': int.parse((item['qte'] ?? item['quantite']).toString()),
          'pharmacie_id': int.parse((item['pharmacieId'] ?? item['pharmacie_id']).toString()),
        };
      }).toList();

      final response = await http.post(
        Uri.parse('$baseUrl/commandes/multiple/'),
        headers: await _getHeaders(),
        body: json.encode({'articles': formattedArticles}),
      );
      return (response.statusCode == 200 || response.statusCode == 201) ? json.decode(response.body) : null;
    } catch (e) { 
      print("Erreur Commande Multiple: $e");
      return null; 
    }
  }
  // ===========================================================================
  // MÉDICAL & ÉTABLISSEMENTS
  // ===========================================================================

  static Future<List<dynamic>> rechercherMedicaments(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medicaments/recherche/?q=$query'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getEtablissements() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/etablissements/"), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
  }

  static Future<List<dynamic>> getTraitements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/traitements/'), headers: await _getHeaders());
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) { return []; }
  }

  // ===========================================================================
  // ORDONNANCES & SUIVI MÉDICAL
  // ===========================================================================

  static Future<List<dynamic>> getMesOrdonnances() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ordonnances/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) { return []; }
  }

  static Future<bool> validerPriseMedicament(int priseId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/traitements/valider-prise/$priseId/'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) { return false; }
  }

  // ===========================================================================
  // ASSISTANT INTELLIGENT (GEMINI)
  // ===========================================================================

  static Future<Map<String, dynamic>?> envoyerMessageAssistant(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assistant/chat/'),
        headers: await _getHeaders(),
        body: jsonEncode({"prompt": prompt}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return null;
    } catch (e) { return null; }
  }
static Future<List<dynamic>> getHistoriqueAssistant() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assistant/historique/'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
// utf8.decode est important pour les accents (é, à, è)
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print("Erreur historique: $e");
      return [];
    }
  }
}
