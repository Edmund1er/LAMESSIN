// SERVICES_/payment_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PaymentService {
  
  static String get _baseUrl => ApiService.baseUrl;
  static Future<Map<String, String>> get _headers => ApiService.getHeaders();

  /// Initier un paiement mobile money
  static Future<Map<String, dynamic>?> initierPaiementMobileMoney({
    required int commandeId,
    required String telephone,
    required String operateur, // 'FLOOZ' ou 'TMONEY'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/paiement/initier/'),
        headers: await _headers,
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

  /// Vérifier le statut d'un paiement
  static Future<Map<String, dynamic>?> verifierStatutPaiement(int commandeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/paiement/verifier/$commandeId/'),
        headers: await _headers,
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
}