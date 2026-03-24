import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import 'package:url_launcher/url_launcher.dart';
// AJOUT CRITIQUE : Import du modèle
import '../../MODELS_/commande_model.dart';

class MesCommandesPage extends StatefulWidget {
  const MesCommandesPage({super.key});

  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

class _MesCommandesPageState extends State<MesCommandesPage> with WidgetsBindingObserver {
  // CORRECTION ICI : Typage strict avec le modèle Commande
  List<Commande> _commandes = []; 
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
    // ApiService renvoie maintenant une List<Commande>
    final data = await ApiService.getMesCommandes();
    if (mounted) {
      setState(() {
        _commandes = data;
        _chargement = false;
      });
    }
  }

  Future<void> _relancerPaiement(int commandeId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ouverture du portail de paiement Togo..."))
    );

    final resultat = await ApiService.obtenirLienPaiement(commandeId);
    
    if (resultat != null && resultat['payment_url'] != null) {
      final Uri uri = Uri.parse(resultat['payment_url']);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      _afficherErreur("Impossible de générer le lien de paiement.");
    }
  }

  void _afficherErreur(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Commandes"), backgroundColor: const Color(0xFFF96AD5)),
      body: _chargement 
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _commandes.length,
              itemBuilder: (context, index) {
                final c = _commandes[index];
                // CORRECTION ICI : Utilisation des propriétés de l'objet (c.statut)
                bool estPaye = c.statut == 'PAYE';

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("Commande #${c.id}"),
                    subtitle: Text("Total: ${c.total.toInt()} FCFA"), // Utilisation de c.total
                    trailing: estPaye 
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                          onPressed: () => _relancerPaiement(c.id),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text("PAYER (TMONEY/FLOOZ)", style: TextStyle(fontSize: 10)),
                        ),
                  ),
                );
              },
            ),
    );
  }
}