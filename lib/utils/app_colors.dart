import 'package:flutter/material.dart';

class AppColors {
  // Primary color - agricultural green
  static const Color primaryColor = Color(0xFF2E7D32);
  
  // Secondary color - earthy orange
  static const Color secondaryColor = Color(0xFFE65100);
  
  // Accent color - fresh blue
  static const Color accentColor = Color(0xFF1976D2);
  
  // Background colors
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFFBDBDBD);
  
  // Status colors
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
  
  // Other UI colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  
  // Category colors
  static final Map<String, Color> categoryColors = {
    'Grains & Cereals': Color(0xFFFFB74D),
    'Fruits': Color(0xFFAED581),
    'Vegetables': Color(0xFF81C784),
    'Dairy': Color(0xFF90CAF9),
    'Meat': Color(0xFFE57373),
    'Spices': Color(0xFFFFD54F),
    'Others': Color(0xFFB39DDB),
  };
  
  // Get color for category
  static Color getCategoryColor(String category) {
    return categoryColors[category] ?? primaryColor;
  }
}