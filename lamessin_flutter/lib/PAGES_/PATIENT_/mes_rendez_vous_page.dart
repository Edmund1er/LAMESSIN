import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class MesRendezVousPage extends StatefulWidget {
  const MesRendezVousPage({super.key});

  @override
  State<MesRendezVousPage> createState() => _MesRendezVousPageState();
}

class _MesRendezVousPageState extends State<MesRendezVousPage> {
  List<dynamic> _tousMesRDV = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _recupererRendezVous();
  }

  // --- LOGIQUE API ---
  Future<void> _recupererRendezVous() async {
    setState(() => _chargement = true);
    final data = await ApiService.getMesRendezVous();
    setState(() {
      _tousMesRDV = data;
      _chargement = false;
    });
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

  // --- FILTRES ---
  List<dynamic> get _rdvFuturs {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime dateRdv = DateTime.parse(rdv['date_rdv']);
      // On garde ce qui est aujourd'hui ou dans le futur et non annulé
      return dateRdv.isAfter(now.subtract(const Duration(days: 1))) && 
             rdv['statut_actuel_rdv'] != 'annulé';
    }).toList();
  }

  List<dynamic> get _rdvPassesOuAnnules {
    DateTime now = DateTime.now();
    return _tousMesRDV.where((rdv) {
      DateTime dateRdv = DateTime.parse(rdv['date_rdv']);
      return dateRdv.isBefore(now) || rdv['statut_actuel_rdv'] == 'annulé';
    }).toList();
  }

  // --- INTERFACE ---
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.blueGrey[50],
        appBar: AppBar(
          // LA PETITE MAISON POUR REVENIR AU DASHBOARD
          leading: IconButton(
            icon: const Icon(Icons.home_rounded, size: 28),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/page_utilisateur', (route) => false),
          ),
          title: const Text("Mes Rendez-vous", 
            style: TextStyle(fontWeight: FontWeight.bold)),
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
        
// --- TON BOUTON VERT POUR PRENDRE RENDEZ-VOUS ---
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/rendez_vous_page'); 
          },
          label: const Text("Prendre rendez-vous", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          icon: const Icon(Icons.add, color: Colors.white),
          backgroundColor: const Color.fromARGB(255, 78, 192, 17), // Ton vert
        ),
      ),
    );
  }

  Widget _buildListeVue(List<dynamic> liste, {required bool estAncien}) {
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

  Widget _buildRDVCard(dynamic rdv, {bool grise = false}) {
    // On récupère les infos du médecin selon tes modèles Django
    final medecin = rdv['medecin_concerne']['compte_utilisateur'];
    final specialite = rdv['medecin_concerne']['specialite_medicale'];
    
    return Opacity(
      opacity: grise ? 0.7 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text("Dr ${medecin['last_name']}", 
                style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(specialite),
              trailing: _buildStatusBadge(rdv['statut_actuel_rdv']),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text("${rdv['date_rdv']} à ${rdv['heure_rdv']}"),
                    ],
                  ),
                  if (!grise && rdv['statut_actuel_rdv'] != 'annulé') 
                    TextButton.icon(
                      onPressed: () => _confirmerAnnulation(rdv['id']),
                      icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                      label: const Text("Annuler", style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOGUES ET MESSAGES ---

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
            onPressed: () {
              Navigator.pop(context);
              _annulerRDV(id);
            },
            child: const Text("Confirmer l'annulation", style: TextStyle(color: Colors.white)),
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
          Text(estAncien ? "Historique vide" : "Aucun rendez-vous à venir"),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String statut) {
    Color color = (statut == 'confirmé' || statut == 'validé') 
        ? Colors.green 
        : (statut == 'annulé' ? Colors.red : Colors.orange);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(8)
      ),
      child: Text(
        statut.toUpperCase(), 
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)
      ),
    );
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: couleur)
    );
  }
}