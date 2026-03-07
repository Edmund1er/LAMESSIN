import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Pour le stockage réel

class ApiService {

  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000/api"; // Web
    if (Platform.isAndroid) return "http://10.0.2.2:8000/api"; // Android émulateur
    if (Platform.isIOS) return "http://localhost:8000/api"; // iOS émulateur
    return "http://127.0.0.1:8000/api"; // fallback
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

// On récupère le jeton stocké lors du login
  
    return prefs.getString('access_token'); 
  }
// ================================================================================================================
// MÉTHODES D'AUTHENTIFICATION 
// ================================================================================================================

// -----------------------------------------RÉCUPÉRATION DU PROFIL----------------------------------------------------

  static Future<Map<String, dynamic>?> getProfil() async {
    String? token = await getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profil/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // utf8.decode pour gérer les accents dans les noms/prénoms
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        print("Erreur profil: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau profil: $e");
      return null;
    }
  }
// -------------------------------Register -----------------------------------
  static Future<bool> inscription(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscription/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Erreur de connexion: $e");
      return false;
    }
  }
// -------------------------------login -----------------------------------
  static Future<String?> login(String telephone, String password) async {
    try {
      final reponse = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"numero_telephone": telephone, "password": password}),
      );

      if (reponse.statusCode == 200) {
        var data = jsonDecode(reponse.body);
        String token = data['access'];
        
// On sauvegarde le token pour les prochaines requêtes
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);

        print("Connexion réussie.");
        return token;
      } else {
        print("Erreur de connexion : ${reponse.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur lors du login : $e");
      return null;
    }
  }

// -------------------------------Deconnexion-----------------------------------
static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    print("Utilisateur déconnecté");
  }
// ================================================================================================================
//MÉTHODES DE GESTION DES RENDEZ-VOUS
// ================================================================================================================
  static Future<bool> creerRendezVous(Map<String, dynamic> rdvData) async {
    final url = Uri.parse("$baseUrl/rendezvous/creer/");
    
//  On récupère le vrai token stocké
    String? token = await getToken(); 

    try {
// on envoie du JSON plus le Token de sécurité
      final reponse = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", 
        },
        body: jsonEncode(rdvData), 
      );

      if (reponse.statusCode == 201) {
        print("Api service : succès de création");
        return true;
      } else {
        print("api service erreur backend : ${reponse.body}");
        return false;
      }
    } catch (e) {
      print("erreur réseau (rendez-vous): $e");
      return false;
    }
  }
// ================================================================================================================
// MÉTHODES DE RÉCUPÉRATION DE DONNÉES pour le patient  
// ================================================================================================================
 
// -------------------------------Listes des medecins-----------------------------------
  static Future<List<dynamic>> getListeMedecins() async {
    final url = Uri.parse("$baseUrl/listeMedecins/");
    String? token = await getToken();

    try {
      final reponse = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"}, 
      );
      if (reponse.statusCode == 200) {
        return jsonDecode(reponse.body);
      } else {
        print("Erreur de la récupération de médecins");
        return [];
      }
    } catch (e) {
      print("erreur d'affichage médecins : $e ");
      return [];
    }
  }
// -------------------------------Plage d'heure -----------------------------------
  static Future<List<dynamic>> getCreneaux(int medecinId, String date) async {
    final url = Uri.parse("$baseUrl/creneauxDisponible/?medecin=$medecinId&date=$date");
    String? token = await getToken();

    try {
      final reponse = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );
      if (reponse.statusCode == 200) {
        return jsonDecode(reponse.body);
      } else {
        print("Erreur récupération créneaux: ${reponse.body}");
        return [];
      }
    } catch (e) {
      print("Erreur réseau: $e");
      return [];
    }
  }

//-------------------------------Récupérer les RDV du patient connecté-----------------------------------

static Future<List<dynamic>> getMesRendezVous() async {
    String? token = await getToken(); 
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/rendezvous/'), 
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", 
        },
      );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

//-------------------------------Annulez RDV-----------------------------------

  static Future<bool> annulerRendezVous(int id) async {
    String? token = await getToken();
    try {
// On utilise PATCH car on modifie seulement le champ 'statut'
      final response = await http.patch(
        Uri.parse('$baseUrl/rendezvous/$id/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"statut_actuel_rdv": "annulé"}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
// -------------------------------Récupérer Hôpitaux et Pharmacies-----------------------------------
static Future<List<dynamic>> getEtablissements() async {
  String? token = await getToken();
  final url = Uri.parse("$baseUrl/etablissements/");

  try {
    final reponse = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (reponse.statusCode == 200) {
// On décode le JSON 
      return json.decode(utf8.decode(reponse.bodyBytes));
    } else {
      print("Erreur récupération établissements: ${reponse.statusCode}");
      return [];
    }
  } catch (e) {
    print("Erreur réseau (établissements): $e");
    return [];
  }
}
// -------------------------------Rappel traitement-----------------------------------
static Future<List<dynamic>> getNotifications() async {
  String? token = await getToken();
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    return [];
  } catch (e) {
    print("Erreur notifications: $e");
    return [];
  }
}

// -------------------------------les listes traitement-----------------------------------
static Future<List<dynamic>> getTraitements() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access_token');
    
    final response = await http.get(
      Uri.parse('$baseUrl/traitements/'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  } catch (e) {
    print("Erreur getTraitements: $e");
    return [];
  }
}
}