import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../THEME_/app_theme.dart';

class EditProfilPage extends StatefulWidget {
  final Patient patient;
  const EditProfilPage({super.key, required this.patient});

  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 4;

  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _telController;
  bool _enChargement = false;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.patient.compteUtilisateur.firstName);
    _nomController = TextEditingController(text: widget.patient.compteUtilisateur.lastName);
    _telController = TextEditingController(text: widget.patient.compteUtilisateur.numeroTelephone);
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/mes_rendez_vous_page');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      return;
    }
  }

  void _sauvegarder() async {
    if (_prenomController.text.trim().isEmpty ||
        _nomController.text.trim().isEmpty ||
        _telController.text.trim().isEmpty) {
      AppWidgets.showSnack(context, "Veuillez remplir tous les champs obligatoires", color: AppColors.danger);
      return;
    }
    setState(() => _enChargement = true);
    Map<String, dynamic> data = {
      "first_name": _prenomController.text.trim(),
      "last_name": _nomController.text.trim(),
      "numero_telephone": _telController.text.trim(),
    };
    bool succes = await ApiService.updateProfil(data);
    if (mounted) {
      setState(() => _enChargement = false);
      if (succes) {
        Navigator.pop(context, true);
      } else {
        AppWidgets.showSnack(context, "Erreur lors de la mise a jour", color: AppColors.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: _brandColor,
        elevation: 0,
        title: const Text("Modifier mon profil", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: _brandColor.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: _brandColor.withOpacity(0.3), width: 3)),
                      child: const Icon(Icons.person_rounded, color: _brandColor, size: 40),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text("Vos coordonnees", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const SizedBox(height: 16),
                  const Text("Prenom", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 8),
                  _buildField(_prenomController, "Kofi", Icons.person_rounded),
                  const SizedBox(height: 16),
                  const Text("Nom", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 8),
                  _buildField(_nomController, "Mensah", Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  const Text("Numero de telephone", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 8),
                  _buildField(_telController, "+228 90 00 00 00", Icons.phone_android_rounded, keyboard: TextInputType.phone),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sauvegarder,
                      style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _enChargement ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Sauvegarder les modifications", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: _brandColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
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