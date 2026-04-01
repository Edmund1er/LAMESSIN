import 'package:flutter/material.dart';
import '../../SERVICES_/api_service.dart';
import '../../THEME_/app_theme.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _telephone = TextEditingController();
  final _password  = TextEditingController();
  bool _chargement = false;
  bool _obscure    = true;

  void _clicConnexion() async {
    if (_telephone.text.isEmpty || _password.text.isEmpty) {
      AppWidgets.showSnack(context, "Veuillez remplir tous les champs");
      return;
    }
    setState(() => _chargement = true);
    try {
      String? token = await ApiService.login(
          _telephone.text.trim(), _password.text);
      if (!mounted) return;
      if (token != null) {
        Navigator.pushReplacementNamed(context, "/page_utilisateur");
      } else {
        AppWidgets.showSnack(context, "Numéro ou mot de passe incorrect",
            color: AppColors.danger);
      }
    } catch (e) {
      if (!mounted) return;
      AppWidgets.showSnack(context, "Erreur de connexion au serveur",
          color: AppColors.danger);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HEADER VIOLET ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft:  Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 40,
                bottom: 36, left: 28, right: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 20),
                  const Text('Bienvenue sur\nLAMESSIN',
                      style: TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 8),
                  Text('Connectez-vous à votre espace',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14)),
                ],
              ),
            ),

            // ── FORMULAIRE ──
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  _label('Téléphone'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _telephone,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '+228 90 00 00 00',
                      prefixIcon: const Icon(Icons.phone_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                  ),
                  const SizedBox(height: 18),

                  _label('Mot de passe'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_rounded,
                          color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded
                                   : Icons.visibility_rounded,
                          color: AppColors.textSecondary, size: 20,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Mot de passe oublié ?',
                          style: TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  AppWidgets.darkButton(
                    label: 'Se connecter',
                    onPressed: _clicConnexion,
                    loading: _chargement,
                  ),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, "/register"),
                      child: RichText(
                        text: const TextSpan(
                          text: 'Pas encore de compte ? ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: "S'inscrire",
                              style: TextStyle(color: AppColors.primary,
                                  fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
          color: AppColors.textPrimary));
}
