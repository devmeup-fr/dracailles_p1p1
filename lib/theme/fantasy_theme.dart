import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual language for the match screen: a dark card-table instead of flat
/// color blocks, hero art framed like a physical card instead of full-bleed,
/// gold trim and a serif display face for numbers/headers - evokes the
/// physical game instead of a generic counter app.
class FantasyPalette {
  // Deep, slightly warm near-black - reads as "table in low light" rather
  // than a plain app background, and lets a framed hero portrait sit on top
  // of it as a distinct object instead of filling the whole tile.
  static const obsidian = Color(0xFF14100D);
  static const obsidianLight = Color(0xFF241A14);

  // Warm metallic gold for borders/trim - the one accent every player's
  // frame shares, regardless of their own color.
  static const gold = Color(0xFFC9A227);
  static const goldDim = Color(0xFF7A621C);

  // Off-white for text on dark backgrounds - true white reads cold/flat
  // against obsidian, parchment keeps the warm, aged-paper feel.
  static const parchment = Color(0xFFEFE3C8);
  static const parchmentDim = Color(0xFFBFB08C);
}

/// Serif display face for life totals and headers - a plain sans here read
/// as "generic counter app"; an engraved-looking serif reads as a game
/// artifact instead.
TextStyle fantasyDisplay({
  required double fontSize,
  Color color = FantasyPalette.parchment,
  FontWeight weight = FontWeight.w700,
}) => GoogleFonts.cinzel(fontSize: fontSize, color: color, fontWeight: weight);
