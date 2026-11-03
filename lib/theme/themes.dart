import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';
import 'fantasy_theme.dart';
import 'styles.dart';

class Themes {
  static ThemeData light() => ThemeData(
    /// Colors
    brightness: Brightness.light,
    textTheme: ThemeStyles.textTheme.apply(
      fontFamily: GoogleFonts.roboto().fontFamily,
      bodyColor: ThemeColors.primary,
      displayColor: ThemeColors.primary,
    ),
    fontFamily: GoogleFonts.roboto().fontFamily,

    primaryColor: Colors.white,

    canvasColor: ThemeColors.primary,
    hoverColor: Colors.grey[200],
    focusColor: ThemeColors.secondary,

    // Appbar
    appBarTheme: const AppBarTheme(backgroundColor: ThemeColors.primary),

    /// input
    inputDecorationTheme: const InputDecorationTheme(
      labelStyle: TextStyle(color: ThemeColors.primary),
    ),

    /// Button
    buttonTheme: const ButtonThemeData(),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(),
    ),

    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom()),
    iconTheme: const IconThemeData(),

    cardTheme: const CardThemeData(color: Colors.white, elevation: 4),

    /// Dropdown theme
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
      ),
    ),

    colorScheme: const ColorScheme.light(
      primary: ThemeColors.primary,
      secondary: ThemeColors.secondary,
      tertiary: ThemeColors.tertiary,
      error: ThemeColors.error,
      surface: Color.fromRGBO(250, 248, 247, 1),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ThemeColors.primary,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    menuTheme: const MenuThemeData(),
  );

  static ThemeData dark() => ThemeData.dark();

  /// Écran de draft : la « table de jeu » sombre de l'écran de match
  /// (FantasyPalette), le rouge et l'or du logo pour les actions.
  static ThemeData draft() {
    const cs = ColorScheme.dark(
      primary: FantasyPalette.gold,
      onPrimary: FantasyPalette.obsidian,
      primaryContainer: ThemeColors.primary,
      onPrimaryContainer: FantasyPalette.parchment,
      secondary: ThemeColors.secondary,
      onSecondary: FantasyPalette.obsidian,
      tertiary: ThemeColors.tertiary,
      error: ThemeColors.error,
      onError: Colors.white,
      surface: FantasyPalette.obsidian,
      onSurface: FantasyPalette.parchment,
      onSurfaceVariant: FantasyPalette.parchmentDim,
      surfaceContainerLow: FantasyPalette.obsidianLight,
      surfaceContainer: FantasyPalette.obsidianLight,
      surfaceContainerHigh: Color(0xFF30231A),
      outline: FantasyPalette.goldDim,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: cs,
      scaffoldBackgroundColor: FantasyPalette.obsidian,
      textTheme: ThemeStyles.textTheme.apply(
        fontFamily: GoogleFonts.roboto().fontFamily,
        bodyColor: FantasyPalette.parchment,
        displayColor: FantasyPalette.parchment,
      ),
      fontFamily: GoogleFonts.roboto().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: FantasyPalette.obsidian,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FantasyPalette.obsidianLight,
        dragHandleColor: FantasyPalette.goldDim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          side: BorderSide(color: FantasyPalette.goldDim),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ThemeColors.primary,
          foregroundColor: FantasyPalette.parchment,
          textStyle: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: FantasyPalette.gold),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FantasyPalette.parchment,
          side: const BorderSide(color: FantasyPalette.goldDim),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
