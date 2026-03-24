import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import 'panier_page.dart';

// Importation de ton modèle exact
import '../../MODELS_/medicament_model.dart';
import '../../MODELS_/etablissement_model.dart';

class RechercheServicesPage extends StatefulWidget {
  const RechercheServicesPage({super.key});

  @override
  State<RechercheServicesPage> createState() => _RechercheServicesPageState();
}

class _RechercheServicesPageState extends State<RechercheServicesPage> {
  List<EtablissementSante> etablissements = []; // Typage strict : Liste d'objets EtablissementSante
  bool chargementEtablissements = true;
  String filtreType = "Tous";

  List<Medicament> resultatsMedicaments = [];
  bool rechercheEnCours = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Utilisation de la position pour le calcul de distance
  Position? _currentPosition;

  List<PanierItem> _panier = [];

  @override
  void initState() {
    super.initState();
    _initialiserLocalisationEtDonnees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialiserLocalisationEtDonnees() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Récupération de la position
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Localisation indisponible : $e");
    } finally {
      await _chargerEtTrierEtablissements();
    }
  }

  Future<void> _ouvrirItineraire(double lat, double lng) async {
    final String url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      _afficherSnackBar("Erreur lors de l'ouverture de la carte", Colors.red);
    }
  }

  void _rechercherMedicament(String query) async {
    if (query.length < 2) {
      setState(() => resultatsMedicaments = []);
      return;
    }
    setState(() => rechercheEnCours = true);
    try {
      final List<Medicament> resultats = await ApiService.rechercherMedicaments(query);
      
      // UTILISATION DE _currentPosition : Tri des stocks par proximité si la position est connue
      if (_currentPosition != null) {
        for (var medoc in resultats) {
          // medoc.stocksDisponibles est une List<StockPharmacie>
          medoc.stocksDisponibles.sort((a, b) {
            double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.latitude, a.longitude);
            double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.latitude, b.longitude);
            return distA.compareTo(distB);
          });
        }
      }

      setState(() {
        resultatsMedicaments = resultats;
        rechercheEnCours = false;
      });
    } catch (e) {
      setState(() => rechercheEnCours = false);
    }
  }

  Future<void> _chargerEtTrierEtablissements() async {
    setState(() => chargementEtablissements = true);
    try {
      // ApiService renvoie maintenant une liste d'objets EtablissementSante
      List<EtablissementSante> data = await ApiService.getEtablissements();
      
      // UTILISATION DE _currentPosition : Tri des établissements
      if (_currentPosition != null) {
        data.sort((a, b) {
          // CORRECTION ICI : On utilise les propriétés de l'objet (a.latitude), pas les clés de map
          double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.latitude, a.longitude);
          double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.latitude, b.longitude);
          return distA.compareTo(distB);
        });
      }

      setState(() {
        etablissements = data;
        chargementEtablissements = false;
      });
    } catch (e) {
      setState(() => chargementEtablissements = false);
    }
  }

  void _afficherModalCommande(Medicament medoc, int pharmacieId) {
    int quantite = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(medoc.nomCommercial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Prix : ${medoc.prixVente.toStringAsFixed(0)} FCFA"),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), 
                             onPressed: () => setModalState(() => quantite > 1 ? quantite-- : null)),
                  Text("$quantite", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), 
                             onPressed: () => setModalState(() => quantite++)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () {
                    _ajouterAuPanier(medoc, quantite, pharmacieId);
                    Navigator.pop(context);
                  },
                  child: Text("Ajouter (${(medoc.prixVente * quantite).toStringAsFixed(0)} FCFA)", style: const TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _ajouterAuPanier(Medicament medoc, int qte, int pharmacieId) {
    setState(() {
      int index = _panier.indexWhere((item) => item.idMedoc == medoc.id && item.idPharmacie == pharmacieId);
      if (index != -1) {
        _panier[index].quantite += qte;
      } else {
        _panier.add(PanierItem(
          idMedoc: medoc.id,
          idPharmacie: pharmacieId,
          nom: medoc.nomCommercial,
          prix: medoc.prixVente,
          quantite: qte,
        ));
      }
    });
    _afficherSnackBar("${medoc.nomCommercial} ajouté au panier", Colors.green);
  }

  void _afficherSnackBar(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Services Médicaux"),
        backgroundColor: const Color(0xFF0056b3),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: _panier.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PanierPage(items: _panier))).then((_) => setState(() {})),
              label: Text("Panier (${_panier.length})"),
              icon: const Icon(Icons.shopping_cart),
              backgroundColor: Colors.green,
            )
          : null,
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
            child: _searchController.text.isNotEmpty ? _buildResultatsMedicaments() : _buildListeEtablissements(),
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
          child: ExpansionTile(
            leading: Icon(Icons.medication, color: medoc.stocksDisponibles.isNotEmpty ? Colors.blue : Colors.red),
            title: Text(medoc.nomCommercial, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${medoc.prixVente.toStringAsFixed(0)} FCFA"),
            children: medoc.stocksDisponibles.map((s) {
              // Calcul de la distance pour l'affichage
              String distanceText = "";
              if (_currentPosition != null) {
                double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, s.latitude, s.longitude);
                distanceText = " - ${(dist / 1000).toStringAsFixed(1)} km";
              }

              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: Text(s.nomPharmacie),
                subtitle: Text("En stock: ${s.quantiteEnStock}$distanceText"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.directions, color: Colors.blue),
                      onPressed: () => _ouvrirItineraire(s.latitude, s.longitude),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_shopping_cart, color: Colors.green), 
                      onPressed: () => _afficherModalCommande(medoc, s.idPharmacie),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildListeEtablissements() {
    if (chargementEtablissements) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: etablissements.length,
      itemBuilder: (context, index) {
        final e = etablissements[index];
        
        // CORRECTION ICI : On utilise les propriétés directes de l'objet e (qui est un EtablissementSante)
        // et non plus e['coordonnee_latitude_gps']
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(e.pharmacieEstGarde == true ? Icons.local_pharmacy : Icons.local_hospital),
            title: Text(e.nom),
            subtitle: Text("Adresse: ${e.adresse}"),
            trailing: IconButton(
              icon: const Icon(Icons.directions, color: Colors.green),
              onPressed: () => _ouvrirItineraire(e.latitude, e.longitude),
            ),
          ),
        );
      },
    );
  }
}