import 'package:flutter/material.dart';

const walletPrimary = Color(0xFF0F4C5C);
const walletLightBackground = Color(0xFFF4F7F8);
const walletDarkBackground = Color(0xFF07141D);

const walletSuccessLight = Color(0xFF15803D);
const walletSuccessDark = Color(0xFF86EFAC);
const walletExpenseLight = Color(0xFFB42318);
const walletExpenseDark = Color(0xFFFCA5A5);
const walletWarningLight = Color(0xFFB7791F);
const walletWarningDark = Color(0xFFFACC15);

ThemeData buildWalletTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final baseScheme = ColorScheme.fromSeed(
    seedColor: walletPrimary,
    brightness: brightness,
  );
  final scheme = baseScheme.copyWith(
    primary: isDark ? const Color(0xFF5EEAD4) : walletPrimary,
    onPrimary: isDark ? const Color(0xFF052E34) : Colors.white,
    primaryContainer: isDark
        ? const Color(0xFF123C46)
        : const Color(0xFFD9F2EE),
    onPrimaryContainer: isDark
        ? const Color(0xFFD4FBF4)
        : const Color(0xFF06343B),
    secondary: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
    onSecondary: isDark ? const Color(0xFF082F49) : Colors.white,
    secondaryContainer: isDark
        ? const Color(0xFF17365E)
        : const Color(0xFFDCEAFE),
    onSecondaryContainer: isDark
        ? const Color(0xFFDCEAFE)
        : const Color(0xFF102A56),
    error: isDark ? walletExpenseDark : walletExpenseLight,
    surface: isDark ? const Color(0xFF0D1B26) : Colors.white,
    surfaceContainerLowest: isDark ? const Color(0xFF0A1721) : Colors.white,
    surfaceContainerLow: isDark
        ? const Color(0xFF102330)
        : const Color(0xFFF9FBFC),
    surfaceContainer: isDark
        ? const Color(0xFF132A38)
        : const Color(0xFFF3F6F8),
    surfaceContainerHigh: isDark
        ? const Color(0xFF1A3444)
        : const Color(0xFFEAF0F3),
    surfaceContainerHighest: isDark
        ? const Color(0xFF203B4C)
        : const Color(0xFFE2EAEE),
    outlineVariant: isDark ? const Color(0xFF2A4858) : const Color(0xFFD8E1E5),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark
        ? walletDarkBackground
        : walletLightBackground,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? walletDarkBackground : walletLightBackground,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.08),
      surfaceTintColor: Colors.transparent,
      color: scheme.surface,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.65 : 0.85),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: isDark ? 1 : 3,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? const Color(0xFFEAF3F5)
          : const Color(0xFF10212C),
      contentTextStyle: TextStyle(
        color: isDark ? const Color(0xFF10212C) : Colors.white,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

Color walletSuccessColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? walletSuccessDark
      : walletSuccessLight;
}

Color walletExpenseColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? walletExpenseDark
      : walletExpenseLight;
}

Color walletWarningColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? walletWarningDark
      : walletWarningLight;
}

Color walletBalanceCardColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF102F3A)
      : walletPrimary;
}
