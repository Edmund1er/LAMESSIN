import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../MODELS_/utilisateur_model.dart';
import '../../MODELS_/consultation_model.dart';
import '../../MODELS_/ordonnance_model.dart';
import '../../MODELS_/traitement_model.dart';
import 'medecin_patients_page.dart';
import 'medecin_dashboard.dart';
import 'medecin_rendezvous_page.dart';
import 'medecin_consultations_page.dart';
import 'medecin_profil_page.dart';

class MedecinDossierPatientPage extends StatefulWidget {
  final int patientId;
  const MedecinDossierPatientPage({super.key, required this.patientId});

  @override
  State<MedecinDossierPatientPage> createState() => _MedecinDossierPatientPageState();
}

class _MedecinDossierPatientPageState extends State<MedecinDossierPatientPage> {
  Map<String, dynamic>? _dossier;
  bool _chargement = true;
  String _ongletActif = "Infos";
  final List<String> _onglets = ["Infos", "Consultations", "Ordonnances", "Traitements"];

  final String _imageFond = "assets/images/fond_medecin_dossier_patient.jpg";

  @override
  void initState() {
    super.initState();
    _chargerDossier();
  }

  Future<void> _chargerDossier() async {
    setState(() => _chargement = true);
    try {
      final data = await DoctorService.getDossierPatient(widget.patientId);
      if (mounted) {
        setState(() {
          _dossier = data;
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Patient? get _patient {
    if (_dossier == null || _dossier!['patient'] == null) return null;
    return Patient.fromJson(_dossier!['patient']);
  }

  List<Consultation> get _consultations {
    if (_dossier == null || _dossier!['consultations'] == null) return [];
    final List list = _dossier!['consultations'];
    return list.map((item) => Consultation.fromJson(item)).toList();
  }

  List<Ordonnance> get _ordonnances {
    if (_dossier == null || _dossier!['ordonnances'] == null) return [];
    final List list = _dossier!['ordonnances'];
    return list.map((item) => Ordonnance.fromJson(item)).toList();
  }

  List<Traitement> get _traitements {
    if (_dossier == null || _dossier!['traitements'] == null) return [];
    final List list = _dossier!['traitements'];
    return list.map((item) => Traitement.fromJson(item)).toList();
  }

  void _voirConsultation(Consultation consultation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("Detail de la consultation", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
              child: Text("Date: ${consultation.dateConsultation.split(' ').first}", style: const TextStyle(color: Color(0xFF00ACC1), fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 16),
            const Text("Diagnostic", style: TextStyle(fontWeight: FontWeight.w600)),
            Text(consultation.diagnostic, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            const Text("Actes effectues", style: TextStyle(fontWeight: FontWeight.w600)),
            Text(consultation.actesEffectues, style: const TextStyle(fontSize: 14)),
            if (consultation.notesMedecin != null && consultation.notesMedecin!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text("Notes du medecin", style: TextStyle(fontWeight: FontWeight.w600)),
              Text(consultation.notesMedecin!, style: const TextStyle(fontSize: 14)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Fermer"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _voirOrdonnance(Ordonnance ordonnance) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Text("Detail de l'ordonnance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: Color(0xFF00ACC1)),
                  const SizedBox(width: 8),
                  Text("Code securite: ${ordonnance.codeSecurite ?? 'Non genere'}", style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF00ACC1))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text("Prescrite le ${ordonnance.datePrescription}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text("Medicaments prescrits:", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...ordonnance.lignes.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nomMedicament, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text("Quantite: ${l.quantiteBoites} boite(s)", style: const TextStyle(fontSize: 12)),
                  Text("Posologie: ${l.posologieSpecifique}", style: const TextStyle(fontSize: 12)),
                  Text("Duree: ${l.dureeTraitementJours} jours", style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Fermer"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage()));
    } else if (index == 1) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinRendezVousPage()));
    } else if (index == 2) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinConsultationsPage()));
    } else if (index == 3) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinProfilPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinDashboardPage())),
        ),
        title: const Text("Dossier patient", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _chargerDossier),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_imageFond, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100])),
          ),
          _chargement
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00ACC1)))
              : Container(
                  color: Colors.white.withOpacity(0.92),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F7FA),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 36),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${_patient?.compteUtilisateur.firstName ?? ''} ${_patient?.compteUtilisateur.lastName ?? ''}",
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(_patient?.compteUtilisateur.numeroTelephone ?? "Non renseigne", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "Groupe: ${_patient?.groupeSanguin ?? 'Inconnu'}",
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00ACC1).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          "Ne(e): ${_patient?.dateNaissance ?? 'Non renseignee'}",
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF00ACC1)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _onglets.map((onglet) {
                              final actif = _ongletActif == onglet;
                              return GestureDetector(
                                onTap: () => setState(() => _ongletActif = onglet),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: actif ? const Color(0xFF00ACC1) : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    onglet,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: actif ? FontWeight.w600 : FontWeight.normal,
                                      color: actif ? const Color(0xFF00ACC1) : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildContenuOnglet(),
                      ),
                    ],
                  ),
                ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.dashboard_rounded, "Accueil", 0),
                _buildNavItem(Icons.calendar_today_rounded, "Rendez-vous", 1),
                _buildNavItem(Icons.history_rounded, "Consultations", 2),
                _buildNavItem(Icons.person_rounded, "Profil", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContenuOnglet() {
    switch (_ongletActif) {
      case "Consultations":
        return _buildConsultationsList();
      case "Ordonnances":
        return _buildOrdonnancesList();
      case "Traitements":
        return _buildTraitementsList();
      default:
        return _buildInfosPersonnelles();
    }
  }

  Widget _buildInfosPersonnelles() {
    if (_patient == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Informations personnelles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Divider(height: 1),
                _infoRow("Nom complet", "${_patient!.compteUtilisateur.firstName} ${_patient!.compteUtilisateur.lastName}"),
                _infoRow("Telephone", _patient!.compteUtilisateur.numeroTelephone ?? "Non renseigne"),
                _infoRow("Email", _patient!.compteUtilisateur.email ?? "Non renseigne"),
                _infoRow("Date de naissance", _patient!.dateNaissance ?? "Non renseignee"),
                _infoRow("Groupe sanguin", _patient!.groupeSanguin ?? "Inconnu"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Statistiques", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Divider(height: 1),
                _infoRow("Nombre de consultations", "${_consultations.length}"),
                _infoRow("Nombre d'ordonnances", "${_ordonnances.length}"),
                _infoRow("Traitements en cours", "${_traitements.where((t) => t.dateFin.isNotEmpty && DateTime.parse(t.dateFin).isAfter(DateTime.now())).length}"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    if (_consultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_information_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucune consultation", style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _consultations.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _voirConsultation(_consultations[i]),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Color(0xFF00ACC1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _consultations[i].dateConsultation.split(' ').first,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _consultations[i].diagnostic,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdonnancesList() {
    if (_ordonnances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucune ordonnance", style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ordonnances.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _voirOrdonnance(_ordonnances[i]),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_rounded, color: Color(0xFF00ACC1)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ordonnance du ${_ordonnances[i].datePrescription}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_ordonnances[i].lignes.length} medicament(s)",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTraitementsList() {
    if (_traitements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucun traitement", style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _traitements.length,
      itemBuilder: (_, i) {
        final t = _traitements[i];
        final estActif = t.dateFin.isNotEmpty && DateTime.parse(t.dateFin).isAfter(DateTime.now());
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: estActif ? const Color(0xFF4CAF50).withOpacity(0.3) : Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: estActif ? const Color(0xFF4CAF50) : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.nomDuTraitement,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (estActif)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text("En cours", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Du ${t.dateDebut} au ${t.dateFin}",
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                "${t.prises.length} prise(s) programmee(s)",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}