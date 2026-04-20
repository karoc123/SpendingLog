import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';

import '../database/app_database.dart';

Future<void> seedDefaultCategories(AppDatabase db, String localeCode) async {
  final assetPath = localeCode == 'en'
      ? 'assets/default_categories/en_defaults.json'
      : 'assets/default_categories/de_defaults.json';
  final jsonString = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
  final categories = decoded['categories'];
  if (categories is! List) return;

  for (var parentIndex = 0; parentIndex < categories.length; parentIndex++) {
    final parentJson = categories[parentIndex];
    if (parentJson is! Map<String, dynamic>) continue;

    final parentName = (parentJson['name'] as String?)?.trim();
    if (parentName == null || parentName.isEmpty) continue;

    final parentIcon =
        (parentJson['icon_name'] as String?)?.trim().isNotEmpty == true
        ? parentJson['icon_name'] as String
        : 'category';
    final parentColor = _parseColorValue(parentJson['color_value']);

    final parentId = await db.insertCategory(
      CategoriesCompanion.insert(
        name: parentName,
        iconName: Value(parentIcon),
        colorValue: Value(parentColor),
        sortOrder: Value(parentIndex),
        createdAt: Value(DateTime.now()),
      ),
    );

    final subcategories = parentJson['subcategories'];
    if (subcategories is! List) continue;

    for (var subIndex = 0; subIndex < subcategories.length; subIndex++) {
      final subJson = subcategories[subIndex];
      if (subJson is! Map<String, dynamic>) continue;

      final subName = (subJson['name'] as String?)?.trim();
      if (subName == null || subName.isEmpty) continue;

      final subIcon =
          (subJson['icon_name'] as String?)?.trim().isNotEmpty == true
          ? subJson['icon_name'] as String
          : parentIcon;

      await db.insertCategory(
        CategoriesCompanion.insert(
          name: subName,
          parentId: Value(parentId),
          iconName: Value(subIcon),
          colorValue: Value(parentColor),
          sortOrder: Value(subIndex),
          createdAt: Value(DateTime.now()),
        ),
      );
    }
  }
}

int _parseColorValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0xFF9E9E9E;
}
