import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../SERVICES_/api_service.dart';

class PanierItem {
  final int idMedoc;
  final int idPharmacie; // Ajouté pour Django
  final String nom;
  final double prix;
  int quantite;

  PanierItem({
    required this.idMedoc,
    required this.idPharmacie,
    required this.nom,
    required this.prix,
    this.quantite = 1,
  });
}

class PanierPage extends StatefulWidget {
  final List<PanierItem> items;
  const PanierPage({super.key, required this.items});

  @override
  State<PanierPage> createState() => _PanierPageState();
}

class _PanierPageState extends State<PanierPage> {
  
  double get total => widget.items.fold(0, (sum, item) => sum + (item.prix * item.quantite));

Future<void> _validerCommandeComplete() async {
    if (widget.items.isEmpty) return;

    List<Map<String, dynamic>> articlesJson = widget.items.map((item) => {
      'id': item.idMedoc,
      'qte': item.quantite,
      'pharmacie_id': item.idPharmacie,
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resultat = await ApiService.creerCommandeMultiple(articlesJson);

      if (!mounted) return;
      Navigator.pop(context); 

      if (resultat != null && resultat['payment_url'] != null) {
        final Uri url = Uri.parse(resultat['payment_url']);
        
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);

          setState(() {
            widget.items.clear();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Commande créée ! Redirection vers le paiement..."), 
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            )
          );
          
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) Navigator.pop(context); 
          });
        }
      } else {
        _afficherErreur("Impossible de générer le lien de paiement.");
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _afficherErreur("Erreur de connexion au serveur.");
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
      appBar: AppBar(
        title: const Text("Mon Panier"),
        backgroundColor: const Color(0xFF0056b3),
        foregroundColor: Colors.white,
      ),
      body: widget.items.isEmpty
          ? const Center(child: Text("Votre panier est vide."))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.items.length,
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(item.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${item.prix} FCFA x ${item.quantite}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    if (item.quantite > 1) item.quantite--;
                                    else widget.items.removeAt(index);
                                  });
                                },
                              ),
                              Text("${item.quantite}"),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => setState(() => item.quantite++),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildSummary(),
              ],
            ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total à payer :", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("${total.toInt()} FCFA", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validerCommandeComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("VALIDER ET PAYER", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}