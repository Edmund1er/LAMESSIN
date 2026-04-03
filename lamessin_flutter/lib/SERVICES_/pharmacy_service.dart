import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// Imports de modèles
import '../MODELS_/medicament_model.dart';
import '../MODELS_/commande_model.dart';
import '../MODELS_/ordonnance_model.dart';
import '../MODELS_/utilisateur_model.dart';
import '../MODELS_/statistiques_pharmacien_model.dart';

class PharmacyService {
  
  // ==================== BASE URL ====================
  static String get _baseUrl => ApiService.baseUrl;
  static Future<Map<String, String>> get _headers => ApiService.getHeaders();

  // ==================== 1. TABLEAU DE BORD ====================
  
  /// Récupère les statistiques du tableau de bord pharmacien
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

  /// Récupère les statistiques détaillées de la pharmacie
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

  /// Récupère tous les stocks de la pharmacie
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

  /// Met à jour la quantité d'un stock
  static Future<bool> updateStock(int stockId, int quantite) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/pharmacien/stocks/$stockId/'),
        headers: await _headers,
        body: jsonEncode({'quantite': quantite}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Erreur updateStock: $e");
      return false;
    }
  }

  /// Récupère les alertes de stock (produits sous seuil)
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

  /// Ajoute ou met à jour un stock pour un médicament
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

  /// Récupère toutes les commandes concernant la pharmacie
  /// [filtre] : 'toutes', 'en_attente', 'payees'
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

  /// Récupère les détails d'une commande
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

  /// Valide une commande (préparation terminée)
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

  /// Récupère le catalogue complet des médicaments
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

  /// Ajoute un nouveau médicament
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

  /// Modifie un médicament existant
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

  /// Scanne une ordonnance par son code de sécurité
  static Future<Map<String, dynamic>?> scannerOrdonnance(String codeSecurite) async {
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

  /// Valide une ordonnance et prépare les médicaments
  static Future<Map<String, dynamic>?> validerOrdonnance(int ordonnanceId) async {
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
}