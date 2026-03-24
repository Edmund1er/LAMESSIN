import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/medicament_model.dart'; // AJOUT CRITIQUE
import 'panier_page.dart';

class DetailProduitPage extends StatelessWidget {
  // CORRECTION ICI : On attend un objet Medicament
  final Medicament medicament; 

  const DetailProduitPage({super.key, required this.medicament});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nomCommercial),
        backgroundColor: const Color(0xFFF96AD5),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Icon(Icons.medication, size: 100, color: Colors.blueGrey[200]),
                  ),
                  const SizedBox(height: 20),
                  Text(medicament.nomCommercial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("Disponible en pharmacie", style: TextStyle(color: Colors.teal[700], fontSize: 16)),
                  const Divider(height: 40),
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(medicament.description),
                  const SizedBox(height: 20),
                  Text("${medicament.prixVente.toInt()} FCFA", 
                    style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Pour l'ajout au panier, il faut un ID de pharmacie.
                  // Comme la page détail ne connait pas forcément la pharmacie (car le médicament peut être dans plusieurs pharmacies),
                  // tu devrais peut-être repenser la navigation pour passer le `StockPharmacie` au lieu du `Medicament`.
                  // En attendant, voici comment on ferait si on avait l'ID pharmacie :
                  
                  // Exemple fictif pour l'instant (à adapter selon ta logique de navigation) :
                  /*
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PanierPage(items: [
                      PanierItem(
                        idMedoc: medicament.id,
                        idPharmacie: 1, // ID par défaut ou à récupérer
                        nom: medicament.nomCommercial,
                        prix: medicament.prixVente,
                      )
                    ]),
                  ));
                  */
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Veuillez sélectionner une pharmacie spécifique dans la recherche pour ajouter au panier."))
                  );
                },
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text("AJOUTER AU PANIER"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }
}