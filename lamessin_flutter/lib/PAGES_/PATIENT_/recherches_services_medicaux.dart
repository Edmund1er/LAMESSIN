import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// Pour l'itinéraire gratuit
import 'package:url_launcher/url_launcher.dart'; 
import '../../SERVICES_/api_service.dart';

class RechercheServicesPage extends StatefulWidget {
  const RechercheServicesPage({super.key});

  @override
  State<RechercheServicesPage> createState() => _RechercheServicesPageState();
}

class _RechercheServicesPageState extends State<RechercheServicesPage> {
  List<dynamic> etablissements = [];
  bool chargement = true;
  String filtreType = "Tous"; 

  @override
  void initState() {
    super.initState();
    _chargerEtTrierParDistance();
  }

  Future<void> _chargerEtTrierParDistance() async {
    try {
      // 1. Obtenir la position du patient
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 2. Récupérer tes données Django
      List<dynamic> data = await ApiService.getEtablissements();

      // 3. Calculer la distance pour chaque point
      for (var e in data) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          double.parse(e['coordonnee_latitude_gps'].toString()),
          double.parse(e['coordonnee_longitude_gps'].toString()),
        );
        e['distance_km'] = distance / 1000; // On convertit en km
      }

      // 4. Trier du plus proche au plus loin
      data.sort((a, b) => a['distance_km'].compareTo(b['distance_km']));

      setState(() {
        etablissements = data;
        chargement = false;
      });
    } catch (e) {
      print("Erreur : $e");
      setState(() => chargement = false);
    }
  }

  // Fonction gratuite pour ouvrir l'itinéraire
  Future<void> _ouvrirItineraire(double lat, double lng) async {
    final url = "google.navigation:q=$lat,$lng&mode=d";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> listeFiltree = filtreType == "Tous"
        ? etablissements
        : etablissements.where((e) => e['type_etablissement'] == filtreType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Santé à proximité"),
        backgroundColor: const Color(0xFF0056b3),
      ),
      body: Column(
        children: [
          // Filtres rapides
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
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
            child: chargement
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: listeFiltree.length,
                    itemBuilder: (context, index) {
                      final e = listeFiltree[index];
                      bool isPharma = e['type_etablissement'] == "Pharmacie";
                      // On vérifie si elle est de garde (champ Django)
                      bool estDeGarde = e['pharmacie_est_garde'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: Icon(
                            isPharma ? Icons.local_pharmacy : Icons.local_hospital,
                            color: isPharma ? Colors.green : Colors.red,
                          ),
                          title: Row(
                            children: [
                              Text(e['nom'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (estDeGarde) 
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                  child: const Text("GARDE", style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                            ],
                          ),
                          subtitle: Text("${e['adresse']}\nÀ ${e['distance_km'].toStringAsFixed(1)} km"),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.directions, color: Color(0xFF0056b3)),
                            onPressed: () => _ouvrirItineraire(
                              double.parse(e['coordonnee_latitude_gps'].toString()),
                              double.parse(e['coordonnee_longitude_gps'].toString()),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}