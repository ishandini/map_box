import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Route Colors
  static const Color routeOrange = Color(0xFFFFA726);
  static const Color progressGreen = Color(0xFF19b30b);

  // Marker Colors
  static const Color landmarkMarker = Color(0xFFFF5722);
  static const Color userMarker = Color(0xFF2196F3);

  // Status Colors - Reached
  static const Color statusReachedBackground = Color(0xFFFFF9C4);
  static const Color statusReachedIcon = Color(0xFFF57F17);

  // Status Colors - Locked
  static const Color statusLockedBackground = Color(0xFFFFE0B2);
  static const Color statusLockedIcon = Color(0xFFE65100);
  static const Color statusLockedButton = Color(0xFFFF9800);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color mediumGrey = Color(0xFF757575);

  // Background Colors
  static const Color lightOrangeBackground = Color(0xFFFFF3E0);
  static const Color errorBackground = Color(0xFFFF5722);

  // Theme
  static const Color themePrimary = Colors.green;

  // Mapbox integer color values (for Mapbox SDK which requires int, not Color)
  static const int routeOrangeInt = 0xFFFFA726;
  static const int progressGreenInt = 0xFF19b30b;
  static const int landmarkMarkerInt = 0xFFFF5722;
  static const int userMarkerInt = 0xFF2196F3;
  static const int whiteInt = 0xFFFFFFFF;
  static const int blackInt = 0xFF000000;
}
