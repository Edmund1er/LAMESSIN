//pour comvertir les données en json et l'envoie des messages avec le http
import 'dart:convert'; 
import 'package:http/http.dart' as http;

class ApiService 
  {
// Sur l'émulateur Android (Pixel 7), 10.0.2.2 pointe vers moi meme mon ordinateur
    static const String baseUrl = "http://10.0.2.2:8000/api";

//on va declarer la fonction qui envoie les infos et attend une réponse
    static Future<bool> inscription(Map<String, dynamic> data) async 
      {
        try 
          {
// envoie réel du paquet vers Django

            final response = await http.post(
              Uri.parse('$baseUrl/inscription/'),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(data),
            );

            if (response.statusCode == 201) 
              {
                return true;
              } 
            else 
              {
                print("Erreur Django: ${response.body}");
                return false;
              }
          }
        catch (e) 
          {
          print("Erreur de connexion: $e");
          return false;
          }
      }


//la fonction pour se connecter et récupérer le jeton
    static Future<String?> login(String telephone, String password) async 
      {
        try 
          {
            final reponse = await http.post(
              Uri.parse('$baseUrl/login/'), 
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "numero_telephone": telephone,
                "password": password,
                }),
              );

            if (reponse.statusCode == 200) 
              {
                var data = jsonDecode(reponse.body);
                

                print("Connexion réussie .");
                return data['access']; 
              } 
            else 
              {
                print("Erreur de connexion : ${reponse.statusCode} - ${reponse.body}");
                return null;
              }
          } 
        catch (e) 
          {

            print("Erreur lors du login : $e");
            return null;
          }
      }
  }
  