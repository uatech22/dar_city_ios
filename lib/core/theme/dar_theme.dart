import 'package:flutter/material.dart';

/// Dar City v1 color palette — black/gray surfaces with red accent.
class DarColors {
  static const background = Color(0xFF000000);
  static const backgroundDark = Color(0xFF000000);
  static const surface = Color(0xFF1A1A1A);
  static const surfaceElevated = Color(0xFF121212);
  static const navBar = Color(0xFF2A2A2A);

  static const cardBrown = Color(0xFF2A2A2A);
  static const cardDark = Color(0xFF1A1A1A);
  static const inputBrown = Color(0xFF1A1A1A);
  static const inputDark = Color(0xFF1A1A1A);
  static const chocolateBrown = Color.fromARGB(255, 27, 17, 17);
  static const sandBrown = Color.fromARGB(255, 144, 102, 87);
  static const lightSandBrown = Color.fromARGB(255, 255, 171, 140);

  static const muted = Color(0xFFB0B0B0);
  static const mutedSecondary = Color(0x8FFFFFFF);
  static const accentRed = Color(0xFFFF4444);
  static const accentRedBright = Color(0xFFFF4444);

  static const green = Color(0xFF4CAF50);
  static const greenBright = Color(0xFF4CAF50);

  // Semantic aliases kept for screen files — all map to v1 red/gray.
  static const mutedPink = muted;
  static const eliteGold = accentRed;
  static const eliteCoral = accentRed;
  static const eliteCoralDark = accentRed;
  static const eliteBlue = accentRed;
  static const maroonBubble = cardDark;
  static const maroonDark = surfaceElevated;

  // Team roster list (team.jpeg reference)
  static const rosterBackground = Color(0xFFFFFFFF);
  static const rosterText = Color(0xFF111111);
  static const rosterMuted = Color(0xFF6B6B6B);
  static const rosterDivider = Color(0xFFE8E8E8);
  static const rosterNumber = Color(0xFFD4D4D4);
}
