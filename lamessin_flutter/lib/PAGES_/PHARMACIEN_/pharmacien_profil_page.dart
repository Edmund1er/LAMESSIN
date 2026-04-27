import 'package:flutter/material.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import 'pharmacien_dashboard_page.dart';
import 'pharmacien_commandes_page.dart';
import 'pharmacien_produits_page.dart';
// SUPPRIME: import 'pharmacien_scan_ordonnance_page.dart';

class PharmacienProfilPage extends StatefulWidget {
  const PharmacienProfilPage({super.key});

  @override
  State<PharmacienProfilPage> createState() => _PharmacienProfilPageState();
}

class _PharmacienProfilPageState extends State<PharmacienProfilPage> {
  Pharmacien? _pharmacien;
  bool _chargement = true;

  final String _imageFond = "assets/images/fond_pharmacien_profil.jpg";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    final data = await ApiService.getProfil();
    if (mounted) {
      setState(() {
        if (data is Pharmacien) {
          _pharmacien = data;
        }
        _chargement = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienCommandesPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienProduitsPage()));
    } else if (index == 3) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1))),
      );
    }

    if (_pharmacien == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text("Profil non disponible")),
      );
    }

    final user = _pharmacien!.compteUtilisateur;
    final nom = user.lastName;
    final prenom = user.firstName;
    final tel = user.numeroTelephone;
    final email = user.email;
    final nomPharmacie = _pharmacien!.nomPharmacie;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PharmacienDashboardPage())),
        ),
        title: const Text("Mon Profil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00ACC1), width: 3),
                    ),
                    child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF00ACC1), size: 50),
                  ),
                  const SizedBox(height: 16),
                  Text("$prenom $nom", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(nomPharmacie, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF00ACC1))),
                  ),
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Informations de contact", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        _infoRow(Icons.phone_rounded, "Telephone", tel, false),
                        _infoRow(Icons.email_rounded, "Email", email, false),
                        _infoRow(Icons.local_pharmacy_rounded, "Pharmacie", nomPharmacie, true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmerDeconnexion(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text("Se deconnecter", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(3), // CORRIGE: index 3 (0,1,2,3) au lieu de 4
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF00ACC1), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 68, color: Colors.grey),
      ],
    );
  }

  void _confirmerDeconnexion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Deconnexion", style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text("Voulez-vous vraiment vous deconnecter ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Se deconnecter"),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int index) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.dashboard_rounded, "Accueil", 0, index),
              _navItem(Icons.shopping_bag_rounded, "Commandes", 1, index),
              _navItem(Icons.medication_rounded, "Produits", 2, index),
              _navItem(Icons.person_rounded, "Profil", 3, index), 
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
          Icon(icon, color: actif ? const Color(0xFF00ACC1) : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: actif ? FontWeight.w600 : FontWeight.normal, color: actif ? const Color(0xFF00ACC1) : Colors.grey)),
        ],
      ),
    );
  }
}