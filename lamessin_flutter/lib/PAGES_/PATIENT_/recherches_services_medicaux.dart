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
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 1;
  
  List<EtablissementSante> etablissements = [];
  List<EtablissementSante> etablissementsFiltres = [];
  bool chargementEtablissements = true;
  String filtreType = "Tous";

  List<Medicament> resultatsMedicaments = [];
  bool rechercheEnCours = false;
  final TextEditingController _searchController = TextEditingController();
  Position? _currentPosition;
  List<PanierItem> _panier = [];

  final String _imageFond = "assets/images/fond_patient.jpg";

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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      return;
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/mes_rendez_vous_page');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  void _appliquerFiltre() {
    setState(() {
      if (filtreType == "Tous") {
        etablissementsFiltres = List.from(etablissements);
      } else if (filtreType == "Pharmacie") {
        etablissementsFiltres = etablissements.where((e) => e.estPharmacie).toList();
      } else if (filtreType == "Hôpital") {
        etablissementsFiltres = etablissements.where((e) => e.estHopital).toList();
      } else {
        etablissementsFiltres = List.from(etablissements);
      }
    });
  }

  Future<void> _initialiserLocalisationEtDonnees() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint("Localisation indisponible : $e");
    } finally {
      await _chargerEtTrierEtablissements();
    }
  }

  Future<void> _ouvrirItineraire(double lat, double lng) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisir une application", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF33A3DC), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.location_on, color: Colors.white)),
              title: const Text("Waze"),
              subtitle: const Text("Navigation avec trafic en temps reel"),
              onTap: () async {
                Navigator.pop(ctx);
                final wazeUrl = 'waze://?ll=$lat,$lng&navigate=yes';
                if (await canLaunchUrl(Uri.parse(wazeUrl))) {
                  await launchUrl(Uri.parse(wazeUrl), mode: LaunchMode.externalApplication);
                } else {
                  AppWidgets.showSnack(context, "Waze non installe", color: Colors.orange);
                }
              },
            ),
            ListTile(
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFEA4335), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.map, color: Colors.white)),
              title: const Text("Google Maps"),
              subtitle: const Text("Alternative fiable et universelle"),
              onTap: () async {
                Navigator.pop(ctx);
                final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
                await launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

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
            double dA = Geolocator.distanceBetween(
              _currentPosition!.latitude, _currentPosition!.longitude,
              a.latitude, a.longitude,
            );
            double dB = Geolocator.distanceBetween(
              _currentPosition!.latitude, _currentPosition!.longitude,
              b.latitude, b.longitude,
            );
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

  Future<void> _chargerEtTrierEtablissements() async {
    setState(() => chargementEtablissements = true);
    try {
      List<EtablissementSante> data = await PatientService.getEtablissements();
      if (_currentPosition != null) {
        data.sort((a, b) {
          double dA = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            a.latitude, a.longitude,
          );
          double dB = Geolocator.distanceBetween(
            _currentPosition!.latitude, _currentPosition!.longitude,
            b.latitude, b.longitude,
          );
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModal) => Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage("assets/images/fond_patient.jpg"), fit: BoxFit.cover)),
          child: Container(
            color: Colors.white.withOpacity(0.95),
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(height: 8),
                Text(medoc.nomCommercial, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                const SizedBox(height: 6),
                Text("${medoc.prixVente.toStringAsFixed(0)} FCFA / unite", style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    GestureDetector(
                      onTap: () => setModal(() => quantite > 1 ? quantite-- : null),
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.dangerLight, shape: BoxShape.circle), child: const Icon(Icons.remove_rounded, color: AppColors.danger, size: 18)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text("$quantite", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87)),
                    ),
                    GestureDetector(
                      onTap: () => setModal(() => quantite++),
                      child: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: Color(0xFF4CAF50), size: 18)),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: const BorderSide(color: Colors.grey), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12)),
                      child: const Text("Annuler", style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _brandColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0),
                      onPressed: () {
                        _ajouterAuPanier(medoc, quantite, pharmacieId);
                        Navigator.pop(context);
                      },
                      child: Text("Ajouter (${(medoc.prixVente * quantite).toStringAsFixed(0)} FCFA)", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                ]),
              ]),
            ),
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
        _panier.add(PanierItem(idMedoc: medoc.id, idPharmacie: pharmacieId, nom: medoc.nomCommercial, prix: medoc.prixVente, quantite: qte));
      }
    });
    AppWidgets.showSnack(context, "${medoc.nomCommercial} ajoute au panier", color: AppColors.success);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: const MenuNavigation(),
      appBar: null,
      floatingActionButton: _panier.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PanierPage(items: _panier))).then((_) => setState(() {})),
              backgroundColor: _brandColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              label: Text("Panier (${_panier.length})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Column(children: [
            Container(
              color: _brandColor,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 16, left: 16, right: 16),
              child: Column(children: [
                Row(children: [
                  Builder(builder: (ctx) => GestureDetector(
                    onTap: () => Scaffold.of(ctx).openDrawer(),
                    child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20)),
                  )),
                  const SizedBox(width: 12),
                  const Text("Services médicaux", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _rechercherMedicament,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: const InputDecoration(
                      hintText: "Rechercher un médicament...",
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Container(
                color: Colors.white.withOpacity(0.92),
                child: _searchController.text.isNotEmpty ? _buildResultatsMedicaments() : _buildListeEtablissements(),
              ),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildResultatsMedicaments() {
    if (rechercheEnCours) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)));
    }
    if (resultatsMedicaments.isEmpty) {
      return const Center(child: Text("Aucun résultat.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: resultatsMedicaments.length,
      itemBuilder: (_, index) {
        final medoc = resultatsMedicaments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: medoc.stocksDisponibles.isNotEmpty ? _brandColor.withOpacity(0.15) : AppColors.dangerLight, borderRadius: BorderRadius.circular(11)),
                child: Icon(Icons.medication_rounded, color: medoc.stocksDisponibles.isNotEmpty ? _brandColor : AppColors.danger, size: 20),
              ),
              title: Text(medoc.nomCommercial, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
              subtitle: Text("${medoc.prixVente.toStringAsFixed(0)} FCFA", style: const TextStyle(fontSize: 12, color: Colors.grey)),
              children: medoc.stocksDisponibles.map((s) {
                String distanceText = "";
                if (_currentPosition != null) {
                  double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, s.latitude, s.longitude);
                  distanceText = " · ${(dist / 1000).toStringAsFixed(1)} km";
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFF4CAF50), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.nomPharmacie, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                      Text("Stock: ${s.quantiteEnStock}$distanceText", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ])),
                    GestureDetector(
                      onTap: () => _ouvrirItineraire(s.latitude, s.longitude),
                      child: Container(width: 34, height: 34, margin: const EdgeInsets.only(right: 6), decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.directions_rounded, color: _brandColor, size: 17)),
                    ),
                    GestureDetector(
                      onTap: () => _afficherModalCommande(medoc, s.idPharmacie),
                      child: Container(width: 34, height: 34, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF4CAF50), size: 17)),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)));
    }

    return Column(children: [
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
                decoration: BoxDecoration(color: sel ? _brandColor : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: sel ? _brandColor : Colors.grey[300]!, width: 1.5)),
                child: Text(type, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : _brandColor)),
              ),
            ),
          );
        }).toList()),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 80),
          itemCount: etablissementsFiltres.length,
          itemBuilder: (_, index) {
            final e = etablissementsFiltres[index];
            final bool isPharmacie = e.estPharmacie;
            final bool isHopital = e.estHopital;

            String distanceText = "";
            if (_currentPosition != null) {
              double dist = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, e.latitude, e.longitude);
              distanceText = "${(dist / 1000).toStringAsFixed(1)} km · ";
            }

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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))]),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)), child: Icon(iconData, color: iconColor, size: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
                    Text("$distanceText${e.adresse}", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: isPharmacie ? _brandColor.withOpacity(0.1) : AppColors.dangerLight, borderRadius: BorderRadius.circular(4)), child: Text(isPharmacie ? "Pharmacie" : (isHopital ? "Hôpital" : "Établissement"), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isPharmacie ? _brandColor : AppColors.danger))),
                  ]),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _ouvrirItineraire(e.latitude, e.longitude),
                  child: Container(width: 38, height: 38, decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.directions_rounded, color: _brandColor, size: 20)),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, "Accueil", 0, currentIndex),
              _navItem(Icons.local_pharmacy_rounded, "Services", 1, currentIndex),
              _navItem(Icons.calendar_month_rounded, "RDV", 2, currentIndex),
              _navItem(Icons.smart_toy_rounded, "Assistant", 3, currentIndex),
              _navItem(Icons.person_rounded, "Profil", 4, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int idx, int current) {
    bool actif = idx == current;
    return GestureDetector(
      onTap: () => _onItemTapped(idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: actif ? _brandColor : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? _brandColor : Colors.grey)),
        ],
      ),
    );
  }
}