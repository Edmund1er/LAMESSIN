import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

class MesCommandesPage extends StatefulWidget {
  const MesCommandesPage({super.key});

  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

class _MesCommandesPageState extends State<MesCommandesPage> with WidgetsBindingObserver {
  List<dynamic> _commandes = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _chargerCommandes();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _chargerCommandes();
    }
  }

  Future<void> _chargerCommandes() async {
    if (!mounted) return;
    setState(() => _chargement = true);
    
    try {
      final data = await ApiService.getMesCommandes();
      if (mounted) {
        setState(() {
          _commandes = data;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _relancerPaiement(int commandeId) async {
    _afficherMessage("Préparation du paiement FedaPay...", Colors.blueGrey);

    final resultat = await ApiService.obtenirLienPaiement(commandeId);
    
    if (resultat != null && resultat['payment_url'] != null) {
      final Uri uri = Uri.parse(resultat['payment_url']);
      
// On utilise le mode externalApplication pour forcer l'ouverture du navigateur

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _afficherMessage("Impossible d'ouvrir le lien", Colors.red);
      }
    } else {
      _afficherMessage("Erreur : Impossible de générer le lien", Colors.red);
    }
  }

  void _afficherMessage(String msg, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: couleur, duration: const Duration(seconds: 2))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const MenuNavigation(),
      appBar: AppBar(
        title: const Text("Mes Achats Pharmaceutiques"),
        backgroundColor: const Color(0xFFF96AD5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerCommandes,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/recherches_services_medicaux'),
        backgroundColor: const Color(0xFFF96AD5),
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text("Commander", style: TextStyle(color: Colors.white)),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF96AD5)))
          : RefreshIndicator(
              onRefresh: _chargerCommandes,
              child: _commandes.isEmpty 
                  ? _buildEmptyState() 
                  : ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: _commandes.length,
                      itemBuilder: (context, index) => _buildCommandeCard(_commandes[index]),
                    ),
            ),
    );
  }

  Widget _buildCommandeCard(dynamic c) {
    String statut = (c['statut_commande'] ?? 'en_attente').toLowerCase();
    bool estPaye = statut == 'paye' || statut == 'confirme';
    Color statusColor = estPaye ? Colors.green : Colors.orange;

    String prixAffiche = c['prix_total']?.toString() ?? "À calculer";

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Commande #${c['id']}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statut.toUpperCase(), 
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 25),
            _infoLigne(Icons.calendar_today, "Date", _formaterDate(c['date'])),
            const SizedBox(height: 8),
            _infoLigne(Icons.monetization_on, "Total", "$prixAffiche FCFA"),
            const SizedBox(height: 20),
            if (!estPaye)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _relancerPaiement(c['id']),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text("FINALISER LE PAIEMENT", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Commande réglée", 
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formaterDate(String? dateStr) {
    if (dateStr == null) return "Date inconnue";
    try {
      DateTime dt = DateTime.parse(dateStr);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  Widget _infoLigne(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Aucune commande dans votre historique.", 
            style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}