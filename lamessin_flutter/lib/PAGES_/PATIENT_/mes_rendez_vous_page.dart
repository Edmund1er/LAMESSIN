import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';

// IMPORTATION DE TES MODÈLES UNIQUEMENT
import '../../MODELS_/rendezvous_model.dart';
import '../../MODELS_/utilisateur_model.dart';


class MesRendezVousPage extends StatefulWidget {
  const MesRendezVousPage({super.key});

  @override
  State<MesRendezVousPage> createState() => _MesRendezVousPageState();
}

class _MesRendezVousPageState extends State<MesRendezVousPage> {
  // Utilisation du modèle RendezVous défini dans ton fichier
  List<RendezVous> _tousMesRDV = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _recupererRendezVous();
  }

  Future<void> _recupererRendezVous() async {
    setState(() => _chargement = true);
    try {
      // ApiService doit retourner une List<RendezVous> via RendezVous.fromJson
      final List<RendezVous> data = await ApiService.getMesRendezVous();
      setState(() {
        _tousMesRDV = data;
        _chargement = false;
      });
    } catch (e) {
      setState(() => _chargement = false);
      _afficherMessage("Erreur de récupération", Colors.red);
    }
  }

  Future<void> _annulerRDV(int id) async {
    bool succes = await ApiService.annulerRendezVous(id);
    if (succes) {
      _afficherMessage("Rendez-vous annulé", Colors.orange);
      _recupererRendezVous();
    } else {
      _afficherMessage("Erreur lors de l'annulation", Colors.red);
    }
  }

  List<RendezVous> get _rdvFuturs {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      // Utilisation des propriétés dateRdv et statutActuelRdv de ton modèle
      DateTime dateRdv = DateTime.parse(rdv.dateRdv);
      return dateRdv.isAfter(now.subtract(const Duration(days: 1))) && rdv.statutActuelRdv != 'annulé';
    }).toList();
  }

  List<RendezVous> get _rdvPassesOuAnnules {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime dateRdv = DateTime.parse(rdv.dateRdv);
      return dateRdv.isBefore(now) || rdv.statutActuelRdv == 'annulé';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],
        drawer: const MenuNavigation(),
        appBar: AppBar(
          title: const Text("Mes Rendez-vous", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.blueAccent,
          elevation: 2,
          bottom: const TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            tabs: [
              Tab(text: "À venir", icon: Icon(Icons.calendar_today)),
              Tab(text: "Historique", icon: Icon(Icons.history)),
            ],
          ),
        ),
        body: _chargement 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _buildListeVue(_rdvFuturs, estAncien: false),
                _buildListeVue(_rdvPassesOuAnnules, estAncien: true),
              ],
            ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.pushNamed(context, '/rendez_vous_page'), 
          label: const Text("Prendre rendez-vous", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: const Color.fromARGB(255, 78, 192, 17),
        ),
      ),
    );
  }

  Widget _buildListeVue(List<RendezVous> liste, {required bool estAncien}) {
    if (liste.isEmpty) return _buildEmptyState(estAncien);
    return RefreshIndicator(
      onRefresh: _recupererRendezVous,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 90),
        itemCount: liste.length,
        itemBuilder: (context, index) => _buildRDVCard(liste[index], grise: estAncien),
      ),
    );
  }

  Widget _buildRDVCard(RendezVous rdv, {bool grise = false}) {
    // medecinConcerne est un objet Medecin? dans ton modèle
    // On accède au nom via compteUtilisateur.lastName comme défini dans utilisateur_model.dart
    final String nomMedecin = rdv.medecinConcerne?.compteUtilisateur.lastName ?? "Médecin";
    final String specialite = rdv.medecinConcerne?.specialiteMedicale ?? "Généraliste";

    return Opacity(
      opacity: grise ? 0.7 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
              title: Text("Dr $nomMedecin", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(specialite),
              trailing: _buildStatusBadge(rdv.statutActuelRdv),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey), 
                    const SizedBox(width: 5), 
                    Text("${rdv.dateRdv} à ${rdv.heureRdv}")
                  ]),
                  if (!grise && rdv.statutActuelRdv != 'annulé') 
                    TextButton.icon(
                      onPressed: () => _confirmerAnnulation(rdv.id), 
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 18), 
                      label: const Text("Annuler", style: TextStyle(color: Colors.red))
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerAnnulation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Annuler le rendez-vous ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Retour")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red), 
            onPressed: () { Navigator.pop(context); _annulerRDV(id); }, 
            child: const Text("Confirmer l'annulation", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool estAncien) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          Icon(estAncien ? Icons.folder_open : Icons.event_busy, size: 60, color: Colors.grey), 
          const SizedBox(height: 10), 
          Text(estAncien ? "Historique vide" : "Aucun rendez-vous à venir")
        ]
      )
    );
  }

  Widget _buildStatusBadge(String statut) {
    Color color;
    switch (statut.toLowerCase()) {
      case 'confirmé':
      case 'validé':
        color = Colors.green;
        break;
      case 'annulé':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), 
      child: Text(statut.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))
    );
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: couleur));
  }
}