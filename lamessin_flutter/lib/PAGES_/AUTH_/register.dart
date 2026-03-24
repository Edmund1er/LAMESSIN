import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();

  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _telephone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _specialite = TextEditingController();
  final _licence = TextEditingController();

  String? _groupeSanguinChoisi;
  final List<String> _groupes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"];
  DateTime? _dateNaissance;
  String _roleChoisi = "patient";
  bool _isLoading = false;

  Future<void> _selectionnerDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale("fr", "FR"),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  void _lancerInscription() async {
    if (!_formKey.currentState!.validate()) return;

    if (_roleChoisi == "patient" && _dateNaissance == null) {
      _msg("Veuillez choisir votre date de naissance");
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> monColis = {
      "username": _telephone.text.trim(),
      "numero_telephone": _telephone.text.trim(),
      "email": _email.text.trim(),
      "password": _password.text,
      "first_name": _prenom.text.trim(),
      "last_name": _nom.text.trim(),
      "type_compte": _roleChoisi.toUpperCase(), 
    };

    if (_roleChoisi == "patient") {
      monColis["date_naissance"] = _dateNaissance?.toIso8601String().split('T')[0];
      monColis["groupe_sanguin"] = _groupeSanguinChoisi;
    } else {
      monColis["specialite_medicale"] = _specialite.text.trim();
      monColis["numero_licence"] = _licence.text.trim();
    }

    bool succes = await ApiService.inscription(monColis);
    
    if (mounted) setState(() => _isLoading = false);

    if (succes) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/login");
      _msg("Inscription réussie !", vert: true);
    } else {
      _msg("Erreur lors de l'inscription.");
    }
  }

  void _msg(String txt, {bool vert = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: vert ? Colors.green : Colors.red, content: Text(txt)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Créer un compte", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildRoleSelector(),
                      const SizedBox(height: 20),
                      _buildField(_nom, "Nom", Icons.person),
                      const SizedBox(height: 12),
                      _buildField(_prenom, "Prénom", Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildField(_telephone, "Téléphone", Icons.phone, type: TextInputType.phone),
                      const SizedBox(height: 12),
                      _buildField(_email, "Email", Icons.email, type: TextInputType.emailAddress, isEmail: true),
                      const SizedBox(height: 12),
                      _buildField(_password, "Mot de passe", Icons.lock, isPass: true),
                      const SizedBox(height: 20),
                      if (_roleChoisi == "patient") ...[
                        _buildDatePicker(),
                        const SizedBox(height: 12),
                        _buildBloodSelector(),
                      ] else ...[
                        _buildField(_specialite, "Spécialité", Icons.medical_services),
                        const SizedBox(height: 12),
                        _buildField(_licence, "N° Licence", Icons.verified_user),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _lancerInscription,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("S'INSCRIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildRoleSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'patient', label: Text('Patient')),
        ButtonSegment(value: 'medecin', label: Text('Médecin')),
        ButtonSegment(value: 'pharmacien', label: Text('Pharma')),
      ],
      selected: {_roleChoisi},
      onSelectionChanged: (val) => setState(() => _roleChoisi = val.first),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {bool isPass = false, TextInputType type = TextInputType.text, bool isEmail = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: type,
      decoration: _inputDecoration(label, icon),
      validator: (v) => (v == null || v.isEmpty) ? "Obligatoire" : (isEmail && !v.contains("@") ? "Email invalide" : null),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectionnerDate(context),
      child: InputDecorator(
        decoration: _inputDecoration("Date de naissance", Icons.calendar_today),
        child: Text(_dateNaissance == null ? "Sélectionner" : "${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}"),
      ),
    );
  }

  Widget _buildBloodSelector() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration("Groupe Sanguin", Icons.bloodtype),
      value: _groupeSanguinChoisi,
      items: _groupes.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (val) => setState(() => _groupeSanguinChoisi = val),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
      filled: true, fillColor: const Color(0xFFF7F9FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}