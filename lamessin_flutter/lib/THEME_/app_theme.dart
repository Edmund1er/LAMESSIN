import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
//  PALETTE LAMESSIN (inspirée des maquettes)
// ─────────────────────────────────────────────
class AppColors {
  static const Color primary      = Color(0xFF3D3BDB); // violet principal
  static const Color primaryDark  = Color(0xFF2B29B0);
  static const Color primaryLight = Color(0xFFEEEEFF);

  static const Color accent       = Color(0xFFFF6B6B);
  static const Color success      = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFE6F9F0);
  static const Color warning      = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color danger       = Color(0xFFE53E3E);
  static const Color dangerLight  = Color(0xFFFFE8E8);

  static const Color background     = Color(0xFFF7F7FC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F0F8);

  static const Color textPrimary   = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF8A8AA0);
  static const Color textHint      = Color(0xFFC0C0D0);

  static const Color border      = Color(0xFFEDEDF5);
  static const Color borderLight = Color(0xFFF0F0F8);
}

// ─────────────────────────────────────────────
//  THÈME GLOBAL
// ─────────────────────────────────────────────
class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: AppColors.textHint),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.borderLight, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ─────────────────────────────────────────────
//  WIDGETS RÉUTILISABLES
// ─────────────────────────────────────────────
class AppWidgets {

  /// Bouton principal violet
  static Widget primaryButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  /// Bouton sombre (noir)
  static Widget darkButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  /// Badge statut RDV
  static Widget statusBadge(String statut) {
    Color bg; Color txt;
    final s = statut.toLowerCase();
    if (s == 'confirmé' || s == 'validé') { bg = AppColors.successLight; txt = const Color(0xFF22863A); }
    else if (s == 'annulé') { bg = AppColors.dangerLight; txt = AppColors.danger; }
    else { bg = AppColors.warningLight; txt = const Color(0xFFE65100); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(statut.toUpperCase(),
          style: TextStyle(color: txt, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  /// En-tête d'étape numérotée
  static Widget stepHeader(String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 26, height: 26,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: Center(child: Text(step,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    );
  }

  /// Carte blanche standard
  static Widget card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: child,
    );
  }

  /// AppBar standard LAMESSIN
  static PreferredSizeWidget appBar(String title,
      {List<Widget>? actions, bool showBack = true}) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: true,
      title: Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
              color: AppColors.textPrimary)),
      automaticallyImplyLeading: showBack,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderLight),
      ),
    );
  }

  /// SnackBar standardisé
  static void showSnack(BuildContext context, String msg,
      {Color color = AppColors.textPrimary}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
