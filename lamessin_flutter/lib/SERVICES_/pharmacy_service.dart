import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports des modèles necessaires
import '../MODELS_/medicament_model.dart';
import '../MODELS_/commande_model.dart';
import '../MODELS_/ordonnance_model.dart';
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/statistiques_pharmacien_model.dart';

class PharmacyService {
  // Url de base de l'API
  static String get _baseUrl => ApiService.baseUrl;

  // Headers avec token d'authentification
  static Future<Map<String, String>> get _headers => ApiService.getHeaders();

  // ==================== 1. TABLEAU DE BORD ====================

  // Recupere les statistiques pour le dashboard du pharmacien
  static Future<StatistiquesPharmacien?> getDashboard() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/dashboard/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return StatistiquesPharmacien.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getDashboard: $e");
      return null;
    }
  }

  // Recupere les statistiques detaillees de la pharmacie
  static Future<Map<String, dynamic>?> getStatistiques() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/statistiques/'),
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

  // ==================== 2. GESTION DES STOCKS ====================

  // Recupere la liste de tous les stocks de la pharmacie
  static Future<List<StockPharmacie>> getStocks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/stocks/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => StockPharmacie.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getStocks: $e");
      return [];
    }
  }

  // Met a jour la quantite d'un produit en stock
  static Future<bool> updateStock(int stockId, int quantite) async {
    try {
      debugPrint("updateStock - ID: $stockId, Quantite: $quantite");
      final response = await http.patch(
        Uri.parse('${ApiService.baseUrl}/pharmacien/stocks/$stockId/'),
        headers: await ApiService.getHeaders(),
        body: jsonEncode({'quantite': quantite}),
      );
      debugPrint("updateStock - Status: ${response.statusCode}");
      if (response.statusCode != 200) {
        debugPrint("updateStock - Response: ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur updateStock: $e");
      return false;
    }
  }

// Recupere les alertes de stock (produits sous seuil d'alerte)
static Future<List<StockPharmacie>> getAlertesStock() async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/pharmacien/stocks/alertes/'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => StockPharmacie.fromJson(item)).toList();
    }
    return [];
  } catch (e) {
    debugPrint("Erreur getAlertesStock: $e");
    return [];
  }
}

  // Ajoute ou met a jour un stock pour un medicament
  static Future<bool> ajouterOuUpdateStock({
    required int medicamentId,
    required int quantite,
    int seuilAlerte = 10,
    required String datePeremption,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacien/stocks/'),
        headers: await _headers,
        body: jsonEncode({
          'medicament_id': medicamentId,
          'quantite': quantite,
          'seuil_alerte': seuilAlerte,
          'date_peremption': datePeremption,
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Erreur ajouterOuUpdateStock: $e");
      return false;
    }
  }

  // ==================== 3. GESTION DES COMMANDES ====================

  // Recupere toutes les commandes concernant cette pharmacie
  // filtre: 'toutes', 'en_attente', 'payees'
  static Future<List<Commande>> getCommandes({String filtre = 'toutes'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/commandes/?filtre=$filtre'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Commande.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getCommandes: $e");
      return [];
    }
  }

  // Recupere les details d'une commande specifique
  static Future<Commande?> getCommandeDetails(int commandeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/commandes/$commandeId/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return Commande.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur getCommandeDetails: $e");
      return null;
    }
  }

  // Valide une commande (preparation terminee)
  static Future<bool> validerCommande(int commandeId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacien/commandes/$commandeId/valider/'),
        headers: await _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur validerCommande: $e");
      return false;
    }
  }

  // ==================== 4. GESTION DES MÉDICAMENTS ====================

  // Recupere le catalogue complet des medicaments
  static Future<List<Medicament>> getCatalogueMedicaments() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/medicaments/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((item) => Medicament.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Erreur getCatalogueMedicaments: $e");
      return [];
    }
  }

  // Ajoute un nouveau medicament au catalogue
  static Future<Medicament?> ajouterMedicament({
    required String nom,
    required String description,
    required String posologie,
    required double prix,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacien/medicaments/ajouter/'),
        headers: await _headers,
        body: jsonEncode({
          'nom': nom,
          'description': description,
          'posologie': posologie,
          'prix': prix,
        }),
      );

      if (response.statusCode == 201) {
        return Medicament.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur ajouterMedicament: $e");
      return null;
    }
  }

  // Modifie un medicament existant
  static Future<Medicament?> modifierMedicament({
    required int medicamentId,
    String? nom,
    String? description,
    String? posologie,
    double? prix,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/pharmacien/medicaments/$medicamentId/modifier/'),
        headers: await _headers,
        body: jsonEncode({
          'nom': nom,
          'description': description,
          'posologie': posologie,
          'prix': prix,
        }),
      );

      if (response.statusCode == 200) {
        return Medicament.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint("Erreur modifierMedicament: $e");
      return null;
    }
  }

  // ==================== 5. SCAN D'ORDONNANCE ====================

  // Scanne une ordonnance par son code de securite
  static Future<Map<String, dynamic>?> scannerOrdonnance(
    String codeSecurite,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/pharmacien/ordonnance/scanner/$codeSecurite/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur scannerOrdonnance: $e");
      return null;
    }
  }

  // Valide une ordonnance et prepare les medicaments
  static Future<Map<String, dynamic>?> validerOrdonnance(
    int ordonnanceId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pharmacien/ordonnance/$ordonnanceId/valider/'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Erreur validerOrdonnance: $e");
      return null;
    }
  }

  // Marque une commande comme livree (statut LIVRE)
  static Future<bool> marquerCommandeLivree(int commandeId) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiService.baseUrl}/pharmacien/commandes/$commandeId/livrer/',
        ),
        headers: await ApiService.getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur marquerCommandeLivree: $e");
      return false;
    }
  }
  // Recupere les commandes avec un filtre specifique
static Future<List<Commande>> getCommandesParStatut(String statut) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/pharmacien/commandes/?statut=$statut'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = json.decode(utf8.decode(response.bodyBytes));
      return data.map((item) => Commande.fromJson(item)).toList();
    }
    return [];
  } catch (e) {
    debugPrint("Erreur getCommandesParStatut: $e");
    return [];
  }
}

// Supprimer un stock
static Future<bool> supprimerStock(int stockId) async {
  try {
    final response = await http.delete(
      Uri.parse('$_baseUrl/pharmacien/stocks/$stockId/supprimer/'),  // Ajouter /supprimer/
      headers: await _headers,
    );
    return response.statusCode == 204 || response.statusCode == 200;
  } catch (e) {
    debugPrint("Erreur supprimerStock: $e");
    return false;
  }
}
}
