import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../domain/entities/recurring_expense_entity.dart';

const _uuid = Uuid();

/// Watches all recurring expenses reactively.
final recurringExpenseListProvider =
    StreamProvider<List<RecurringExpenseEntity>>((ref) {
      return ref.watch(getRecurringExpensesProvider).watch();
    });

class RecurringExpensesScreen extends ConsumerWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final recurringAsync = ref.watch(recurringExpenseListProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final categories = categoriesAsync.value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.recurringExpenses ?? 'Wiederkehrende Ausgaben'),
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
                  '${cat?.name ?? ''} · ${item.interval == RecurringInterval.monthly ? (l10n?.monthly ?? 'Monatlich') : (l10n?.yearly ?? 'Jährlich')}',
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
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null
          ? (existing.amountCents / 100).toStringAsFixed(2)
          : '',
    );
    int? selectedCategoryId = existing?.categoryId;
    RecurringInterval selectedInterval =
        existing?.interval ?? RecurringInterval.monthly;
    DateTime selectedStartDate = existing?.startDate ?? DateTime.now();
    bool isActive = existing?.isActive ?? true;
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final parents = categories
                .where((c) => c.parentId == null)
                .toList();
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
                          ? (l10n?.editRecurring ??
                                'Wiederkehrende Ausgabe bearbeiten')
                          : (l10n?.addRecurring ??
                                'Wiederkehrende Ausgabe hinzufügen'),
                      style: Theme.of(ctx).textTheme.titleMedium,
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
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: parents.map((cat) {
                        return ChoiceChip(
                          label: Text(cat.name),
                          selected: selectedCategoryId == cat.id,
                          selectedColor: Color(
                            cat.colorValue,
                          ).withValues(alpha: 0.3),
                          onSelected: (_) =>
                              setSheetState(() => selectedCategoryId = cat.id),
                        );
                      }).toList(),
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
                            DateFormat.yMd().format(selectedStartDate),
                          ),
                        ),
                      ],
                    ),
                    if (existing != null)
                      SwitchListTile(
                        title: Text(l10n?.active ?? 'Aktiv'),
                        value: isActive,
                        onChanged: (v) => setSheetState(() => isActive = v),
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
