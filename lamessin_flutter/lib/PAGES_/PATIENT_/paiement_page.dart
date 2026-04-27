import 'package:flutter/material.dart';
import '../../SERVICES_/patient_service.dart';
import '../../THEME_/app_theme.dart';

class PaiementPage extends StatefulWidget {
  final int commandeId;
  final double montant;

  const PaiementPage({
    super.key,
    required this.commandeId,
    required this.montant,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  static const Color _brandColor = Color(0xFF00ACC1);
  int _selectedIndex = 2;

  final TextEditingController _telephoneController = TextEditingController();
  String _operateur = 'TMONEY';
  bool _isLoading = false;
  bool _isVerifying = false;

  final String _imageFond = "assets/images/fond_patient.jpg";

  @override
  void dispose() {
    _telephoneController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/page_utilisateur');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/recherches_services_medicaux');
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/assistant');
    } else if (index == 4) {
      Navigator.pushReplacementNamed(context, '/profil_patient');
    }
  }

  Future<void> _initierPaiement() async {
    String telephone = _telephoneController.text.trim();

    if (telephone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numero de telephone invalide')));
      return;
    }

    setState(() => _isLoading = true);

    final result = await PatientService.initierPaiementMobileMoney(
      commandeId: widget.commandeId,
      telephone: telephone,
      operateur: _operateur,
    );

    setState(() => _isLoading = false);

    if (result != null && result['success'] == true) {
      _showSuccessDialog(result['message'] ?? 'Paiement initie');
      await _verifierPaiement();
    } else {
      String error = result?['error'] ?? 'Erreur lors du paiement';
      _showErrorDialog(error);
    }
  }

  Future<void> _verifierPaiement() async {
    setState(() => _isVerifying = true);

    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));

      final result = await PatientService.verifierStatutPaiement(widget.commandeId);

      if (result != null && result['statut'] == 'SUCCES') {
        setState(() => _isVerifying = false);
        _showSuccessDialog('Paiement reussi !', goBack: true);
        return;
      }
    }

    setState(() => _isVerifying = false);
    _showInfoDialog('Le paiement est en cours de traitement. Verifiez plus tard dans "Mes commandes".');
  }

  void _showSuccessDialog(String message, {bool goBack = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 10),
            Text('Succes'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (goBack) {
                Navigator.pushNamedAndRemoveUntil(context, '/mes_commandes', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Text('Information'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Paiement ${widget.montant.toStringAsFixed(0)} FCFA', style: const TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: _brandColor),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          Container(
            color: Colors.white.withOpacity(0.92),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
                      child: Column(
                        children: [
                          const Text('Montant a payer', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text('${widget.montant.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _brandColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Choisissez votre operateur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildOperateurCard('TMONEY', Icons.phone_android, _operateur == 'TMONEY', () => setState(() => _operateur = 'TMONEY'))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOperateurCard('FLOOZ', Icons.phone_iphone, _operateur == 'FLOOZ', () => setState(() => _operateur = 'FLOOZ'))),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text('Numero de telephone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                      child: TextField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        decoration: const InputDecoration(
                          hintText: 'Ex: 90000001',
                          hintStyle: TextStyle(color: Colors.grey),
                          prefixIcon: Icon(Icons.phone, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isVerifying) ? null : _initierPaiement,
                        style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : _isVerifying
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                      SizedBox(width: 12),
                                      Text('Verification en cours...', style: TextStyle(color: Colors.white)),
                                    ],
                                  )
                                : Text('Payer ${widget.montant.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vous recevrez une notification sur votre telephone pour confirmer le paiement.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(_selectedIndex),
    );
  }

  Widget _buildOperateurCard(String name, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _brandColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _brandColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? _brandColor : Colors.grey, size: 28),
            const SizedBox(height: 6),
            Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: isSelected ? _brandColor : Colors.grey)),
          ],
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
              _navItem(Icons.shopping_bag_rounded, "Commandes", 2, currentIndex),
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