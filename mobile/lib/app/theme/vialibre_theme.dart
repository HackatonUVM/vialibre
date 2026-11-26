import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens semánticos adaptables entre Modo Claro y Modo Oscuro de "Calma Urbana".
@immutable
class ViaLibrePalette extends ThemeExtension<ViaLibrePalette> {
  const ViaLibrePalette({
    required this.isDark,
    required this.canvas,
    required this.card,
    required this.sand,
    required this.border,
    required this.ink,
    required this.muted,
    required this.coral,
    required this.coralSoft,
    required this.lavender,
    required this.lavenderInk,
    required this.mintSoft,
    required this.mintInk,
    required this.amberSoft,
    required this.amberInk,
    required this.alertRed,
    required this.alertRedSoft,
    required this.ctaBg,
    required this.ctaFg,
  });

  final bool isDark;
  final Color canvas;
  final Color card;
  final Color sand;
  final Color border;
  final Color ink;
  final Color muted;
  final Color coral;
  final Color coralSoft;
  final Color lavender;
  final Color lavenderInk;
  final Color mintSoft;
  final Color mintInk;
  final Color amberSoft;
  final Color amberInk;
  final Color alertRed;
  final Color alertRedSoft;
  final Color ctaBg;
  final Color ctaFg;

  static const ViaLibrePalette light = ViaLibrePalette(
    isDark: false,
    canvas: Color(0xFFFAF8F5),
    card: Color(0xFFFFFFFF),
    sand: Color(0xFFF1EBE3),
    border: Color(0xFFE7E2DA),
    ink: Color(0xFF18181B),
    muted: Color(0xFF52525B),
    coral: Color(0xFFC83E4D),
    coralSoft: Color(0xFFFCE8EA),
    lavender: Color(0xFFE6E6FA),
    lavenderInk: Color(0xFF3730A3),
    mintSoft: Color(0xFFDCFCE7),
    mintInk: Color(0xFF166534),
    amberSoft: Color(0xFFFEF3C7),
    amberInk: Color(0xFF92400E),
    alertRed: Color(0xFFB91C1C),
    alertRedSoft: Color(0xFFFEE2E2),
    ctaBg: Color(0xFF18181B),
    ctaFg: Color(0xFFFFFFFF),
  );

  static const ViaLibrePalette dark = ViaLibrePalette(
    isDark: true,
    canvas: Color(0xFF141416),
    card: Color(0xFF1D1D1F),
    sand: Color(0xFF26262C),
    border: Color(0xFF363640),
    ink: Color(0xFFFAF8F5),
    muted: Color(0xFFB8B8C4),
    coral: Color(0xFFEF4756),
    coralSoft: Color(0xFF3A1E24),
    lavender: Color(0xFF292A44),
    lavenderInk: Color(0xFFDCE0FF),
    mintSoft: Color(0xFF163525),
    mintInk: Color(0xFF86EFAC),
    amberSoft: Color(0xFF3B2D14),
    amberInk: Color(0xFFFDE68A),
    alertRed: Color(0xFFFCA5A5),
    alertRedSoft: Color(0xFF421C20),
    ctaBg: Color(0xFFFAF8F5),
    ctaFg: Color(0xFF18181B),
  );

  @override
  ViaLibrePalette copyWith({
    bool? isDark,
    Color? canvas,
    Color? card,
    Color? sand,
    Color? border,
    Color? ink,
    Color? muted,
    Color? coral,
    Color? coralSoft,
    Color? lavender,
    Color? lavenderInk,
    Color? mintSoft,
    Color? mintInk,
    Color? amberSoft,
    Color? amberInk,
    Color? alertRed,
    Color? alertRedSoft,
    Color? ctaBg,
    Color? ctaFg,
  }) {
    return ViaLibrePalette(
      isDark: isDark ?? this.isDark,
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      sand: sand ?? this.sand,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      coral: coral ?? this.coral,
      coralSoft: coralSoft ?? this.coralSoft,
      lavender: lavender ?? this.lavender,
      lavenderInk: lavenderInk ?? this.lavenderInk,
      mintSoft: mintSoft ?? this.mintSoft,
      mintInk: mintInk ?? this.mintInk,
      amberSoft: amberSoft ?? this.amberSoft,
      amberInk: amberInk ?? this.amberInk,
      alertRed: alertRed ?? this.alertRed,
      alertRedSoft: alertRedSoft ?? this.alertRedSoft,
      ctaBg: ctaBg ?? this.ctaBg,
      ctaFg: ctaFg ?? this.ctaFg,
    );
  }

  @override
  ViaLibrePalette lerp(covariant ThemeExtension<ViaLibrePalette>? other, double t) {
    if (other is! ViaLibrePalette) return this;
    return ViaLibrePalette(
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      sand: Color.lerp(sand, other.sand, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralSoft: Color.lerp(coralSoft, other.coralSoft, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
      lavenderInk: Color.lerp(lavenderInk, other.lavenderInk, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      mintInk: Color.lerp(mintInk, other.mintInk, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      amberInk: Color.lerp(amberInk, other.amberInk, t)!,
      alertRed: Color.lerp(alertRed, other.alertRed, t)!,
      alertRedSoft: Color.lerp(alertRedSoft, other.alertRedSoft, t)!,
      ctaBg: Color.lerp(ctaBg, other.ctaBg, t)!,
      ctaFg: Color.lerp(ctaFg, other.ctaFg, t)!,
    );
  }
}

/// Sistema de diseño "Calma Urbana" de VíaLibre (WCAG 2.2 AA) con soporte Claro + Oscuro.
class ViaLibreTheme {
  ViaLibreTheme._();

  static const Color surfaceCanvas = Color(0xFFFAF8F5);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceSand = Color(0xFFF1EBE3);
  static const Color borderSubtle = Color(0xFFE7E2DA);
  static const Color inkPrimary = Color(0xFF18181B);
  static const Color textMuted = Color(0xFF52525B);
  static const Color accentCoral = Color(0xFFC83E4D);
  static const Color coralSoft = Color(0xFFFCE8EA);
  static const Color chipLavender = Color(0xFFE6E6FA);
  static const Color chipLavenderInk = Color(0xFF3730A3);
  static const Color mintSoft = Color(0xFFDCFCE7);
  static const Color successGreen = Color(0xFF166534);
  static const Color amberSoft = Color(0xFFFEF3C7);
  static const Color amberInk = Color(0xFF92400E);
  static const Color alertRed = Color(0xFFB91C1C);
  static const Color alertRedSoft = Color(0xFFFEE2E2);

  static ViaLibrePalette paletteOf(BuildContext context) {
    return Theme.of(context).extension<ViaLibrePalette>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? ViaLibrePalette.dark
            : ViaLibrePalette.light);
  }

  static const SystemUiOverlayStyle lightOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle darkOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkOverlayStyle : lightOverlayStyle;

  static ThemeData buildLightTheme({bool highContrast = false}) {
    return _buildTheme(
      palette: ViaLibrePalette.light,
      brightness: Brightness.light,
      highContrast: highContrast,
    );
  }

  static ThemeData buildDarkTheme({bool highContrast = false}) {
    return _buildTheme(
      palette: ViaLibrePalette.dark,
      brightness: Brightness.dark,
      highContrast: highContrast,
    );
  }

  static ThemeData _buildTheme({
    required ViaLibrePalette palette,
    required Brightness brightness,
    required bool highContrast,
  }) {
    final isDark = brightness == Brightness.dark;
    final muted = highContrast ? palette.ink : palette.muted;
    final borderColor = highContrast ? palette.ink : palette.border;
    final borderWidth = highContrast ? 2.0 : 1.0;
    final scaffoldBg = highContrast
        ? (isDark ? Colors.black : Colors.white)
        : palette.canvas;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: palette.ctaBg,
      onPrimary: palette.ctaFg,
      secondary: palette.coral,
      onSecondary: Colors.white,
      error: palette.alertRed,
      onError: isDark ? const Color(0xFF18181B) : Colors.white,
      surface: scaffoldBg,
      onSurface: palette.ink,
    );

    final baseText = GoogleFonts.interTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
      textTheme: baseText.copyWith(
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: palette.ink,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: palette.ink,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: palette.ink,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.45,
          color: palette.ink,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.4,
          color: muted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyleFor(brightness),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: borderWidth),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: palette.ink,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.card,
        selectedColor: palette.ctaBg,
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        labelStyle: TextStyle(
          color: palette.ink,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        hintStyle: TextStyle(color: muted, fontSize: 16),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: palette.ink, width: 2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.ctaBg,
        contentTextStyle: TextStyle(color: palette.ctaFg),
      ),
    );
  }
}
