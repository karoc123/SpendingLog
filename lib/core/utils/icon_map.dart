import 'package:flutter/material.dart';

/// Maps icon name strings (stored in database) to Material Icons.
IconData iconFromName(String name) {
  const map = <String, IconData>{
    'shopping_cart': Icons.shopping_cart,
    'home': Icons.home,
    'sports_esports': Icons.sports_esports,
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'favorite': Icons.favorite,
    'work': Icons.work,
    'category': Icons.category,
    'local_grocery_store': Icons.local_grocery_store,
    'flight': Icons.flight,
    'school': Icons.school,
    'pets': Icons.pets,
    'savings': Icons.savings,
    'child_care': Icons.child_care,
    'fitness_center': Icons.fitness_center,
    'movie': Icons.movie,
    'music_note': Icons.music_note,
    'phone': Icons.phone,
    'wifi': Icons.wifi,
    'attach_money': Icons.attach_money,
    'receipt': Icons.receipt,
    'card_giftcard': Icons.card_giftcard,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'local_hospital': Icons.local_hospital,
    'local_gas_station': Icons.local_gas_station,
  };
  return map[name] ?? Icons.category;
}

/// Available icon names for category creation UI.
const availableIconNames = [
  'shopping_cart',
  'home',
  'sports_esports',
  'restaurant',
  'directions_car',
  'favorite',
  'work',
  'category',
  'local_grocery_store',
  'flight',
  'school',
  'pets',
  'savings',
  'child_care',
  'fitness_center',
  'movie',
  'music_note',
  'phone',
  'attach_money',
  'receipt',
  'local_cafe',
  'local_bar',
  'local_hospital',
  'local_gas_station',
];

/// Available colors for category creation.
const availableCategoryColors = [
  0xFF4CAF50, // Green
  0xFF2196F3, // Blue
  0xFFFF9800, // Orange
  0xFFE91E63, // Pink
  0xFF9C27B0, // Purple
  0xFFF44336, // Red
  0xFF607D8B, // Blue Grey
  0xFF795548, // Brown
  0xFF00BCD4, // Cyan
  0xFFFFEB3B, // Yellow
  0xFF3F51B5, // Indigo
  0xFF009688, // Teal
];
