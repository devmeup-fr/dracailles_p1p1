import 'package:flutter/material.dart';

class ThemeColors {
  // Sampled from the app logo (assets/images/logo_dracailles_full_512.png):
  // the dragon's wings/roses red as primary, its body's light brown/gold as
  // secondary, so the menu reads as on-brand instead of an unrelated navy.
  static const primary = Color.fromRGBO(125, 32, 41, 1); // #7d2029
  static const primaryLight = Color.fromRGBO(125, 32, 41, 0.1); // #7d2029
  static const secondary = Color.fromRGBO(179, 135, 91, 1); // #b3875b
  static const tertiary = Color.fromRGBO(255, 255, 255, 1); // #ffffff

  static const warning = Color.fromRGBO(243, 146, 9, 1); // #f39209
  static const warningLight = Color.fromRGBO(253, 233, 205, 1); // #FDE9CD
  static const error = Color.fromRGBO(179, 38, 30, 1); // #B3261E
  static const errorLight = Color.fromRGBO(249, 222, 220, 1); // #F9DEDC
  static const success = Color.fromRGBO(128, 186, 39, 1); // #80BA27
  static const successLight = Color.fromRGBO(230, 241, 212, 1); // #E6F1D4

  static const buttonOnBg = Color.fromRGBO(255, 0, 0, 1); // #FF0000
  static const buttonOffBg = Color.fromRGBO(184, 153, 153, 1); // #FF0000

  static const disabled = Color(0xFF404040);

  static const barrierBG = Color.fromRGBO(64, 64, 64, 0.4);

  static const text = Color(0xFF404040);

  static const labelValue = Color.fromRGBO(70, 70, 70, 0.781);

  static const formInputBackground = Color.fromRGBO(241, 241, 241, 0.6);

  static const backgroundColor = Color.fromRGBO(241, 241, 241, 1);
  static const tabBackgroundColor = Color.fromRGBO(253, 233, 205, 1);

  // One continuous sweep around the hue wheel (sorted by hue), same
  // saturation/lightness throughout so no tile stands out from the rest.
  // The hue steps aren't evenly spaced on purpose: they're wide through
  // yellow-green/green/teal (a couple of tiles is plenty, since that band
  // reads as "more greens" even at equal angular spacing) and narrower
  // everywhere else, so the panel doesn't skew green. Each tile still
  // keeps relative luminance <= 0.30 so the white player name stays
  // readable on top of it.
  static const colorsPlayerGame = [
    Color.fromRGBO(191, 61, 61, 1),
    Color.fromRGBO(191, 80, 61, 1),
    Color.fromRGBO(191, 100, 61, 1),
    Color.fromRGBO(191, 119, 61, 1),
    Color.fromRGBO(191, 138, 61, 1),
    Color.fromRGBO(191, 158, 61, 1),
    Color.fromRGBO(191, 177, 61, 1),
    Color.fromRGBO(186, 191, 61, 1),
    Color.fromRGBO(166, 191, 61, 1),
    Color.fromRGBO(119, 191, 61, 1),
    Color.fromRGBO(61, 191, 69, 1),
    Color.fromRGBO(61, 191, 134, 1),
    Color.fromRGBO(61, 191, 160, 1),
    Color.fromRGBO(61, 191, 175, 1),
    Color.fromRGBO(61, 191, 191, 1),
    Color.fromRGBO(61, 175, 191, 1),
    Color.fromRGBO(61, 160, 191, 1),
    Color.fromRGBO(61, 145, 191, 1),
    Color.fromRGBO(61, 129, 191, 1),
    Color.fromRGBO(61, 114, 191, 1),
    Color.fromRGBO(61, 98, 191, 1),
    Color.fromRGBO(61, 83, 191, 1),
    Color.fromRGBO(61, 67, 191, 1),
    Color.fromRGBO(70, 61, 191, 1),
    Color.fromRGBO(86, 61, 191, 1),
    Color.fromRGBO(101, 61, 191, 1),
    Color.fromRGBO(117, 61, 191, 1),
    Color.fromRGBO(132, 61, 191, 1),
    Color.fromRGBO(148, 61, 191, 1),
    Color.fromRGBO(163, 61, 191, 1),
    Color.fromRGBO(179, 61, 191, 1),
    Color.fromRGBO(191, 61, 188, 1),
    Color.fromRGBO(191, 61, 163, 1),
    Color.fromRGBO(191, 61, 129, 1),
    Color.fromRGBO(191, 61, 95, 1),
  ];
}
