//pour comvertir les données en json et l'envoie des messages avec le http
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiService {
  // Détecte automatiquement l'URL backend selon la plateforme
  static String get baseUrl 
    {
      if (kIsWeb) return "http://127.0.0.1:8000/api";       // Web
      if (Platform.isAndroid) return "http://10.0.2.2:8000/api"; // Android émulateur
      if (Platform.isIOS) return "http://localhost:8000/api";    // iOS émulateur
      return "http://127.0.0.1:8000/api";                      // fallback
    }
  static Future<bool> inscription(Map<String, dynamic> data) async {
    try {
      // envoie réel du paquet vers Django

      final response = await http.post(
        Uri.parse('${baseUrl}/inscription/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Erreur Django: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Erreur de connexion: $e");
      return false;
    }
  }

  //la fonction pour se connecter et récupérer le jeton
  static Future<String?> login(String telephone, String password) async {
    try {
      final reponse = await http.post(
        Uri.parse('${baseUrl}/login/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"numero_telephone": telephone, "password": password}),
      );

      if (reponse.statusCode == 200) {
        var data = jsonDecode(reponse.body);

        print("Connexion réussie .");
        return data['access'];
      } else {
        print("Erreur de connexion : ${reponse.statusCode} - ${reponse.body}");
        return null;
      }
    } catch (e) {
      print("Erreur lors du login : $e");
      return null;
    }
  }
// ---------------------------------------------------------------------------
  // MÉTHODES DE GESTION DES RENDEZ-VOUS
  // ---------------------------------------------------------------------------

  static Future<bool> creerRendezVous(Map<String, dynamic>rdvData) async {

//construisons  l'url 
    final url = Uri.parse("${baseUrl}/rendezvous/");

    try
      {
// on dit au serveur qu'on envoie du json eserialisation du dictionnaire la map quoi en chaine de caractere
        final reponse  = await http.post(url,
        headers : {"content-Type" : "application/json"},
        body : jsonEncode(rdvData),
        );
// pour confirmer que django a inserer les données recues
        if(reponse.statusCode == 201)
          {
            print("Api service : succes de creation");
            return true ;
          }
        else
//si on  a une erreur on affiche l'erreur rencotrer dans django
        {
            print("api service erreur backend : ${reponse.body}");
            return false ;
        }

      }
    catch (e)
    {
      print("erreur reseau (rendez-vous): $e");
      return false;
    }
  }
// ---------------------------------------------------------------------------
// MÉTHODES DE RÉCUPÉRATION DE DONNÉES
// ---------------------------------------------------------------------------
 
 static Future <List<dynamic>>getListeMedecins()async
  {
    final url = Uri.parse("${baseUrl}/listeMedecins/");

    try
      {
        final reponse =  await http.get(url);
        if (reponse.statusCode==200)
          {
          return jsonDecode(reponse.body);
          }
        else
          {
            print("Erreur de la recuperation de medecins");
            return [];
          }
      }
    catch (e)
      {
        print("erreur d'affichage medecins : $e ");
        return [];
      }
  }

// ---------------------------------------------------------------------------
// creneau  
// ---------------------------------------------------------------------------
static Future<List<dynamic>> getCreneaux(int medecinId, String date) async {
  final url = Uri.parse("${baseUrl}/creneaux-disponibles/?medecin=$medecinId&date=$date");
  final response = await http.get(url);
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  return [];
}
}