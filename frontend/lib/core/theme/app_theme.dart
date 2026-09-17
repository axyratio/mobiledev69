import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Radius scale from the Nocturne design system (see the project's design
/// reference), exposed as a [ThemeExtension] so widgets can read
/// `Theme.of(context).extension<NocturneRadii>()` instead of hardcoding
/// magic numbers.
class NocturneRadii extends ThemeExtension<NocturneRadii> {
  const NocturneRadii({this.sm = 4, this.md = 8, this.lg = 14});

  final double sm;
  final double md;
  final double lg;

  @override
  NocturneRadii copyWith({double? sm, double? md, double? lg}) {
    return NocturneRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
    );
  }

  @override
  NocturneRadii lerp(ThemeExtension<NocturneRadii>? other, double t) => this;
}

/// Light/dark [ThemeData] built from the Nocturne color ramps in the design
/// reference. Primary CTAs across the mockups are accent-bordered outlines,
/// not filled — [OutlinedButtonThemeData] carries that everywhere, not just
/// on a case-by-case basis.
class AppTheme {
  AppTheme._();

  static const _radii = NocturneRadii();

  static ThemeData get light => _build(
    background: const Color(0xFFF3F5FE),
    surface: const Color(0xFFFBFCFF),
    text: const Color(0xFF292B31),
    muted: const Color(0xFF595D6C),
    accent: const Color(0xFF796CBF),
    accentStrong: const Color(0xFF5D5294),
    accentContainer: const Color(0xFFE7E5FE),
    divider: const Color(0x24292B31),
    error: const Color(0xFFA4453F),
    errorContainer: const Color(0xFFF7E6E5),
    brightness: Brightness.light,
  );

  static ThemeData get dark => _build(
    background: const Color(0xFF161826),
    surface: const Color(0xFF232532),
    text: const Color(0xFFE9E9ED),
    muted: const Color(0xFF9397AB),
    accent: const Color(0xFF9184D9),
    accentStrong: const Color(0xFFB5ABFC),
    accentContainer: const Color(0xFF2B2741),
    divider: const Color(0x29E9E9ED),
    error: const Color(0xFFE08A8A),
    errorContainer: const Color(0xFF3A2630),
    brightness: Brightness.dark,
  );

  static ThemeData _build({
    required Color background,
    required Color surface,
    required Color text,
    required Color muted,
    required Color accent,
    required Color accentStrong,
    required Color accentContainer,
    required Color divider,
    required Color error,
    required Color errorContainer,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: brightness == Brightness.light ? Colors.white : background,
      primaryContainer: accentContainer,
      onPrimaryContainer: accentStrong,
      secondary: accentStrong,
      onSecondary: brightness == Brightness.light ? Colors.white : background,
      surface: surface,
      onSurface: text,
      error: error,
      onError: brightness == Brightness.light ? Colors.white : background,
      errorContainer: errorContainer,
      onErrorContainer: error,
      outline: divider,
    );

    final textTheme = _textTheme(text, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      extensions: const [_radii],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radii.md),
          side: BorderSide(color: divider),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: muted),
        labelStyle: textTheme.bodySmall?.copyWith(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radii.md),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radii.md),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radii.md),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radii.md),
          borderSide: BorderSide(color: error),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentStrong,
          side: BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radii.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radii.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentStrong),
      ),
      iconTheme: IconThemeData(color: muted),
      dividerTheme: DividerThemeData(color: divider, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: divider),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radii.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Inter for latin glyphs, Noto Sans Thai as the fallback for Thai text —
  /// mirrors the mockup's `font-family: 'Inter','Noto Sans Thai',sans-serif`.
  static TextTheme _textTheme(Color text, Color muted) {
    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: text,
      displayColor: text,
    );
    final thaiFallback = [GoogleFonts.notoSansThai().fontFamily!];

    TextStyle? withFallback(TextStyle? style) =>
        style?.copyWith(fontFamilyFallback: thaiFallback);

    return TextTheme(
      displayLarge: withFallback(base.displayLarge),
      displayMedium: withFallback(base.displayMedium),
      displaySmall: withFallback(base.displaySmall),
      headlineLarge: withFallback(base.headlineLarge),
      headlineMedium: withFallback(base.headlineMedium),
      headlineSmall: withFallback(base.headlineSmall),
      titleLarge: withFallback(
        base.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: -0.01,
        ),
      ),
      titleMedium: withFallback(
        base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
        ),
      ),
      titleSmall: withFallback(
        base.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      ),
      bodyLarge: withFallback(base.bodyLarge),
      bodyMedium: withFallback(base.bodyMedium?.copyWith(color: muted)),
      bodySmall: withFallback(base.bodySmall?.copyWith(color: muted)),
      labelLarge: withFallback(
        base.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      labelMedium: withFallback(base.labelMedium),
      labelSmall: withFallback(base.labelSmall),
    );
  }
}
