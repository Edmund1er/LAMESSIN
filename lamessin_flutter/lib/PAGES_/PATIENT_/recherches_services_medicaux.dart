import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';

class RechercheServicesPage extends StatefulWidget {
  const RechercheServicesPage({super.key});

  @override
  State<RechercheServicesPage> createState() => _RechercheServicesPageState();
}

class _RechercheServicesPageState extends State<RechercheServicesPage> {
  List<dynamic> etablissements = [];
  bool chargementEtablissements = true;
  String filtreType = "Tous"; 

  List<dynamic> resultatsMedicaments = [];
  bool rechercheEnCours = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerEtTrierParDistance();
  }

  // --- LOGIQUE COMMANDE & PAIEMENT DIRECT (CORRIGÉ) ---
  void _afficherModalCommande(dynamic medoc) {
    int quantite = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(medoc['nom_commercial'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Prix unitaire: ${medoc['prix_vente']} FCFA", style: const TextStyle(color: Colors.grey)),
                  const Divider(),
                  const Text("Quantité souhaitée :"),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => setModalState(() => quantite > 1 ? quantite-- : null),
                      ),
                      Text("$quantite", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => setModalState(() => quantite++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      onPressed: () => _validerAchat(medoc['id'], quantite),
                      child: Text("Payer maintenant (${medoc['prix_vente'] * quantite} FCFA)", 
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _validerAchat(int idMedoc, int qte) async {
    Navigator.pop(context); // Fermer le modal
    setState(() => rechercheEnCours = true);

    // On utilise la fonction qui crée la commande ET récupère le lien FedaPay
    final resultat = await ApiService.creerCommandeEtPayer(idMedoc, qte);

    if (resultat != null && resultat['payment_url'] != null) {
      final Uri uri = Uri.parse(resultat['payment_url']);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Redirection vers la liste des commandes pour voir le statut
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/mes_commandes');
        }
      } else {
        _afficherSnackBar("Impossible d'ouvrir le lien de paiement", Colors.red);
      }
    } else {
      _afficherSnackBar("Erreur lors de l'initialisation du paiement", Colors.red);
    }
    setState(() => rechercheEnCours = false);
  }

  void _afficherSnackBar(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  // --- LOGIQUE GÉOLOCALISATION & RECHERCHE ---
  Future<void> _chargerEtTrierParDistance() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<dynamic> data = await ApiService.getEtablissements();
      for (var e in data) {
        double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude, 
          double.parse(e['coordonnee_latitude_gps'].toString()), 
          double.parse(e['coordonnee_longitude_gps'].toString())
        );
        e['distance_km'] = distance / 1000;
      }
      data.sort((a, b) => a['distance_km'].compareTo(b['distance_km']));
      setState(() { etablissements = data; chargementEtablissements = false; });
    } catch (e) {
      setState(() => chargementEtablissements = false);
    }
  }

  Future<void> _ouvrirItineraire(double lat, double lng) async {
    final url = "google.navigation:q=$lat,$lng&mode=d";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) { await launchUrl(uri); }
  }

  void _rechercherMedicament(String query) async {
    if (query.isEmpty) { setState(() => resultatsMedicaments = []); return; }
    setState(() => rechercheEnCours = true);
    final resultats = await ApiService.rechercherMedicaments(query);
    setState(() { resultatsMedicaments = resultats; rechercheEnCours = false; });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> listeFiltree = filtreType == "Tous" 
        ? etablissements 
        : etablissements.where((e) => e['type_etablissement'] == filtreType).toList();

    return Scaffold(
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Services Médicaux"), 
        backgroundColor: const Color(0xFF0056b3),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0056b3),
            child: TextField(
              controller: _searchController,
              onChanged: _rechercherMedicament,
              decoration: InputDecoration(
                hintText: "Rechercher un médicament...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _searchController.text.isNotEmpty 
              ? _buildResultatsMedicaments() 
              : _buildListeEtablissements(listeFiltree),
          ),
        ],
      ),
    );
  }

  Widget _buildResultatsMedicaments() {
    if (rechercheEnCours) return const Center(child: CircularProgressIndicator());
    if (resultatsMedicaments.isEmpty) return const Center(child: Text("Aucun résultat."));

    return ListView.builder(
      itemCount: resultatsMedicaments.length,
      itemBuilder: (context, index) {
        final medoc = resultatsMedicaments[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.medication, color: Colors.blue),
            title: Text(medoc['nom_commercial'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${medoc['prix_vente']} FCFA"),
            trailing: const Icon(Icons.add_shopping_cart, color: Colors.green),
            onTap: () => _afficherModalCommande(medoc),
          ),
        );
      },
    );
  }

  Widget _buildListeEtablissements(List<dynamic> listeFiltree) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Row(
            children: ["Tous", "Pharmacie", "Hôpital"].map((type) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(type),
                  selected: filtreType == type,
                  onSelected: (val) => setState(() => filtreType = type),
                  selectedColor: const Color(0xFF0056b3),
                  labelStyle: TextStyle(color: filtreType == type ? Colors.white : Colors.black),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: chargementEtablissements
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: listeFiltree.length,
                itemBuilder: (context, index) {
                  final e = listeFiltree[index];
                  bool isPharma = e['type_etablissement'] == "Pharmacie";
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: Icon(isPharma ? Icons.local_pharmacy : Icons.local_hospital, color: isPharma ? Colors.green : Colors.red),
                      title: Text(e['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${e['adresse']}\n${e['distance_km'].toStringAsFixed(1)} km"),
                      trailing: IconButton(
                        icon: const Icon(Icons.directions, color: Color(0xFF0056b3)), 
                        onPressed: () => _ouvrirItineraire(double.parse(e['coordonnee_latitude_gps'].toString()), double.parse(e['coordonnee_longitude_gps'].toString()))
                      ),
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}