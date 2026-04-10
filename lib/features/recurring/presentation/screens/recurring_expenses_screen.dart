import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/screen_help.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../domain/entities/recurring_expense_entity.dart';

const _uuid = Uuid();

/// Watches all recurring expenses reactively.
final recurringExpenseListProvider =
    StreamProvider<List<RecurringExpenseEntity>>((ref) {
      return ref.watch(getRecurringExpensesProvider).watch();
    });

class RecurringExpensesScreen extends ConsumerStatefulWidget {
  final String? prefillName;
  final int? prefillAmountCents;
  final int? prefillCategoryId;
  final DateTime? prefillStartDate;

  const RecurringExpensesScreen({
    super.key,
    this.prefillName,
    this.prefillAmountCents,
    this.prefillCategoryId,
    this.prefillStartDate,
  });

  @override
  ConsumerState<RecurringExpensesScreen> createState() =>
      _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState
    extends ConsumerState<RecurringExpensesScreen> {
  bool _openedPrefill = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final recurringAsync = ref.watch(recurringExpenseListProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final categories = categoriesAsync.value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    if (!_openedPrefill &&
        categories.isNotEmpty &&
        widget.prefillName != null) {
      _openedPrefill = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showRecurringExpenseForm(
          context,
          ref,
          categories,
          prefillName: widget.prefillName,
          prefillAmountCents: widget.prefillAmountCents,
          prefillCategoryId: widget.prefillCategoryId,
          prefillStartDate: widget.prefillStartDate,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.recurringExpenses ?? 'Wiederkehrende Ausgaben'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showScreenHelp(
              context,
              deTitle: 'Hilfe: Wiederkehrende Ausgaben',
              enTitle: 'Help: Recurring Expenses',
              deBody:
                  'Hier legst du monatliche oder jährliche Regeln an. Du kannst Regeln bearbeiten, deaktivieren oder sofort eine Ausgabe erzeugen.',
              enBody:
                  'Manage monthly or yearly recurring rules. You can edit rules, deactivate them, or generate an expense immediately.',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecurringExpenseForm(context, ref, categories),
        child: const Icon(Icons.add),
      ),
      body: recurringAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Text(
                l10n?.noRecurringExpenses ?? 'Keine wiederkehrenden Ausgaben',
              ),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final item = items[index];
              final cat = catMap[item.categoryId];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    cat?.colorValue ?? 0xFF9E9E9E,
                  ).withValues(alpha: 0.2),
                  child: const Icon(Icons.repeat, size: 20),
                ),
                title: Text(item.name),
                subtitle: Text(
                  '${_categoryPath(catMap, item.categoryId)} · ${item.interval == RecurringInterval.monthly ? (l10n?.monthly ?? 'Monatlich') : (l10n?.yearly ?? 'Jährlich')} · ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(item.startDate)}',
                ),
                trailing: Text(
                  formatAmount(item.amountCents, symbol: currencySymbol),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                onTap: () => _showRecurringExpenseForm(
                  context,
                  ref,
                  categories,
                  existing: item,
                ),
                onLongPress: () => _confirmDelete(context, ref, item),
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
    RecurringExpenseEntity item,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.deleteRecurring ?? 'Löschen?'),
        content: Text(
          l10n?.deleteRecurringConfirm ??
              'Wiederkehrende Ausgabe "${item.name}" wirklich löschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancel ?? 'Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(deleteRecurringExpenseProvider).call(item.id);
              ref.invalidate(recurringExpenseListProvider);
              ref.invalidate(committedAmountProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n?.delete ?? 'Löschen'),
          ),
        ],
      ),
    );
  }

  void _showRecurringExpenseForm(
    BuildContext context,
    WidgetRef ref,
    List<CategoryEntity> categories, {
    RecurringExpenseEntity? existing,
    String? prefillName,
    int? prefillAmountCents,
    int? prefillCategoryId,
    DateTime? prefillStartDate,
  }) {
    final nameCtrl = TextEditingController(
      text: existing?.name ?? prefillName ?? '',
    );
    final amountCtrl = TextEditingController(
      text: existing != null
          ? (existing.amountCents / 100).toStringAsFixed(2)
          : prefillAmountCents != null
          ? (prefillAmountCents / 100).toStringAsFixed(2)
          : '',
    );
    int? selectedCategoryId = existing?.categoryId ?? prefillCategoryId;
    RecurringInterval selectedInterval =
        existing?.interval ?? RecurringInterval.monthly;
    DateTime selectedStartDate =
        existing?.startDate ?? prefillStartDate ?? DateTime.now();
    bool isActive = existing?.isActive ?? true;
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
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom:
                      MediaQuery.of(ctx).viewInsets.bottom +
                      MediaQuery.of(ctx).viewPadding.bottom +
                      16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              existing != null
                                  ? (l10n?.editRecurring ??
                                        'Wiederkehrende Ausgabe bearbeiten')
                                  : (l10n?.addRecurring ??
                                        'Wiederkehrende Ausgabe hinzufügen'),
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                            tooltip: l10n?.cancel ?? 'Schliessen',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n?.name ?? 'Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n?.amount ?? 'Betrag',
                          prefixText:
                              '${ref.read(currencySymbolProvider).value ?? '€'} ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final selection = await _showCategoryPickerModal(
                            ctx,
                            categories,
                            selectedCategoryId: selectedCategoryId,
                          );
                          if (selection == null) return;
                          setSheetState(() {
                            selectedCategoryId = selection.$1;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Kategorie',
                            suffixIcon: const Icon(Icons.chevron_right),
                          ),
                          child: Text(
                            _categoryPickerLabel(
                              categories,
                              selectedCategoryId,
                              fallback:
                                  l10n?.selectCategory ??
                                  'Bitte Kategorie wählen',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<RecurringInterval>(
                        segments: [
                          ButtonSegment(
                            value: RecurringInterval.monthly,
                            label: Text(l10n?.monthly ?? 'Monatlich'),
                          ),
                          ButtonSegment(
                            value: RecurringInterval.yearly,
                            label: Text(l10n?.yearly ?? 'Jährlich'),
                          ),
                        ],
                        selected: {selectedInterval},
                        onSelectionChanged: (s) =>
                            setSheetState(() => selectedInterval = s.first),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(l10n?.startDate ?? 'Startdatum:'),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedStartDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedStartDate = picked);
                              }
                            },
                            child: Text(
                              DateFormat.yMd(
                                Localizations.localeOf(ctx).toString(),
                              ).format(selectedStartDate),
                            ),
                          ),
                        ],
                      ),
                      // Always show next transaction date (at both CREATE and EDIT)
                      if (!_isValidForNextDate(selectedStartDate))
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            'Startdatum muss in Zukunft oder heute sein',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                l10n?.nextTransaction ?? 'Nächste Transaktion:',
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMd(
                                  Localizations.localeOf(ctx).toString(),
                                ).format(
                                  _calculateNextTransactionDate(
                                    selectedStartDate,
                                    selectedInterval,
                                  ),
                                ),
                                style: Theme.of(ctx).textTheme.bodySmall
                                    ?.copyWith(
                                      color: isActive
                                          ? Theme.of(ctx).colorScheme.primary
                                          : Theme.of(
                                              ctx,
                                            ).colorScheme.outlineVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      if (existing != null)
                        SwitchListTile(
                          title: Text(l10n?.active ?? 'Aktiv'),
                          value: isActive,
                          onChanged: (v) => setSheetState(() => isActive = v),
                        ),
                      if (existing != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: selectedCategoryId == null
                                ? null
                                : () async {
                                    final cents = parseAmountToCents(
                                      amountCtrl.text,
                                    );
                                    if (cents == null) return;
                                    final now = DateTime.now();
                                    await ref
                                        .read(addExpenseProvider)
                                        .call(
                                          ExpenseEntity(
                                            id: _uuid.v4(),
                                            amountCents: cents,
                                            description: nameCtrl.text.trim(),
                                            categoryId: selectedCategoryId!,
                                            date: now,
                                            recurringExpenseId: existing.id,
                                            createdAt: now,
                                            updatedAt: now,
                                          ),
                                        );
                                    ref.invalidate(expenseListProvider);
                                    ref.invalidate(
                                      currentMonthExpensesProvider,
                                    );
                                    // Invalidate chart/statistics providers
                                    ref.invalidate(spendingByCategoryProvider);
                                    ref.invalidate(spendingSummaryProvider);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Ausgabe sofort erzeugt',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.bolt),
                            label: const Text('Sofort Ausgabe erzeugen'),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final cents = parseAmountToCents(amountCtrl.text);
                            if (name.isEmpty ||
                                cents == null ||
                                selectedCategoryId == null) {
                              return;
                            }
                            final now = DateTime.now();
                            if (existing != null) {
                              await ref
                                  .read(updateRecurringExpenseProvider)
                                  .call(
                                    existing.copyWith(
                                      name: name,
                                      amountCents: cents,
                                      categoryId: selectedCategoryId,
                                      interval: selectedInterval,
                                      startDate: selectedStartDate,
                                      isActive: isActive,
                                      updatedAt: now,
                                    ),
                                  );
                            } else {
                              await ref
                                  .read(addRecurringExpenseProvider)
                                  .call(
                                    RecurringExpenseEntity(
                                      id: _uuid.v4(),
                                      name: name,
                                      amountCents: cents,
                                      categoryId: selectedCategoryId!,
                                      interval: selectedInterval,
                                      startDate: selectedStartDate,
                                      createdAt: now,
                                      updatedAt: now,
                                    ),
                                  );
                            }
                            ref.invalidate(recurringExpenseListProvider);
                            ref.invalidate(committedAmountProvider);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              if (widget.prefillName != null) {
                                context.go('/recurring');
                              }
                            }
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

  String _categoryPickerLabel(
    List<CategoryEntity> categories,
    int? categoryId, {
    required String fallback,
  }) {
    if (categoryId == null) return fallback;
    final selected = categories.where((c) => c.id == categoryId).firstOrNull;
    if (selected == null) return fallback;
    if (selected.parentId == null) return selected.name;
    final parent = categories
        .where((c) => c.id == selected.parentId)
        .firstOrNull;
    if (parent == null) return selected.name;
    return '${parent.name} -> ${selected.name}';
  }

  Future<(int, int?)?> _showCategoryPickerModal(
    BuildContext context,
    List<CategoryEntity> categories, {
    int? selectedCategoryId,
  }) {
    int? activeParentId = categories
        .where((c) => c.id == selectedCategoryId)
        .firstOrNull
        ?.parentId;

    return showModalBottomSheet<(int, int?)>(
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

            return SafeArea(
              child: Padding(
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
                              child: const Icon(Icons.category, size: 18),
                            ),
                            title: Text(category.name),
                            trailing: hasChildren
                                ? const Icon(Icons.chevron_right)
                                : (isSelected ? const Icon(Icons.check) : null),
                            onTap: () {
                              if (hasChildren) {
                                setModalState(
                                  () => activeParentId = category.id,
                                );
                                return;
                              }
                              Navigator.pop(ctx, (
                                category.id,
                                category.parentId,
                              ));
                            },
                          );
                        },
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

  String _categoryPath(Map<int, CategoryEntity> catMap, int categoryId) {
    final cat = catMap[categoryId];
    if (cat == null) return '';
    if (cat.parentId == null) return cat.name;
    final parent = catMap[cat.parentId];
    if (parent == null) return cat.name;
    return '${parent.name} -> ${cat.name}';
  }

  /// Calculate the next transaction date based on start date and interval.
  DateTime _calculateNextTransactionDate(
    DateTime startDate,
    RecurringInterval interval,
  ) {
    if (interval == RecurringInterval.monthly) {
      return DateTime(startDate.year, startDate.month + 1, startDate.day);
    } else {
      return DateTime(startDate.year + 1, startDate.month, startDate.day);
    }
  }

  /// Check if start date is valid for next date calculation.
  /// Start date must be today or in the future.
  bool _isValidForNextDate(DateTime startDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    return !start.isBefore(today);
  }
}
