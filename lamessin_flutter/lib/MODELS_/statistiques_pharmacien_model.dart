import 'commande_model.dart';

class StatistiquesPharmacien {
  final int totalProduits;
  final int produitsEnRupture;
  final int produitsAlerte;
  final int commandesAttente;
  final int commandesTotal;
  final double caTotal;
  final List<Commande> commandesRecentes;
  final List<Map<String, dynamic>> ventesParMois;
  final List<Map<String, dynamic>> topMedicaments;

  StatistiquesPharmacien({
    required this.totalProduits,
    required this.produitsEnRupture,
    required this.produitsAlerte,
    required this.commandesAttente,
    required this.commandesTotal,
    required this.caTotal,
    required this.commandesRecentes,
    required this.ventesParMois,
    required this.topMedicaments,
  });

  factory StatistiquesPharmacien.fromJson(Map<String, dynamic> json) {
    return StatistiquesPharmacien(
      totalProduits: json['total_produits'] ?? 0,
      produitsEnRupture: json['produits_en_rupture'] ?? 0,
      produitsAlerte: json['produits_alerte'] ?? 0,
      commandesAttente: json['commandes_attente'] ?? 0,
      commandesTotal: json['commandes_total'] ?? 0,
      caTotal: (json['ca_total'] ?? 0).toDouble(),
      commandesRecentes: (json['commandes_recentes'] as List?)
          ?.map((e) => Commande.fromJson(e))
          .toList() ?? [],
      ventesParMois: (json['ventes_par_mois'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
      topMedicaments: (json['top_medicaments'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e))
          .toList() ?? [],
    );
  }
}