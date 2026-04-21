import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/default_category_seeder.dart';
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
    final categoryMap = ref.watch(categoryMapProvider);
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final categories = categoriesAsync.value ?? [];
    final hasCategories = categories.isNotEmpty;

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
                  'Hier legst du Regeln mit taeglichem, woechentlichem, monatlichem, quartalsweisem oder jaehrlichem Rhythmus an. Optional kannst du ein Enddatum setzen, ab dem die Regel inaktiv wird.',
              enBody:
                  'Create rules with daily, weekly, monthly, quarterly, or yearly rhythm. Optionally set an end date, after which the rule becomes inactive.',
            ),
          ),
        ],
      ),
      floatingActionButton: hasCategories
          ? FloatingActionButton(
              onPressed: () =>
                  _showRecurringExpenseForm(context, ref, categories),
              child: const Icon(Icons.add),
            )
          : null,
      body: recurringAsync.when(
        data: (items) {
          if (!hasCategories) {
            return _buildNoCategoriesActions(context, ref);
          }
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
              final cat = categoryMap[item.categoryId];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    cat?.colorValue ?? 0xFF9E9E9E,
                  ).withValues(alpha: 0.2),
                  child: const Icon(Icons.repeat, size: 20),
                ),
                title: Text(item.name),
                subtitle: Text(
                  '${_categoryPath(categoryMap, item.categoryId)} · ${_intervalLabel(item.interval, l10n)} · ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(item.startDate)}${item.endDate != null ? ' · ${(l10n?.endDate ?? 'Enddatum')}: ${DateFormat.yMd(Localizations.localeOf(context).toString()).format(item.endDate!)}' : ''}',
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

  Future<void> _createDefaultCategories(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final db = ref.read(databaseProvider);
    final localeCode = ref.read(localeSettingProvider).value ?? 'en';
    final hasCategories = (await db.getAllCategories()).isNotEmpty;
    if (!hasCategories) {
      await seedDefaultCategories(db, localeCode);
      ref.invalidate(allCategoriesProvider);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.importSuccess ?? 'Import successful',
        ),
      ),
    );
  }

  Widget _buildNoCategoriesActions(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.selectCategory ?? 'Please select a category',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _createDefaultCategories(context, ref),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                  l10n?.addDefaultCategories ?? 'Create default categories',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/settings/categories'),
                icon: const Icon(Icons.category),
                label: Text(l10n?.manageCategories ?? 'Manage categories'),
              ),
            ),
          ],
        ),
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
    DateTime? selectedEndDate = existing?.endDate;
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
                            labelText: l10n?.category ?? 'Category',
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
                      DropdownButtonFormField<RecurringInterval>(
                        initialValue: selectedInterval,
                        decoration: InputDecoration(
                          labelText: l10n?.rhythm ?? 'Rhythm',
                        ),
                        items: RecurringInterval.values
                            .map(
                              (interval) => DropdownMenuItem(
                                value: interval,
                                child: Text(_intervalLabel(interval, l10n)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedInterval = value);
                        },
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
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final today = DateTime.now();
                          final initial =
                              selectedEndDate == null ||
                                  _dayOnly(
                                    selectedEndDate!,
                                  ).isBefore(_dayOnly(today))
                              ? _dayOnly(today)
                              : selectedEndDate!;
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: initial,
                            firstDate: DateTime(
                              today.year,
                              today.month,
                              today.day,
                            ),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedEndDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText:
                                l10n?.endDateOptional ?? 'End date (optional)',
                            suffixIcon: selectedEndDate == null
                                ? const Icon(Icons.event)
                                : IconButton(
                                    onPressed: () => setSheetState(
                                      () => selectedEndDate = null,
                                    ),
                                    tooltip: l10n?.clearFilter ?? 'Clear',
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                          child: Text(
                            selectedEndDate == null
                                ? (l10n?.noEndDate ?? 'No end date')
                                : DateFormat.yMd(
                                    Localizations.localeOf(ctx).toString(),
                                  ).format(selectedEndDate!),
                          ),
                        ),
                      ),
                      if (selectedEndDate != null &&
                          _isEndDateInPast(selectedEndDate!))
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            l10n?.endDateValidationFuture ??
                                'End date must be today or in the future',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: Theme.of(ctx).colorScheme.error,
                            ),
                          ),
                        ),
                      // Always show next transaction date (at both CREATE and EDIT)
                      if (!_isValidForNextDate(selectedStartDate))
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Text(
                            l10n?.startDateValidationFuture ??
                                'Start date must be today or in the future',
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
                                        SnackBar(
                                          content: Text(
                                            l10n?.expenseGeneratedNow ??
                                                'Expense generated now',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.bolt),
                            label: Text(
                              l10n?.generateExpenseNow ?? 'Generate now',
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            final name = nameCtrl.text.trim();
                            final cents = parseAmountToCents(amountCtrl.text);
                            final validationMessage = _validateRecurringForm(
                              name: name,
                              amountCents: cents,
                              categoryId: selectedCategoryId,
                              startDate: selectedStartDate,
                              endDate: selectedEndDate,
                              l10n: l10n,
                            );
                            if (validationMessage != null) {
                              ScaffoldMessenger.of(ctx)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text(validationMessage)),
                                );
                              return;
                            }
                            final validatedCents = cents!;
                            final now = DateTime.now();
                            if (existing != null) {
                              await ref
                                  .read(updateRecurringExpenseProvider)
                                  .call(
                                    existing.copyWith(
                                      name: name,
                                      amountCents: validatedCents,
                                      categoryId: selectedCategoryId,
                                      interval: selectedInterval,
                                      startDate: selectedStartDate,
                                      endDate: () => selectedEndDate,
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
                                      amountCents: validatedCents,
                                      categoryId: selectedCategoryId!,
                                      interval: selectedInterval,
                                      startDate: selectedStartDate,
                                      endDate: selectedEndDate,
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
                            activeParent?.name ??
                                (AppLocalizations.of(context)?.category ??
                                    'Category'),
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

  String _intervalLabel(RecurringInterval interval, AppLocalizations? l10n) {
    switch (interval) {
      case RecurringInterval.daily:
        return l10n?.daily ?? 'Täglich';
      case RecurringInterval.weekly:
        return l10n?.weekly ?? 'Wöchentlich';
      case RecurringInterval.monthly:
        return l10n?.monthly ?? 'Monatlich';
      case RecurringInterval.quarterly:
        return l10n?.quarterly ?? 'Quartalsweise';
      case RecurringInterval.yearly:
        return l10n?.yearly ?? 'Jährlich';
    }
  }

  DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isEndDateInPast(DateTime endDate) {
    final today = _dayOnly(DateTime.now());
    return _dayOnly(endDate).isBefore(today);
  }

  String? _validateRecurringForm({
    required String name,
    required int? amountCents,
    required int? categoryId,
    required DateTime startDate,
    required DateTime? endDate,
    required AppLocalizations? l10n,
  }) {
    if (name.isEmpty) {
      return l10n?.enterDescription ?? 'Bitte Beschreibung eingeben';
    }
    if (amountCents == null || amountCents == 0) {
      return l10n?.enterValidAmount ?? 'Bitte gültigen Betrag eingeben';
    }
    if (categoryId == null) {
      return l10n?.selectCategory ?? 'Bitte Kategorie wählen';
    }
    if (!_isValidForNextDate(startDate)) {
      return l10n?.startDateValidationFuture ??
          'Start date must be today or in the future';
    }
    if (endDate != null && _isEndDateInPast(endDate)) {
      return l10n?.endDateValidationFuture ??
          'End date must be today or in the future';
    }
    return null;
  }

  /// Calculate the next transaction date based on start date and interval.
  DateTime _calculateNextTransactionDate(
    DateTime startDate,
    RecurringInterval interval,
  ) {
    switch (interval) {
      case RecurringInterval.daily:
        return startDate.add(const Duration(days: 1));
      case RecurringInterval.weekly:
        return startDate.add(const Duration(days: 7));
      case RecurringInterval.monthly:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
      case RecurringInterval.quarterly:
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case RecurringInterval.yearly:
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
