import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final expensesAsync = ref.watch(expenseListProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final dateFormat = DateFormat.yMMMd('de_DE');

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.transactions ?? 'Transaktionen')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n?.searchTransactions ?? 'Suchen…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Category filter
                Expanded(
                  child: categoriesAsync.when(
                    data: (categories) {
                      final parents = categories
                          .where((c) => c.parentId == null)
                          .toList();
                      return DropdownButtonFormField<int?>(
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: l10n?.filterCategory ?? 'Kategorie',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(l10n?.allCategories ?? 'Alle'),
                          ),
                          ...parents.map(
                            (c) => DropdownMenuItem<int?>(
                              value: c.id,
                              child: Text(
                                c.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedCategoryId = value),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(width: 8),
                // Date range filter
                IconButton.outlined(
                  icon: Icon(
                    Icons.date_range,
                    color: _dateRange != null
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: now,
                      initialDateRange:
                          _dateRange ??
                          DateTimeRange(
                            start: DateTime(now.year, now.month, 1),
                            end: now,
                          ),
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    }
                  },
                ),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: l10n?.clearFilter ?? 'Filter zurücksetzen',
                    onPressed: () => setState(() => _dateRange = null),
                  ),
              ],
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${dateFormat.format(_dateRange!.start)} – ${dateFormat.format(_dateRange!.end)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(),
          // Expense list
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                final categories = categoriesAsync.value ?? [];
                final categoryMap = {for (final c in categories) c.id: c};

                final filtered = _applyFilters(expenses, categoryMap);

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(l10n?.noExpenses ?? 'Keine Ausgaben'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final expense = filtered[index];
                    final category = categoryMap[expense.categoryId];
                    return _ExpenseTile(
                      expense: expense,
                      category: category,
                      dateFormat: dateFormat,
                      onEdit: () => _showEditSheet(expense, categories),
                      onDelete: () => _confirmDelete(expense),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }

  List<ExpenseEntity> _applyFilters(
    List<ExpenseEntity> expenses,
    Map<int, CategoryEntity> categoryMap,
  ) {
    var result = expenses;

    // Text search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((e) {
        if (e.description.toLowerCase().contains(q)) return true;
        if (e.notes != null && e.notes!.toLowerCase().contains(q)) return true;
        final cat = categoryMap[e.categoryId];
        if (cat != null && cat.name.toLowerCase().contains(q)) return true;
        return false;
      }).toList();
    }

    // Category filter (include subcategories of the selected parent)
    if (_selectedCategoryId != null) {
      final childIds =
          categoryMap.values
              .where((c) => c.parentId == _selectedCategoryId)
              .map((c) => c.id)
              .toSet()
            ..add(_selectedCategoryId!);
      result = result.where((e) => childIds.contains(e.categoryId)).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end.add(
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );
      result = result
          .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
          .toList();
    }

    return result;
  }

  void _showEditSheet(ExpenseEntity expense, List<CategoryEntity> categories) {
    final amountCtrl = TextEditingController(
      text: (expense.amountCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    final descCtrl = TextEditingController(text: expense.description);
    final notesCtrl = TextEditingController(text: expense.notes ?? '');
    var editCategoryId = expense.categoryId;
    var editDate = expense.date;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.editExpense ?? 'Ausgabe bearbeiten',
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n?.amount ?? 'Betrag',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: l10n?.description ?? 'Beschreibung',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 96),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: categories
                              .where((c) => c.parentId == null)
                              .map((cat) {
                                return ChoiceChip(
                                  label: Text(cat.name),
                                  selected: editCategoryId == cat.id,
                                  selectedColor: Color(
                                    cat.colorValue,
                                  ).withValues(alpha: 0.3),
                                  onSelected: (_) => setSheetState(
                                    () => editCategoryId = cat.id,
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(DateFormat.yMMMd('de_DE').format(editDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: editDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSheetState(() => editDate = picked);
                        }
                      },
                    ),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: l10n?.notes ?? 'Notizen (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final cents = parseAmountToCents(amountCtrl.text);
                          if (cents == null || descCtrl.text.trim().isEmpty) {
                            return;
                          }
                          final updated = expense.copyWith(
                            amountCents: cents,
                            description: descCtrl.text.trim(),
                            categoryId: editCategoryId,
                            date: editDate,
                            notes: () => notesCtrl.text.trim().isNotEmpty
                                ? notesCtrl.text.trim()
                                : null,
                            updatedAt: DateTime.now(),
                          );
                          ref.read(updateExpenseProvider).call(updated);
                          Navigator.pop(ctx);
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

  void _confirmDelete(ExpenseEntity expense) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.delete ?? 'Löschen'),
        content: Text(
          '${expense.description} – ${formatAmount(expense.amountCents)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              ref.read(deleteExpenseProvider).call(expense.id);
              Navigator.pop(ctx);
            },
            child: Text(l10n?.delete ?? 'Löschen'),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseEntity expense;
  final CategoryEntity? category;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.dateFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: category != null
            ? Color(category!.colorValue).withValues(alpha: 0.2)
            : null,
        child: Icon(
          category != null ? iconFromName(category!.iconName) : Icons.category,
          color: category != null ? Color(category!.colorValue) : null,
        ),
      ),
      title: Text(
        expense.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${category?.name ?? ''} · ${dateFormat.format(expense.date)}',
      ),
      trailing: Text(
        formatAmount(expense.amountCents),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      onTap: onEdit,
      onLongPress: onDelete,
    );
  }
}
