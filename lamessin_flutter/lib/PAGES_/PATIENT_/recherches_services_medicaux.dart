import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../SERVICES_/api_service.dart';
import '../../SERVICES_/patient_service.dart';
import '../../WIDGETS_/menu_navigation.dart';
import '../../MODELS_/medicament_model.dart';
import '../../MODELS_/etablissement_model.dart';
import '../../THEME_/app_theme.dart';
import 'panier_page.dart';

class RechercheServicesPage extends StatefulWidget {
  const RechercheServicesPage({super.key});
  @override
  State<RechercheServicesPage> createState() => _RechercheServicesPageState();
}

class _RechercheServicesPageState extends State<RechercheServicesPage> {
  static const Color _brandColor = Color(0xFF00C2CB);
  
  List<EtablissementSante> etablissements = [];
  List<EtablissementSante> etablissementsFiltres = [];
  bool chargementEtablissements = true;
  String filtreType = "Tous";

  List<Medicament> resultatsMedicaments = [];
  bool rechercheEnCours = false;
  final TextEditingController _searchController = TextEditingController();
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

  void _appliquerFiltre() {
    setState(() {
      if (filtreType == "Tous") {
        etablissementsFiltres = List.from(etablissements);
      } else if (filtreType == "Pharmacie") {
// on ne garder que les pharmacies 
        etablissementsFiltres = etablissements.where((e) => 
          e.estPharmacie
        ).toList();
      } else if (filtreType == "Hôpital") {
//on ne garder que les hôpitaux
        etablissementsFiltres = etablissements.where((e) => 
          e.estHopital
        ).toList();
      } else {
        etablissementsFiltres = List.from(etablissements);
      }
    });
  }
//pour la localisation
  Future<void> _initialiserLocalisationEtDonnees() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 3));
    } catch (e) {
      debugPrint("Localisation indisponible : $e");
    } finally {
      await _chargerEtTrierEtablissements();
    }
  }
//l'itineraire dans maps apres la géolocalisation 
  Future<void> _ouvrirItineraire(double lat, double lng) async {
    final Uri uri = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      AppWidgets.showSnack(context, "Erreur lors de l'ouverture de la carte",
          color: AppColors.danger);
    }
  }
//pour rechercher les medicaments
  void _rechercherMedicament(String query) async {
    if (query.length < 2) { 
      setState(() => resultatsMedicaments = []); 
      return; 
    }
    setState(() => rechercheEnCours = true);
    try {
      final List<Medicament> resultats = await PatientService.rechercherMedicaments(query);
      if (_currentPosition != null) {
        for (var medoc in resultats) {
          medoc.stocksDisponibles.sort((a, b) {
            double dA = Geolocator.distanceBetween(_currentPosition!.latitude,
                _currentPosition!.longitude, a.latitude, a.longitude);
            double dB = Geolocator.distanceBetween(_currentPosition!.latitude,
                _currentPosition!.longitude, b.latitude, b.longitude);
            return dA.compareTo(dB);
          });
        }
      }
      setState(() { 
        resultatsMedicaments = resultats; 
        rechercheEnCours = false; 
      });
    } catch (e) {
      setState(() => rechercheEnCours = false);
      debugPrint("Erreur recherche médicament: $e");
    }
  }
//on affiche les etablissements rechercher 

  Future<void> _chargerEtTrierEtablissements() async {
    setState(() => chargementEtablissements = true);
    try {
      List<EtablissementSante> data = await PatientService.getEtablissements();
      if (_currentPosition != null) {
        data.sort((a, b) {
          double dA = Geolocator.distanceBetween(_currentPosition!.latitude,
              _currentPosition!.longitude, a.latitude, a.longitude);
          double dB = Geolocator.distanceBetween(_currentPosition!.latitude,
              _currentPosition!.longitude, b.latitude, b.longitude);
          return dA.compareTo(dB);
        });
      }
      setState(() { 
        etablissements = data; 
        etablissementsFiltres = List.from(data);
        chargementEtablissements = false; 
      });
    } catch (e) {
      setState(() => chargementEtablissements = false);
      debugPrint("Erreur chargement établissements: $e");
    }
  }

  void _afficherModalCommande(Medicament medoc, int pharmacieId) {
    int quantite = 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white.withOpacity(0.95),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)
              ),
            ),
            const SizedBox(height: 16),
            Text(
              medoc.nomCommercial, 
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary
              )
            ),
            const SizedBox(height: 6),
            Text(
              "${medoc.prixVente.toStringAsFixed(0)} FCFA / unité",
              style: const TextStyle(
                fontSize: 14, 
                color: AppColors.textSecondary
              )
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  GestureDetector(
                    onTap: () => setModal(() => quantite > 1 ? quantite-- : null),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_rounded,
                        color: AppColors.danger, 
                        size: 18
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "$quantite", 
                      style: const TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary
                      )
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setModal(() => quantite++),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF22863A), 
                        size: 18
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "Annuler",
                    style: TextStyle(fontWeight: FontWeight.w700)
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _ajouterAuPanier(medoc, quantite, pharmacieId);
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Ajouter (${(medoc.prixVente * quantite).toStringAsFixed(0)} FCFA)",
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13
                    ),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
//la fonction qui permettras d'ajouter un produit au panier 
  void _ajouterAuPanier(Medicament medoc, int qte, int pharmacieId) {
    setState(() {
      int index = _panier.indexWhere(
        (item) => item.idMedoc == medoc.id && item.idPharmacie == pharmacieId
      );
      if (index != -1) {
        _panier[index].quantite += qte;
      } else {
        _panier.add(PanierItem(
          idMedoc: medoc.id, 
          idPharmacie: pharmacieId,
          nom: medoc.nomCommercial, 
          prix: medoc.prixVente, 
          quantite: qte
        ));
      }
    });
    AppWidgets.showSnack(context, "${medoc.nomCommercial} ajouté au panier",
        color: AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MenuNavigation(),
      appBar: null,
      floatingActionButton: _panier.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => PanierPage(items: _panier))
              ).then((_) => setState(() {})),
              backgroundColor: _brandColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)
              ),
              label: Text(
                "Panier (${_panier.length})",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700
                )
              ),
              icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fond_patient.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(children: [
//l'en tete en couleur cyan
          Container(
            color: _brandColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 16, 
              left: 16, 
              right: 16,
            ),
            child: Column(children: [
              Row(children: [
                Builder(builder: (ctx) => GestureDetector(
                  onTap: () => Scaffold.of(ctx).openDrawer(),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_rounded, 
                      color: Colors.white, 
                      size: 20
                    ),
                  ),
                )),
                const SizedBox(width: 12),
                const Text(
                  "Services médicaux", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 17, 
                    fontWeight: FontWeight.w800
                  )
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9), 
                  borderRadius: BorderRadius.circular(14)
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _rechercherMedicament,
                  style: const TextStyle(
                    fontSize: 14, 
                    color: AppColors.textPrimary
                  ),
                  decoration: const InputDecoration(
                    hintText: "Rechercher un médicament...",
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary, 
                      size: 20
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ]),
          ),

//le contenu gerant les affichages avec un fond transparent
          Expanded(
            child: Container(
              color: Colors.white.withOpacity(0.75),
              child: _searchController.text.isNotEmpty
                  ? _buildResultatsMedicaments()
                  : _buildListeEtablissements(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildResultatsMedicaments() {
    if (rechercheEnCours) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C2CB))
      );
    }
    if (resultatsMedicaments.isEmpty) {
      return const Center(
        child: Text(
          "Aucun résultat.",
          style: TextStyle(color: AppColors.textSecondary)
        )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: resultatsMedicaments.length,
      itemBuilder: (_, index) {
        final medoc = resultatsMedicaments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight)
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: medoc.stocksDisponibles.isNotEmpty
                      ? _brandColor.withOpacity(0.15) : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: medoc.stocksDisponibles.isNotEmpty
                      ? _brandColor : AppColors.danger, 
                  size: 20
                ),
              ),
              title: Text(
                medoc.nomCommercial, 
                style: const TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary
                )
              ),
              subtitle: Text(
                "${medoc.prixVente.toStringAsFixed(0)} FCFA",
                style: const TextStyle(
                  fontSize: 12, 
                  color: AppColors.textSecondary
                )
              ),
              children: medoc.stocksDisponibles.map((s) {
                String distanceText = "";
                if (_currentPosition != null) {
                  double dist = Geolocator.distanceBetween(
                      _currentPosition!.latitude, _currentPosition!.longitude,
                      s.latitude, s.longitude);
                  distanceText = " · ${(dist / 1000).toStringAsFixed(1)} km";
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Row(children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.success, 
                      size: 16
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(
                          s.nomPharmacie, 
                          style: const TextStyle(
                            fontSize: 13, 
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary
                          )
                        ),
                        Text(
                          "Stock: ${s.quantiteEnStock}$distanceText",
                          style: const TextStyle(
                            fontSize: 11, 
                            color: AppColors.textSecondary
                          )
                        ),
                      ]
                    )),
                    GestureDetector(
                      onTap: () => _ouvrirItineraire(s.latitude, s.longitude),
                      child: Container(
                        width: 34, height: 34, 
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _brandColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Icon(
                          Icons.directions_rounded,
                          color: _brandColor, 
                          size: 17
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _afficherModalCommande(medoc, s.idPharmacie),
                      child: Container(
                        width: 34, height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Color(0xFF22863A), 
                          size: 17
                        ),
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListeEtablissements() {
    if (chargementEtablissements) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C2CB))
      );
    }

    return Column(children: [
      // Filtres
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: ["Tous", "Pharmacie", "Hôpital"].map((type) {
          bool sel = filtreType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  filtreType = type;
                  _appliquerFiltre();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _brandColor : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: sel ? _brandColor : AppColors.border, 
                    width: 1.5
                  ),
                ),
                child: Text(
                  type, 
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textSecondary
                  )
                ),
              ),
            ),
          );
        }).toList()),
      ),

//la liste des établissements filtrés
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
          itemCount: etablissementsFiltres.length,
          itemBuilder: (_, index) {
            final e = etablissementsFiltres[index];
// Déterminer si c'est une pharmacie ou un hôpital
            final bool isPharmacie = e.estPharmacie;
            final bool isHopital = e.estHopital;

            String distanceText = "";
            if (_currentPosition != null) {
              double dist = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude, 
                e.latitude, 
                e.longitude
              );
              distanceText = "${(dist / 1000).toStringAsFixed(1)} km · ";
            }

            // Icône et couleur selon le type
            IconData iconData;
            Color iconColor;
            Color bgColor;
            
            if (isPharmacie) {
              iconData = Icons.local_pharmacy_rounded;
              iconColor = _brandColor;
              bgColor = _brandColor.withOpacity(0.15);
            } else if (isHopital) {
              iconData = Icons.local_hospital_rounded;
              iconColor = AppColors.danger;
              bgColor = AppColors.dangerLight;
            } else {
              iconData = Icons.medical_services_rounded;
              iconColor = AppColors.primary;
              bgColor = AppColors.primaryLight;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight)
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(
                        e.nom, 
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800, 
                          color: AppColors.textPrimary
                        )
                      ),
                      Text(
                        "$distanceText${e.adresse}",
                        style: const TextStyle(
                          fontSize: 12, 
                          color: AppColors.textSecondary
                        ),
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Afficher le type d'établissement
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPharmacie ? _brandColor.withOpacity(0.1) : AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isPharmacie ? "Pharmacie" : (isHopital ? "Hôpital" : "Établissement"),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isPharmacie ? _brandColor : AppColors.danger,
                          ),
                        ),
                      ),
                    ]
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _ouvrirItineraire(e.latitude, e.longitude),
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: _brandColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Icon(
                      Icons.directions_rounded,
                      color: _brandColor, 
                      size: 20
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}