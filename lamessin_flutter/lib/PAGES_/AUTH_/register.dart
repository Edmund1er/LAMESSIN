import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../THEME_/app_theme.dart';

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
  final List<String> _groupes = [
    "A+",
    "A-",
    "B+",
    "B-",
    "AB+",
    "AB-",
    "O+",
    "O-",
  ];
  DateTime? _dateNaissance;
  String _roleChoisi = "patient";
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _selectionnerDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale("fr", "FR"),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateNaissance = picked);
  }

  void _lancerInscription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roleChoisi == "patient" && _dateNaissance == null) {
      AppWidgets.showSnack(
        context,
        "Veuillez choisir votre date de naissance",
        color: AppColors.warning,
      );
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
      "type_compte": _roleChoisi,
    };
    if (_roleChoisi == "patient") {
      monColis["date_naissance"] = _dateNaissance?.toIso8601String().split(
        'T',
      )[0];
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
      AppWidgets.showSnack(
        context,
        "Inscription réussie !",
        color: AppColors.success,
      );
    } else {
      AppWidgets.showSnack(
        context,
        "Erreur lors de l'inscription.",
        color: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 28,
                left: 20,
                right: 20,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Rejoignez LAMESSIN',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Sélecteur de rôle
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'patient', label: Text('Patient')),
                        ButtonSegment(value: 'medecin', label: Text('Médecin')),
                        ButtonSegment(
                          value: 'pharmacien',
                          label: Text('Pharma'),
                        ),
                      ],
                      selected: {_roleChoisi},
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected))
                            return AppColors.primary;
                          return AppColors.background;
                        }),
                        foregroundColor: MaterialStateProperty.resolveWith((
                          states,
                        ) {
                          if (states.contains(MaterialState.selected))
                            return Colors.white;
                          return AppColors.textSecondary;
                        }),
                      ),
                      onSelectionChanged: (val) =>
                          setState(() => _roleChoisi = val.first),
                    ),
                    const SizedBox(height: 20),

                    // Nom + Prénom
                    Row(
                      children: [
                        Expanded(child: _buildField(_nom, "Nom", Icons.person)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            _prenom,
                            "Prénom",
                            Icons.person_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      _telephone,
                      "Téléphone",
                      Icons.phone,
                      type: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      _email,
                      "Email",
                      Icons.email,
                      type: TextInputType.emailAddress,
                      isEmail: true,
                    ),
                    const SizedBox(height: 12),
                    _buildPasswordField(),
                    const SizedBox(height: 16),

                    if (_roleChoisi == "patient") ...[
                      _buildDatePicker(),
                      const SizedBox(height: 12),
                      _buildBloodSelector(),
                    ] else ...[
                      _buildField(
                        _specialite,
                        "Spécialité",
                        Icons.medical_services,
                      ),
                      const SizedBox(height: 12),
                      _buildField(_licence, "N° Licence", Icons.verified_user),
                    ],

                    const SizedBox(height: 28),
                    AppWidgets.primaryButton(
                      label: "S'inscrire",
                      onPressed: _lancerInscription,
                      loading: _isLoading,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Déjà un compte ? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: 'Se connecter',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isPass = false,
    TextInputType type = TextInputType.text,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      ),
      validator: (v) => (v == null || v.isEmpty)
          ? "Obligatoire"
          : (isEmail && !v.contains("@") ? "Email invalide" : null),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _password,
      obscureText: _obscure,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.lock_rounded,
          color: AppColors.primary,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Obligatoire" : null,
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectionnerDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _dateNaissance != null
                ? AppColors.primary
                : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              _dateNaissance == null
                  ? "Date de naissance"
                  : "${_dateNaissance!.day.toString().padLeft(2, '0')}/"
                        "${_dateNaissance!.month.toString().padLeft(2, '0')}/"
                        "${_dateNaissance!.year}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _dateNaissance != null
                    ? AppColors.textPrimary
                    : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSelector() {
    return DropdownButtonFormField<String>(
      value: _groupeSanguinChoisi,
      decoration: const InputDecoration(
        labelText: "Groupe sanguin",
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(
          Icons.bloodtype_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      items: _groupes
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(
                g,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _groupeSanguinChoisi = val),
    );
  }
}
