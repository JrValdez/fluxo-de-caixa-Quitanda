import 'package:flutter/material.dart';

/// Paleta e tema visual da marca "Quitandas da Badia".
/// Cores extraídas do logo: terracota/laranja queimado + creme.
class AppColors {
  static const terracota = Color(0xFFBE5E24);
  static const terracotaEscuro = Color(0xFF9A4A1B);
  static const terracotaClaro = Color(0xFFD98A4E);
  static const creme = Color(0xFFF7EEE2);
  static const cremeClaro = Color(0xFFFBF5EC);
  static const marrom = Color(0xFF3A2416);
  static const marromSuave = Color(0xFF6B5344);
  static const entrada = Color(0xFF2E7D5B);
  static const saida = Color(0xFFC0392B);

  /// Âmbar escurecido para garantir contraste WCAG AA (≥4.5:1) em texto
  /// sobre fundos claros. Para fundos/tints, use `alertaFundo`.
  static const alerta = Color(0xFFA16207);
  static const alertaFundo = Color(0xFFE0A106);

  static const borda = Color(0xFFE4D6C4);

  /// Sombra natural suave (estilo "Nature Distilled"): quase imperceptível,
  /// só o suficiente para descolar o card do fundo creme.
  static const List<BoxShadow> sombraCard = [
    BoxShadow(color: Color(0x143A2416), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.terracota,
        primary: AppColors.terracota,
        secondary: AppColors.terracotaEscuro,
        surface: AppColors.cremeClaro,
        error: AppColors.saida,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.creme,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.terracota,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: const Color(0x143A2416),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borda),
        ),
        margin: EdgeInsets.zero,
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.marromSuave,
        ),
        // Números tabulares: colunas de valores não "dançam" entre linhas.
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: AppColors.marrom,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) return AppColors.cremeClaro;
          return null;
        }),
        dividerThickness: 0.6,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borda),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.terracota, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracota,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.terracota,
        selectedIconTheme: IconThemeData(color: AppColors.terracota),
        unselectedIconTheme: IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: Colors.white70),
        indicatorColor: Colors.white,
      ),
    );
  }
}
