import 'dart:ui'; // Nécessaire pour le flou
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
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _dateNaissance) {
      setState(() => _dateNaissance = picked);
    }
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
      "type_compte": _roleChoisi.toLowerCase(),
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

    try {
      bool succes = await ApiService.inscription(monColis);

      if (mounted) setState(() => _isLoading = false);

      if (succes) {
        if (!mounted) return;
        AppWidgets.showSnack(
          context,
          "Inscription réussie ! Connectez-vous.",
          color: AppColors.success,
        );
        Navigator.pushReplacementNamed(context, "/login");
      } else {
        AppWidgets.showSnack(
          context,
          "Erreur lors de l'inscription. Vérifiez vos informations.",
          color: AppColors.danger,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      AppWidgets.showSnack(
        context,
        "Erreur réseau : $e",
        color: AppColors.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/register.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(
                      0.2,
                    ), // Le haut reste clair pour voir l'image
                    Colors.black.withOpacity(
                      0.75,
                    ), // Le bas s'assombrit pour le formulaire
                  ],
                ),
              ),
            ),
          ),

          // 3. CONTENU PRINCIPAL
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // BOUTON RETOUR (FLOTTANT)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // --- TITRE (Chic et Visible) ---
                    Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rejoignez LAMESSIN',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- CARTE FORMULAIRE (GLASSMORPHISM) ---
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.15,
                            ), // Fond transparent
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // SÉLECTEUR DE RÔLE
                                const Text(
                                  "Je suis un...",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _roleButton(
                                          'Patient',
                                          Icons.person,
                                          'patient',
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _roleButton(
                                          'Médecin',
                                          Icons.medical_services,
                                          'medecin',
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: _roleButton(
                                          'Pharma',
                                          Icons.local_pharmacy,
                                          'pharmacien',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // CHAMPS NOM & PRÉNOM
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        _nom,
                                        "Nom",
                                        Icons.person,
                                      ),
                                    ),
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

                                // TÉLÉPHONE
                                _buildField(
                                  _telephone,
                                  "Téléphone",
                                  Icons.phone_android_rounded,
                                  type: TextInputType.phone,
                                ),
                                const SizedBox(height: 12),

                                // EMAIL
                                _buildField(
                                  _email,
                                  "Email",
                                  Icons.email_outlined,
                                  type: TextInputType.emailAddress,
                                  isEmail: true,
                                ),
                                const SizedBox(height: 12),

                                // MOT DE PASSE
                                _buildPasswordField(),
                                const SizedBox(height: 20),

                                // CHAMPS CONDITIONNELS
                                if (_roleChoisi == "patient") ...[
                                  const Text(
                                    "Informations de santé",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildDatePicker(),
                                  const SizedBox(height: 12),
                                  _buildBloodSelector(),
                                ] else ...[
                                  const Text(
                                    "Informations professionnelles",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _buildField(
                                    _specialite,
                                    "Spécialité",
                                    Icons.workspace_premium_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildField(
                                    _licence,
                                    "N° Licence",
                                    Icons.verified_user_outlined,
                                  ),
                                ],

                                const SizedBox(height: 25),

                                // BOUTON VALIDER
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _lancerInscription,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Text(
                                            "CRÉER MON COMPTE",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // LIEN
                                Center(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text(
                                      "Vous avez déjà un compte ? Se connecter",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS PERSONNALISÉS STYLE GLASS ---

  Widget _roleButton(String label, IconData icon, String value) {
    bool isSelected = _roleChoisi == value;
    return GestureDetector(
      onTap: () => setState(() => _roleChoisi = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
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
    TextInputType type = TextInputType.text,
    bool isEmail = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        // Fond blanc semi-transparent (70%) pour lisibilité
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Requis";
          if (isEmail &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
            return "Email invalide";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: _password,
        obscureText: _obscure,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: "Mot de passe",
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.primary,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          border: InputBorder.none,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Requis";
          if (value.length < 6) return "6 car. min";
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectionnerDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              _dateNaissance == null
                  ? "Date de naissance"
                  : "Né(e) le : ${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}",
              style: TextStyle(
                color: _dateNaissance == null
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _groupeSanguinChoisi,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          decoration: InputDecoration(
            labelText: "Groupe Sanguin",
            labelStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.bloodtype_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          items: _groupes.map((String g) {
            return DropdownMenuItem(value: g, child: Text(g));
          }).toList(),
          onChanged: (value) => setState(() => _groupeSanguinChoisi = value),
          validator: (value) => value == null ? "Requis" : null,
        ),
      ),
    );
  }
}
