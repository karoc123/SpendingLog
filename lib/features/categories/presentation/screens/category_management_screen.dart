import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/delete_category.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.manageCategories ?? 'Kategorien verwalten'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final parents = categories.where((c) => c.parentId == null).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: parents.length,
            itemBuilder: (context, index) {
              final parent = parents[index];
              final children =
                  categories.where((c) => c.parentId == parent.id).toList()
                    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

              return ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    parent.colorValue,
                  ).withValues(alpha: 0.2),
                  child: Icon(
                    iconFromName(parent.iconName),
                    color: Color(parent.colorValue),
                    size: 20,
                  ),
                ),
                title: Text(parent.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showCategoryForm(context, ref, existing: parent),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () =>
                          _confirmDelete(context, ref, parent, categories),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      tooltip:
                          l10n?.addSubcategory ?? 'Unterkategorie hinzufügen',
                      onPressed: () =>
                          _showCategoryForm(context, ref, parentId: parent.id),
                    ),
                  ],
                ),
                children: children.map((child) {
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 72, right: 16),
                    leading: Icon(
                      iconFromName(child.iconName),
                      color: Color(child.colorValue),
                      size: 18,
                    ),
                    title: Text(child.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () =>
                              _showCategoryForm(context, ref, existing: child),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () =>
                              _confirmDelete(context, ref, child, categories),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
    List<CategoryEntity> allCategories,
  ) {
    final l10n = AppLocalizations.of(context);
    final others = allCategories.where((c) => c.id != category.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteCategory ?? 'Kategorie löschen'),
        content: Text(
          l10n?.deleteCategoryPrompt ??
              'Was soll mit den zugehörigen Ausgaben passieren?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(deleteCategoryProvider)
                  .call(
                    category.id,
                    action: DeleteCategoryAction.deleteExpenses,
                  );
              ref.invalidate(allCategoriesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n?.deleteWithExpenses ?? 'Mit Ausgaben löschen'),
          ),
          if (others.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showReassignDialog(context, ref, category, others);
              },
              child: Text(l10n?.reassignExpenses ?? 'Ausgaben verschieben'),
            ),
        ],
      ),
    );
  }

  void _showReassignDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
    List<CategoryEntity> others,
  ) {
    final l10n = AppLocalizations.of(context);
    int? targetId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n?.reassignTo ?? 'Verschieben nach'),
          content: DropdownButton<int>(
            isExpanded: true,
            value: targetId,
            hint: Text(l10n?.selectCategory ?? 'Kategorie wählen'),
            items: others
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setDialogState(() => targetId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n?.cancel ?? 'Abbrechen'),
            ),
            TextButton(
              onPressed: targetId != null
                  ? () async {
                      await ref
                          .read(deleteCategoryProvider)
                          .call(
                            category.id,
                            action: DeleteCategoryAction.reassign,
                            reassignToCategoryId: targetId,
                          );
                      ref.invalidate(allCategoriesProvider);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }
                  : null,
              child: Text(l10n?.confirm ?? 'Bestätigen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryForm(
    BuildContext context,
    WidgetRef ref, {
    CategoryEntity? existing,
    int? parentId,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedIcon = existing?.iconName ?? 'category';
    int selectedColor = existing?.colorValue ?? 0xFF4CAF50;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing != null
                          ? (l10n?.editCategory ?? 'Kategorie bearbeiten')
                          : parentId != null
                          ? (l10n?.addSubcategory ??
                                'Unterkategorie hinzufügen')
                          : (l10n?.addCategory ?? 'Kategorie hinzufügen'),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n?.name ?? 'Name',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Icon picker.
                    Text(
                      l10n?.icon ?? 'Symbol',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIconNames.map((name) {
                        final isSelected = name == selectedIcon;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedIcon = name),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(ctx).colorScheme.primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(ctx).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(iconFromName(name), size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Color picker.
                    Text(
                      l10n?.color ?? 'Farbe',
                      style: Theme.of(ctx).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableCategoryColors.map((color) {
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedColor = color),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Color(
                                          color,
                                        ).withValues(alpha: 0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          if (existing != null) {
                            await ref
                                .read(updateCategoryProvider)
                                .call(
                                  existing.copyWith(
                                    name: name,
                                    iconName: selectedIcon,
                                    colorValue: selectedColor,
                                  ),
                                );
                          } else {
                            await ref
                                .read(addCategoryProvider)
                                .call(
                                  CategoryEntity(
                                    id: 0,
                                    name: name,
                                    parentId: parentId ?? existing?.parentId,
                                    iconName: selectedIcon,
                                    colorValue: selectedColor,
                                    createdAt: DateTime.now(),
                                  ),
                                );
                          }
                          ref.invalidate(allCategoriesProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: Text(l10n?.save ?? 'Speichern'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
