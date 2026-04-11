import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/utils/screen_help.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  final int? initialCategoryId;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final String? initialSearchQuery;

  const TransactionsScreen({
    super.key,
    this.initialCategoryId,
    this.initialStart,
    this.initialEnd,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategoryId;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    if (widget.initialStart != null && widget.initialEnd != null) {
      _dateRange = DateTimeRange(
        start: widget.initialStart!,
        end: widget.initialEnd!,
      );
    }
    if ((widget.initialSearchQuery ?? '').trim().isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!.trim();
      _searchController.text = _searchQuery;
    }
  }

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
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.transactions ?? 'Transaktionen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showScreenHelp(
              context,
              deTitle: 'Hilfe: Transaktionen',
              enTitle: 'Help: Transactions',
              deBody:
                  'Suche und filtere Transaktionen nach Zeitraum und Kategorie. Die Liste zeigt Monatswechsel und Summen.',
              enBody:
                  'Search and filter transactions by date and category. The list includes month separators and totals.',
            ),
          ),
        ],
      ),
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
                      return InkWell(
                        onTap: () async {
                          final selection =
                              await _showCategoryFilterPickerModal(
                                context,
                                categories,
                                selectedCategoryId: _selectedCategoryId,
                                allLabel: l10n?.allCategories ?? 'Alle',
                              );
                          if (selection == null) return;
                          setState(
                            () => _selectedCategoryId = selection == -1
                                ? null
                                : selection,
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n?.filterCategory ?? 'Kategorie',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: const Icon(Icons.chevron_right),
                          ),
                          child: Text(
                            _selectedCategoryId == null
                                ? (l10n?.allCategories ?? 'Alle')
                                : _categoryLabel(
                                    categories,
                                    _selectedCategoryId,
                                    fallback: l10n?.allCategories ?? 'Alle',
                                  ),
                          ),
                        ),
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
                final totalCents = filtered.fold<int>(
                  0,
                  (sum, expense) => sum + expense.amountCents,
                );

                if (filtered.isEmpty) {
                  return Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(l10n?.noExpenses ?? 'Keine Ausgaben'),
                        ),
                      ),
                      _TotalFooter(
                        totalCents: 0,
                        currencySymbol: currencySymbol,
                        count: 0,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          final category = categoryMap[expense.categoryId];
                          final previous = index > 0
                              ? filtered[index - 1]
                              : null;
                          final showMonthHeader =
                              previous == null ||
                              previous.date.year != expense.date.year ||
                              previous.date.month != expense.date.month;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showMonthHeader)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    10,
                                    16,
                                    6,
                                  ),
                                  child: Text(
                                    DateFormat.yMMMM(
                                      Localizations.localeOf(
                                        context,
                                      ).toString(),
                                    ).format(expense.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              _ExpenseTile(
                                expense: expense,
                                category: category,
                                categoryPath: _categoryPath(
                                  categoryMap,
                                  expense.categoryId,
                                ),
                                currencySymbol: currencySymbol,
                                dateFormat: dateFormat,
                                onEdit: () =>
                                    _showEditSheet(expense, categories),
                                onDelete: () => _confirmDelete(expense),
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        },
                      ),
                    ),
                    _TotalFooter(
                      totalCents: totalCents,
                      currencySymbol: currencySymbol,
                      count: filtered.length,
                    ),
                  ],
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
      final end = DateTime(
        _dateRange!.end.year,
        _dateRange!.end.month,
        _dateRange!.end.day,
        23,
        59,
        59,
      );
      result = result
          .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
          .toList();
    }

    return result;
  }

  String _categoryPath(Map<int, CategoryEntity> categoryMap, int categoryId) {
    final category = categoryMap[categoryId];
    if (category == null) return '';
    if (category.parentId == null) return category.name;
    final parent = categoryMap[category.parentId];
    if (parent == null) return category.name;
    return '${parent.name} -> ${category.name}';
  }

  String _categoryLabel(
    List<CategoryEntity> categories,
    int? categoryId, {
    required String fallback,
  }) {
    if (categoryId == null) return fallback;
    final category = categories.where((c) => c.id == categoryId).firstOrNull;
    if (category == null) return fallback;
    if (category.parentId == null) return category.name;
    final parent = categories
        .where((c) => c.id == category.parentId)
        .firstOrNull;
    if (parent == null) return category.name;
    return '${parent.name} -> ${category.name}';
  }

  Future<int?> _showCategoryPickerModal(
    BuildContext context,
    List<CategoryEntity> categories, {
    int? selectedCategoryId,
  }) {
    int? activeParentId = categories
        .where((c) => c.id == selectedCategoryId)
        .firstOrNull
        ?.parentId;

    return showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final visibleCategories = activeParentId == null
                ? categories.where((c) => c.parentId == null).toList()
                : categories
                      .where((c) => c.parentId == activeParentId)
                      .toList();
            final activeParent = activeParentId == null
                ? null
                : categories.where((c) => c.id == activeParentId).firstOrNull;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewPadding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (activeParentId != null)
                        IconButton(
                          onPressed: () =>
                              setModalState(() => activeParentId = null),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      Expanded(
                        child: Text(
                          activeParent?.name ?? 'Kategorie',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          AppLocalizations.of(context)?.cancel ?? 'Abbrechen',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: visibleCategories.length,
                      itemBuilder: (ctx, index) {
                        final category = visibleCategories[index];
                        final hasChildren = categories.any(
                          (c) => c.parentId == category.id,
                        );
                        final isSelected = selectedCategoryId == category.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              category.colorValue,
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              iconFromName(category.iconName),
                              size: 18,
                            ),
                          ),
                          title: Text(category.name),
                          trailing: hasChildren
                              ? const Icon(Icons.chevron_right)
                              : (isSelected ? const Icon(Icons.check) : null),
                          onTap: () {
                            if (hasChildren) {
                              setModalState(() => activeParentId = category.id);
                              return;
                            }
                            Navigator.pop(ctx, category.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<int?> _showCategoryFilterPickerModal(
    BuildContext context,
    List<CategoryEntity> categories, {
    int? selectedCategoryId,
    required String allLabel,
  }) {
    int? activeParentId = categories
        .where((c) => c.id == selectedCategoryId)
        .firstOrNull
        ?.parentId;

    return showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final visibleCategories = activeParentId == null
                ? categories.where((c) => c.parentId == null).toList()
                : categories
                      .where((c) => c.parentId == activeParentId)
                      .toList();
            final activeParent = activeParentId == null
                ? null
                : categories.where((c) => c.id == activeParentId).firstOrNull;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewPadding.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (activeParentId != null)
                        IconButton(
                          onPressed: () =>
                              setModalState(() => activeParentId = null),
                          icon: const Icon(Icons.arrow_back),
                        ),
                      Expanded(
                        child: Text(
                          activeParent?.name ?? 'Kategorie',
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          AppLocalizations.of(context)?.cancel ?? 'Abbrechen',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (activeParentId == null)
                    ListTile(
                      leading: const Icon(Icons.layers_clear),
                      title: Text(allLabel),
                      onTap: () => Navigator.pop(ctx, -1),
                    ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: visibleCategories.length,
                      itemBuilder: (ctx, index) {
                        final category = visibleCategories[index];
                        final hasChildren = categories.any(
                          (c) => c.parentId == category.id,
                        );
                        final isSelected = selectedCategoryId == category.id;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Color(
                              category.colorValue,
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              iconFromName(category.iconName),
                              size: 18,
                            ),
                          ),
                          title: Text(category.name),
                          trailing: hasChildren
                              ? const Icon(Icons.chevron_right)
                              : (isSelected ? const Icon(Icons.check) : null),
                          onTap: () {
                            if (hasChildren) {
                              setModalState(() => activeParentId = category.id);
                              return;
                            }
                            Navigator.pop(ctx, category.id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditSheet(ExpenseEntity expense, List<CategoryEntity> categories) {
    final amountCtrl = TextEditingController(
      text: (expense.amountCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    final descCtrl = TextEditingController(text: expense.description);
    final notesCtrl = TextEditingController(text: expense.notes ?? '');
    int? editCategoryId = expense.categoryId;
    var editDate = expense.date;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom +
                      MediaQuery.of(ctx).viewPadding.bottom +
                      16,
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
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: l10n?.notes ?? 'Notizen (optional)',
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      InkWell(
                        onTap: () async {
                          final selection = await _showCategoryPickerModal(
                            ctx,
                            categories,
                            selectedCategoryId: editCategoryId,
                          );
                          if (selection == null) return;
                          setSheetState(() => editCategoryId = selection);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Kategorie',
                            suffixIcon: const Icon(Icons.chevron_right),
                          ),
                          child: Text(
                            _categoryLabel(
                              categories,
                              editCategoryId,
                              fallback:
                                  l10n?.selectCategory ??
                                  'Bitte Kategorie wählen',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          DateFormat.yMMMd(
                            Localizations.localeOf(ctx).toString(),
                          ).format(editDate),
                        ),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton.outlined(
                          tooltip: 'Wiederkehrend erstellen',
                          onPressed: () {
                            final cents = parseAmountToCents(amountCtrl.text);
                            if (cents == null) return;
                            final uri = Uri(
                              path: '/recurring',
                              queryParameters: {
                                'name': descCtrl.text.trim(),
                                'amountCents': '$cents',
                                if (editCategoryId != null)
                                  'categoryId': '$editCategoryId',
                                'startDate': editDate.toIso8601String(),
                              },
                            ).toString();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              context.push(uri);
                            }
                          },
                          icon: const Icon(Icons.repeat),
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
                            ref.invalidate(spendingByCategoryProvider);
                            ref.invalidate(spendingSummaryProvider);
                            Navigator.pop(ctx);
                          },
                          child: Text(l10n?.save ?? 'Speichern'),
                        ),
                      ),
                    ],
                  ),
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
              ref.invalidate(spendingByCategoryProvider);
              ref.invalidate(spendingSummaryProvider);
              Navigator.pop(ctx);
            },
            child: Text(l10n?.delete ?? 'Löschen'),
          ),
        ],
      ),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  final int totalCents;
  final String currencySymbol;
  final int count;

  const _TotalFooter({
    required this.totalCents,
    required this.currencySymbol,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            '${l10n?.totalSpent ?? 'Gesamt'}: ($count)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const Spacer(),
          Text(
            formatAmount(totalCents, symbol: currencySymbol),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseEntity expense;
  final CategoryEntity? category;
  final String categoryPath;
  final String currencySymbol;
  final DateFormat dateFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.category,
    required this.categoryPath,
    required this.currencySymbol,
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
      subtitle: Text('$categoryPath · ${dateFormat.format(expense.date)}'),
      trailing: Text(
        formatAmount(expense.amountCents, symbol: currencySymbol),
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      onTap: onEdit,
      onLongPress: onDelete,
    );
  }
}
