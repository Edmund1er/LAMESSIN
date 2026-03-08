import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000/api";
    if (Platform.isAndroid) return "http://10.0.2.2:8000/api";
    if (Platform.isIOS) return "http://localhost:8000/api";
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"numero_telephone": telephone, "password": password}),
      );
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        return data['access'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  //------------------------------------ INSCRIPTION ------------------------------------------------
  static Future<bool> inscription(Map<String, dynamic> donnees) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscription/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(donnees),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getProfil() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/profil/'), headers: await _getHeaders());
      if (response.statusCode == 200) return json.decode(utf8.decode(response.bodyBytes));
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> updateProfil(Map<String, dynamic> donnees) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/updateProfil/'), headers: await _getHeaders(), body: jsonEncode(donnees));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ===========================================================================
  // RENDEZ-VOUS
  // ===========================================================================

  static Future<List<dynamic>> getListeMedecins() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/listeMedecins/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getCreneaux(int medecinId, String date) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/creneauxDisponible/?medecin=$medecinId&date=$date'), headers: await _getHeaders());
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> creerRendezVous(Map<String, dynamic> rdv) async {
    try {
      final response = await http.post(Uri.parse('$baseUrl/rendezvous/creer/'), headers: await _getHeaders(), body: jsonEncode(rdv));
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getMesRendezVous() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/rendezvous/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> annulerRendezVous(int id) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/rendezvous/$id/'), headers: await _getHeaders());
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // COMMANDES & PAIEMENT avec FedaPay
  // ===========================================================================

  static Future<Map<String, dynamic>?> creerCommandeEtPayer(int medicamentId, int quantite) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/commandes/creerEtPayer/'), 
        headers: await _getHeaders(),
        body: json.encode({
          'medicament_id': medicamentId,
          'quantite': quantite,
        }),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> obtenirLienPaiement(int commandeId) async {
    try {
// Cette route permet de repayer une commande restée "En attente"
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
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // MÉDICAL & ÉTABLISSEMENTS
  // ===========================================================================

  static Future<List<dynamic>> rechercherMedicaments(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medicaments/recherche/?q=$query'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getEtablissements() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/etablissements/"), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getTraitements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/traitements/'), headers: await _getHeaders());
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications/'), headers: await _getHeaders());
      return response.statusCode == 200 ? json.decode(utf8.decode(response.bodyBytes)) : [];
    } catch (e) {
      return [];
    }
  }
}