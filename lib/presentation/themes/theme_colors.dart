// presentation/themes/theme_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color primary = Color(0xFF0066FF);
  static const Color onPrimary = Colors.white;
  static const Color secondary = Color(0xFF00C853);
  static const Color onSecondary = Colors.white;
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF1A1A1A);
  static const Color background = Color(0xFFF8F9FA);
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color error = Color(0xFFD32F2F);
  static const Color onError = Colors.white;
  static const Color surfaceVariant = Color(0xFFE8E9EB);
  static const Color onSurfaceVariant = Color(0xFF5F6368);
  static const Color outline = Color(0xFFDADCE0);
  
  // Status Colors
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF0066FF);
  
  // Property Status Colors
  static const Color statusOccupied = Color(0xFF00C853);
  static const Color statusVacant = Color(0xFFFFB300);
  static const Color statusMaintenance = Color(0xFFD32F2F);
  static const Color statusMarketing = Color(0xFF6200EE);
  static const Color statusPaid = Color(0xFF0066FF);
  
  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFF0066FF),
    Color(0xFF00C853),
    Color(0xFFFFB300),
    Color(0xFFD32F2F),
    Color(0xFF6200EE),
  ];
  
  // Dark Theme Colors
  static const Color primaryDark = Color(0xFF66A3FF);
  static const Color onPrimaryDark = Color(0xFF0A0A0A);
  static const Color secondaryDark = Color(0xFF66FF99);
  static const Color onSecondaryDark = Color(0xFF0A0A0A);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color onSurfaceDark = Color(0xFFE8E8E8);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color onBackgroundDark = Color(0xFFE8E8E8);
  static const Color errorDark = Color(0xFFF44336);
  static const Color onErrorDark = Colors.white;
  static const Color surfaceVariantDark = Color(0xFF2D2D2D);
  static const Color onSurfaceVariantDark = Color(0xFFA0A0A0);
  static const Color outlineDark = Color(0xFF3D3D3D);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0066FF), Color(0xFF00B8FF)],
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
  );
}