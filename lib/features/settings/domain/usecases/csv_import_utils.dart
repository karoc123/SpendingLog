import '../../../../core/utils/icon_map.dart';
import '../../../categories/domain/repositories/category_repository.dart';
import '../../../expenses/domain/repositories/expense_repository.dart';

const seedDefaultParentNames = {
  'lebensmittel',
  'haushalt',
  'freizeit',
  'essen',
  'transport',
  'gesundheit',
  'arbeit',
  'sonstiges',
};

class CsvImportUtils {
  static double? parseAmount(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;

    final hasComma = s.contains(',');
    final hasDot = s.contains('.');

    if (hasComma && hasDot) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }

    return double.tryParse(s);
  }

  static String normalizeName(String name) => name.trim().toLowerCase();

  static String subcategoryKey(int parentId, String subcategoryName) {
    return '$parentId::${normalizeName(subcategoryName)}';
  }

  static int deterministicColor(String name) {
    var hash = 0;
    for (final code in name.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return availableCategoryColors[hash % availableCategoryColors.length];
  }

  static Future<void> cleanupUnusedSeedDefaults({
    required CategoryRepository categoryRepository,
    required ExpenseRepository expenseRepository,
  }) async {
    final allCategories = await categoryRepository.getAllCategories();
    final allExpenses = await expenseRepository.getAllExpenses();
    final usedCategoryIds = allExpenses.map((e) => e.categoryId).toSet();

    final categoryById = {for (final c in allCategories) c.id: c};
    final usedWithAncestors = <int>{...usedCategoryIds};
    for (final id in usedCategoryIds) {
      var current = categoryById[id];
      while (current?.parentId != null) {
        usedWithAncestors.add(current!.parentId!);
        current = categoryById[current.parentId!];
      }
    }

    for (final category in allCategories) {
      if (category.parentId != null) continue;
      final normalized = normalizeName(category.name);
      if (!seedDefaultParentNames.contains(normalized)) continue;
      if (usedWithAncestors.contains(category.id)) continue;
      final hasChildren = allCategories.any((c) => c.parentId == category.id);
      if (hasChildren) continue;
      await categoryRepository.deleteCategory(category.id);
    }
  }
}
