import 'package:flutter/material.dart';
import '../../SERVICES_/doctor_service.dart';
import '../../THEME_/app_theme.dart';
import '../../SERVICES_/api_service.dart';
import '../../MODELS_/rendezvous_model.dart';
import '../../MODELS_/consultation_model.dart';
import '../../MODELS_/ordonnance_model.dart';
import 'medecin_consultations_page.dart';

class MedecinDetailConsultationPage extends StatefulWidget {
  final int rdvId;
  final Consultation? consultationExistante;
  const MedecinDetailConsultationPage({
    super.key,
    required this.rdvId,
    this.consultationExistante,
  });

  @override
  State<MedecinDetailConsultationPage> createState() => _MedecinDetailConsultationPageState();
}

class _MedecinDetailConsultationPageState extends State<MedecinDetailConsultationPage> {
  RendezVous? _rdv;
  Consultation? _consultation;
  bool _chargement = true;
  bool _enCreation = false;

  final _diagnosticController = TextEditingController();
  final _actesController = TextEditingController();
  final _notesController = TextEditingController();

  final String _imageFond = "assets/images/fond_medecin_detail_consultation.jpg";

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  @override
  void dispose() {
    _diagnosticController.dispose();
    _actesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargement = true);
    try {
      final tousRdv = await DoctorService.getMesRendezVousMedecin();
      final rdv = tousRdv.firstWhere((r) => r.id == widget.rdvId);
      
      if (mounted) {
        setState(() {
          _rdv = rdv;
          if (widget.consultationExistante != null) {
            _consultation = widget.consultationExistante;
            _diagnosticController.text = _consultation!.diagnostic;
            _actesController.text = _consultation!.actesEffectues;
            _notesController.text = _consultation!.notesMedecin ?? "";
          }
          _chargement = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _validerEtTerminer() async {
    if (_diagnosticController.text.trim().isEmpty) {
      AppWidgets.showSnack(context, "Veuillez renseigner le diagnostic", color: Colors.orange);
      return;
    }
    if (_actesController.text.trim().isEmpty) {
      AppWidgets.showSnack(context, "Veuillez renseigner les actes effectues", color: Colors.orange);
      return;
    }
    
    setState(() => _enCreation = true);
    try {
      final result = await DoctorService.creerConsultation(
        rdvId: widget.rdvId,
        diagnostic: _diagnosticController.text.trim(),
        actesEffectues: _actesController.text.trim(),
        notesMedecin: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      
      if (mounted) {
        if (result != null) {
          await DoctorService.updateRendezVousStatut(widget.rdvId, 'termine');
          AppWidgets.showSnack(context, "Consultation enregistree avec succes", color: const Color(0xFF4CAF50));
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinConsultationsPage()));
        } else {
          AppWidgets.showSnack(context, "Erreur lors de l'enregistrement", color: Colors.red);
        }
      }
    } catch (e) {
      if (mounted) AppWidgets.showSnack(context, "Erreur: $e", color: Colors.red);
    } finally {
      if (mounted) setState(() => _enCreation = false);
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

    final nomPatient = _rdv?.patientDemandeur?.compteUtilisateur.firstName ?? "Patient";
    final prenomPatient = _rdv?.patientDemandeur?.compteUtilisateur.lastName ?? "";
    final telephone = _rdv?.patientDemandeur?.compteUtilisateur.numeroTelephone ?? "Non renseigne";
    final motif = _rdv?.motifConsultation ?? "Consultation generale";
    final aDejaConsulte = _consultation != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinConsultationsPage())),
        ),
        title: Text(
          aDejaConsulte ? "Detail consultation" : "Nouvelle consultation",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoPatient(nomPatient, prenomPatient, telephone, motif),
                  const SizedBox(height: 20),
                  
                  if (!aDejaConsulte)
                    _buildFormulaireConsultation()
                  else
                    _buildConsultationExistante(),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPatient(String nomPatient, String prenomPatient, String telephone, String motif) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.person_rounded, color: Color(0xFF00ACC1), size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("$nomPatient $prenomPatient", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(telephone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("${_rdv?.dateRdv} à ${_rdv?.heureRdv}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, size: 16, color: Color(0xFF00ACC1)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    motif,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaireConsultation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Renseignements medicaux", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 16),
          TextField(
            controller: _diagnosticController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Diagnostic *",
              hintText: "Description du diagnostic...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _actesController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Actes effectues *",
              hintText: "Examens, procedures realisees...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: "Notes (optionnel)",
              hintText: "Observations complementaires...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _enCreation ? null : _validerEtTerminer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _enCreation
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Valider et terminer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationExistante() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_information_rounded, color: Color(0xFF4CAF50), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Consultation du", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      _consultation?.dateConsultation.split(' ').first ?? "Date inconnue",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text("Termine", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          const Text("Diagnostic", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _consultation?.diagnostic ?? "Non specifie",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Actes effectues", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _consultation?.actesEffectues ?? "Non specifie",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          if (_consultation?.notesMedecin != null && _consultation!.notesMedecin!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text("Notes du medecin", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _consultation!.notesMedecin!,
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MedecinConsultationsPage())),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text("Retour a la liste"),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}