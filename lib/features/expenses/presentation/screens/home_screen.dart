import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/utils/screen_help.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/autocomplete_suggestion.dart';
import '../../domain/entities/expense_entity.dart';
import '../providers/expense_providers.dart';

const _uuid = Uuid();

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  int? _selectedCategoryId;
  int? _selectedParentCategoryId;
  DateTime _selectedDate = DateTime.now();
  List<AutocompleteSuggestion> _suggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the amount field on launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
    _descriptionController.addListener(_onDescriptionChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _amountFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  void _onDescriptionChanged() {
    final query = _descriptionController.text.trim();
    if (query.length >= 2) {
      ref.read(autocompleteSuggestionsProvider(query).future).then((
        suggestions,
      ) {
        if (mounted) {
          setState(() {
            _suggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
          });
        }
      });
    } else {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  void _applySuggestion(AutocompleteSuggestion suggestion) {
    _descriptionController.removeListener(_onDescriptionChanged);
    _descriptionController.text = suggestion.description;
    _amountController.text = (suggestion.amountCents / 100).toStringAsFixed(2);
    _selectedCategoryId = suggestion.categoryId;
    final categories = ref.read(allCategoriesProvider).value ?? [];
    final selected = categories
        .where((c) => c.id == suggestion.categoryId)
        .firstOrNull;
    _selectedParentCategoryId = selected?.parentId;
    _descriptionController.addListener(_onDescriptionChanged);
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  Future<void> _saveExpense() async {
    final amountCents = parseAmountToCents(_amountController.text);
    if (amountCents == null || amountCents == 0) {
      _showSnackBar(
        AppLocalizations.of(context)?.enterValidAmount ??
            'Bitte gültigen Betrag eingeben',
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)?.enterDescription ??
            'Bitte Beschreibung eingeben',
      );
      return;
    }

    if (_selectedCategoryId == null) {
      _showSnackBar(
        AppLocalizations.of(context)?.selectCategory ??
            'Bitte Kategorie wählen',
      );
      return;
    }

    final now = DateTime.now();
    final expense = ExpenseEntity(
      id: _uuid.v4(),
      amountCents: amountCents,
      description: description,
      categoryId: _selectedCategoryId!,
      date: _selectedDate,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(addExpenseProvider).call(expense);

    if (mounted) {
      _amountController.clear();
      _descriptionController.removeListener(_onDescriptionChanged);
      _descriptionController.clear();
      _descriptionController.addListener(_onDescriptionChanged);
      _notesController.clear();
      _selectedCategoryId = null;
      _selectedParentCategoryId = null;
      _selectedDate = DateTime.now();
      _amountFocusNode.requestFocus();
      setState(() {});
      _showSnackBar(
        AppLocalizations.of(context)?.expenseSaved ?? 'Ausgabe gespeichert',
      );
      // Invalidate the expense list to show the new entry.
      ref.invalidate(expenseListProvider);
      ref.invalidate(currentMonthExpensesProvider);
      ref.invalidate(committedAmountProvider);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final expensesAsync = ref.watch(currentMonthExpensesProvider);
    final committedAsync = ref.watch(committedAmountProvider);
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.appTitle ?? 'SpendingLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showScreenHelp(
              context,
              deTitle: 'Hilfe: Ausgaben',
              enTitle: 'Help: Expenses',
              deBody:
                  'Erfasse neue Ausgaben schnell, waehle erst eine Kategorie und dann die Unterkategorie. Tippe auf einen Eintrag zum Bearbeiten.',
              enBody:
                  'Quickly add expenses, select a parent category then a subcategory, and tap entries to edit them.',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Committed amount banner.
          committedAsync.when(
            data: (committed) {
              if (committed == 0) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                child: Text(
                  '${l10n?.committedThisMonth ?? 'Fixkosten diesen Monat'}: ${formatAmount(committed, symbol: currencySymbol)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Expense input form.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Amount + Date row.
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: l10n?.amount ?? 'Betrag',
                          prefixText: '$currencySymbol ',
                          isDense: true,
                        ),
                        onSubmitted: (_) =>
                            _descriptionFocusNode.requestFocus(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n?.date ?? 'Datum',
                            isDense: true,
                          ),
                          child: Text(
                            DateFormat.yMd(
                              Localizations.localeOf(context).toString(),
                            ).format(_selectedDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description with autocomplete.
                TextField(
                  controller: _descriptionController,
                  focusNode: _descriptionFocusNode,
                  decoration: InputDecoration(
                    labelText: l10n?.description ?? 'Beschreibung',
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),

                // Autocomplete suggestions.
                if (_showSuggestions)
                  _buildSuggestionsList(categoriesAsync, currencySymbol),

                const SizedBox(height: 12),

                // Category selector.
                categoriesAsync.when(
                  data: (categories) => _buildCategoryChips(categories),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 8),

                // Notes (optional).
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: l10n?.notes ?? 'Notizen (optional)',
                    isDense: true,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 12),

                // Save button.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveExpense,
                    icon: const Icon(Icons.save),
                    label: Text(l10n?.save ?? 'Speichern'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Recent expenses list.
          Expanded(
            child: expensesAsync.when(
              data: (expenses) {
                if (expenses.isEmpty) {
                  return Center(
                    child: Text(l10n?.noExpenses ?? 'Noch keine Ausgaben'),
                  );
                }
                return ListView.builder(
                  itemCount: expenses.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return _ExpenseListTile(
                      expense: expense,
                      currencySymbol: currencySymbol,
                      categories: categoriesAsync.value ?? [],
                      onDismissed: () async {
                        await ref.read(deleteExpenseProvider).call(expense.id);
                        ref.invalidate(expenseListProvider);
                        ref.invalidate(currentMonthExpensesProvider);
                      },
                      onTap: () => _showEditExpenseSheet(context, expense),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList(
    AsyncValue<List<CategoryEntity>> categoriesAsync,
    String currencySymbol,
  ) {
    final categories = categoriesAsync.value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _suggestions.length,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          final cat = catMap[suggestion.categoryId];
          return ListTile(
            dense: true,
            title: Text(suggestion.description),
            subtitle: Text(cat?.name ?? ''),
            trailing: Text(
              formatAmount(suggestion.amountCents, symbol: currencySymbol),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            onTap: () => _applySuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips(List<CategoryEntity> categories) {
    final parents = categories.where((c) => c.parentId == null).toList();
    final selected = categories
        .where((c) => c.id == _selectedCategoryId)
        .firstOrNull;
    final activeParentId = _selectedParentCategoryId ?? selected?.parentId;
    final subcategories = activeParentId == null
        ? <CategoryEntity>[]
        : categories.where((c) => c.parentId == activeParentId).toList();

    if (activeParentId != null && subcategories.isNotEmpty) {
      final activeParent = categories
          .where((c) => c.id == activeParentId)
          .firstOrNull;
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 96),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: Text('← ${activeParent?.name ?? 'Kategorie'}'),
                selected: false,
                onSelected: (_) {
                  setState(() {
                    _selectedParentCategoryId = null;
                    _selectedCategoryId = null;
                  });
                },
              ),
              ...subcategories.map((cat) {
                final isSelected = _selectedCategoryId == cat.id;
                return ChoiceChip(
                  label: Text(cat.name),
                  avatar: Icon(iconFromName(cat.iconName), size: 18),
                  selected: isSelected,
                  selectedColor: Color(cat.colorValue).withValues(alpha: 0.3),
                  onSelected: (_) =>
                      setState(() => _selectedCategoryId = cat.id),
                );
              }),
            ],
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 96),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: parents.map((cat) {
            final isSelected = _selectedCategoryId == cat.id;
            return ChoiceChip(
              label: Text(cat.name),
              avatar: Icon(iconFromName(cat.iconName), size: 18),
              selected: isSelected,
              selectedColor: Color(cat.colorValue).withValues(alpha: 0.3),
              onSelected: (_) {
                final hasChildren = categories.any((c) => c.parentId == cat.id);
                setState(() {
                  if (hasChildren) {
                    _selectedParentCategoryId = cat.id;
                    _selectedCategoryId = null;
                  } else {
                    _selectedParentCategoryId = null;
                    _selectedCategoryId = cat.id;
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showEditExpenseSheet(BuildContext context, ExpenseEntity expense) {
    final amountCtrl = TextEditingController(
      text: (expense.amountCents / 100).toStringAsFixed(2),
    );
    final descCtrl = TextEditingController(text: expense.description);
    final notesCtrl = TextEditingController(text: expense.notes ?? '');
    int? editCategoryId = expense.categoryId;
    int? editParentCategoryId;
    DateTime editDate = expense.date;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final categoriesAsync = ref.watch(allCategoriesProvider);
            final currencySymbol =
                ref.watch(currencySymbolProvider).value ?? '€';
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
                      Text(
                        l10n?.editExpense ?? 'Ausgabe bearbeiten',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: l10n?.amount ?? 'Betrag',
                          prefixText: '$currencySymbol ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          labelText: l10n?.description ?? 'Beschreibung',
                        ),
                      ),
                      const SizedBox(height: 12),
                      categoriesAsync.when(
                        data: (categories) {
                          final selected = categories
                              .where((c) => c.id == editCategoryId)
                              .firstOrNull;
                          final activeParentId =
                              editParentCategoryId ?? selected?.parentId;
                          final subcategories = activeParentId == null
                              ? <CategoryEntity>[]
                              : categories
                                    .where((c) => c.parentId == activeParentId)
                                    .toList();

                          if (activeParentId != null &&
                              subcategories.isNotEmpty) {
                            return ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 96),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    ChoiceChip(
                                      label: const Text('← Kategorie'),
                                      selected: false,
                                      onSelected: (_) => setSheetState(() {
                                        editParentCategoryId = null;
                                        editCategoryId = null;
                                      }),
                                    ),
                                    ...subcategories.map((cat) {
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
                                    }),
                                  ],
                                ),
                              ),
                            );
                          }

                          final parents = categories
                              .where((c) => c.parentId == null)
                              .toList();
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 96),
                            child: SingleChildScrollView(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: parents.map((cat) {
                                  return ChoiceChip(
                                    label: Text(cat.name),
                                    selected: editCategoryId == cat.id,
                                    selectedColor: Color(
                                      cat.colorValue,
                                    ).withValues(alpha: 0.3),
                                    onSelected: (_) {
                                      final hasChildren = categories.any(
                                        (c) => c.parentId == cat.id,
                                      );
                                      setSheetState(() {
                                        if (hasChildren) {
                                          editParentCategoryId = cat.id;
                                          editCategoryId = null;
                                        } else {
                                          editParentCategoryId = null;
                                          editCategoryId = cat.id;
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        decoration: InputDecoration(
                          labelText: l10n?.notes ?? 'Notizen (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: editDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 1),
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => editDate = picked);
                              }
                            },
                            child: Text(
                              DateFormat.yMd(
                                Localizations.localeOf(ctx).toString(),
                              ).format(editDate),
                            ),
                          ),
                          const Spacer(),
                          IconButton.outlined(
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
                          FilledButton(
                            onPressed: () async {
                              final cents = parseAmountToCents(amountCtrl.text);
                              if (cents == null) return;
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
                              await ref
                                  .read(updateExpenseProvider)
                                  .call(updated);
                              ref.invalidate(expenseListProvider);
                              ref.invalidate(currentMonthExpensesProvider);
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Text(l10n?.save ?? 'Speichern'),
                          ),
                        ],
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
}

class _ExpenseListTile extends StatelessWidget {
  final ExpenseEntity expense;
  final String currencySymbol;
  final List<CategoryEntity> categories;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const _ExpenseListTile({
    required this.expense,
    required this.currencySymbol,
    required this.categories,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cat = categories.where((c) => c.id == expense.categoryId).firstOrNull;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(expense.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => onDismissed(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(
            cat?.colorValue ?? 0xFF9E9E9E,
          ).withValues(alpha: 0.2),
          child: expense.isRecurring
              ? const Icon(Icons.repeat, size: 20)
              : Icon(iconFromName(cat?.iconName ?? 'category'), size: 20),
        ),
        title: Text(expense.description),
        subtitle: Text(
          '${cat?.name ?? ''} · ${DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(expense.date)}',
        ),
        trailing: Text(
          formatAmount(expense.amountCents, symbol: currencySymbol),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
