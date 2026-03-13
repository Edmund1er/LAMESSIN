import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import 'panier_page.dart';

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
  Position? _currentPosition;

  List<PanierItem> _panier = [];

  @override
  void initState() {
    super.initState();
    _initialiserLocalisationEtDonnees();
  }

  // --- INITIALISATION SÉCURISÉE ---
  Future<void> _initialiserLocalisationEtDonnees() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Localisation indisponible (normal sur Edge/Web) : $e");
    } finally {
      await _chargerEtTrierEtablissements();
    }
  }

  // --- GOOGLE MAPS ---
  Future<void> _ouvrirItineraire(double lat, double lng) async {
    final String url = "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving";
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

  // --- RECHERCHE MÉDICAMENTS ---
  void _rechercherMedicament(String query) async {
    if (query.length < 2) {
      setState(() => resultatsMedicaments = []);
      return;
    }
    setState(() => rechercheEnCours = true);
    
    try {
      final resultats = await ApiService.rechercherMedicaments(query);

      for (var medoc in resultats) {
        List<dynamic> stocks = medoc['stocks_disponibles'] ?? [];
        for (var s in stocks) {
          if (_currentPosition != null && s['latitude'] != null && s['longitude'] != null) {
            double dist = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                double.tryParse(s['latitude'].toString()) ?? 0.0,
                double.tryParse(s['longitude'].toString()) ?? 0.0);
            s['distance_km'] = dist / 1000;
          } else {
            s['distance_km'] = null;
          }
        }
        stocks.sort((a, b) => (a['distance_km'] ?? 999.0).compareTo(b['distance_km'] ?? 999.0));
      }

      setState(() {
        resultatsMedicaments = resultats;
        rechercheEnCours = false;
      });
    } catch (e) {
      debugPrint("Erreur recherche : $e");
      setState(() => rechercheEnCours = false);
    }
  }

  // --- CHARGEMENT ÉTABLISSEMENTS ---
  Future<void> _chargerEtTrierEtablissements() async {
    setState(() => chargementEtablissements = true);
    try {
      List<dynamic> data = await ApiService.getEtablissements();
      
      for (var e in data) {
        if (_currentPosition != null && e['coordonnee_latitude_gps'] != null) {
          try {
            double dist = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                double.parse(e['coordonnee_latitude_gps'].toString()),
                double.parse(e['coordonnee_longitude_gps'].toString()));
            e['distance_km'] = dist / 1000;
          } catch (err) { e['distance_km'] = null; }
        } else {
          e['distance_km'] = null;
        }
      }
      data.sort((a, b) => (a['distance_km'] ?? 999.0).compareTo(b['distance_km'] ?? 999.0));

      setState(() {
        etablissements = data;
        chargementEtablissements = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement : $e");
      setState(() => chargementEtablissements = false);
    }
  }

  // --- MODAL COMMANDE ---
  void _afficherModalCommande(dynamic medoc, int pharmacieId) {
    int quantite = 1;
    double prixUnitaire = double.tryParse(medoc['prix_vente']?.toString() ?? '0') ?? 0.0;

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
              Text(medoc['nom_commercial'] ?? "Médicament", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Prix : ${prixUnitaire.toStringAsFixed(0)} FCFA"),
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
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler"))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () {
                      _ajouterAuPanier(medoc, quantite, pharmacieId);
                      Navigator.pop(context);
                    },
                    child: Text("Ajouter (${(prixUnitaire * quantite).toStringAsFixed(0)} FCFA)", style: const TextStyle(color: Colors.white)),
                  )),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

void _ajouterAuPanier(dynamic medoc, int qte, int pharmacieId) {
    debugPrint("Tentative d'ajout : Medoc ${medoc['id']} de la Pharmacie $pharmacieId");
    
    setState(() {
      double prixVrai = double.tryParse(medoc['prix_vente']?.toString() ?? '0') ?? 0.0;
      
      // Recherche si le produit existe déjà pour CETTE pharmacie précise
      int index = _panier.indexWhere((item) => 
        item.idMedoc == medoc['id'] && item.idPharmacie == pharmacieId);

      if (index != -1) {
        _panier[index].quantite += qte;
        debugPrint("Quantité mise à jour : ${_panier[index].quantite}");
      } else {
        _panier.add(PanierItem(
          idMedoc: medoc['id'],
          idPharmacie: pharmacieId,
          nom: medoc['nom_commercial'] ?? "Médicament",
          prix: prixVrai,
          quantite: qte,
        ));
        debugPrint("Nouvel article ajouté au panier. Taille du panier : ${_panier.length}");
      }
    });
    
    _afficherSnackBar("${medoc['nom_commercial']} ajouté au panier", Colors.green);
  }

  void _afficherSnackBar(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> listeFiltree = filtreType == "Tous"
        ? etablissements
        : etablissements.where((e) {
            String typeData = e['type_etablissement'].toString().toLowerCase().replaceAll('ô', 'o');
            String typeBouton = filtreType.toLowerCase().replaceAll('ô', 'o');
            return typeData == typeBouton;
          }).toList();

    return Scaffold(
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("LAMESSIN - Services"),
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
            child: _searchController.text.isNotEmpty ? _buildResultatsMedicaments() : _buildListeEtablissements(listeFiltree),
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
        final stocks = medoc['stocks_disponibles'] as List<dynamic>? ?? [];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ExpansionTile(
            leading: Icon(Icons.medication, color: stocks.isNotEmpty ? Colors.blue : Colors.red),
            title: Text(medoc['nom_commercial'] ?? "Inconnu", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${medoc['prix_vente']} FCFA"),
            children: stocks.map((s) {
              double? dist = s['distance_km'];
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.green),
                title: Text(s['nom_pharmacie'] ?? "Pharmacie"),
                subtitle: Text("${dist?.toStringAsFixed(1) ?? '?'} km"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      
                      icon: const Icon(Icons.directions, color: Colors.blue),
                      onPressed: () => _ouvrirItineraire(
                        double.parse(s['latitude'].toString()), 
                        double.parse(s['longitude'].toString())
                      ),
                    ),
                    IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.green), 
                          onPressed: () {
                            if (s['id_pharmacie'] != null) {
                              _afficherModalCommande(medoc, s['id_pharmacie']);
                            } else {
                              debugPrint("ERREUR : id_pharmacie est nul dans les données JSON !");
                              _afficherSnackBar("Erreur de données pharmacie", Colors.red);
                            }
                          },
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

  Widget _buildListeEtablissements(List<dynamic> listeFiltree) {
    if (chargementEtablissements) return const Center(child: CircularProgressIndicator());
    if (listeFiltree.isEmpty) return const Center(child: Text("Connectez-vous pour voir les établissements."));

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: ["Tous", "Pharmacie", "Hôpital"].map((type) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(type),
                selected: filtreType == type,
                onSelected: (val) => setState(() => filtreType = type),
              ),
            )).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: listeFiltree.length,
            itemBuilder: (context, index) {
              final e = listeFiltree[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(e['type_etablissement'] == "Pharmacie" ? Icons.local_pharmacy : Icons.local_hospital, 
                                color: e['type_etablissement'] == "Pharmacie" ? Colors.blue : Colors.red),
                  title: Text(e['nom'] ?? "Nom inconnu", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${e['distance_km']?.toStringAsFixed(1) ?? '...'} km - ${e['plage_horaire_ouverture'] ?? '24h/24'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.directions, color: Colors.green), 
                    onPressed: () => _ouvrirItineraire(
                      double.parse(e['coordonnee_latitude_gps'].toString()), 
                      double.parse(e['coordonnee_longitude_gps'].toString())
                    )
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