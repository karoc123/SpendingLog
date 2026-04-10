import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../expenses/domain/entities/expense_entity.dart';

import '../../../expenses/presentation/providers/expense_providers.dart';
import '../providers/statistics_providers.dart';
import '../widgets/spending_chart.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final viewMode = ref.watch(statsViewModeProvider);
    final currentDate = ref.watch(statsDateProvider);
    final spendingAsync = ref.watch(spendingByCategoryProvider);
    final summaryAsync = ref.watch(spendingSummaryProvider);
    final selectedCategoryId = ref.watch(selectedChartCategoryProvider);
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final (start, end) = ref.watch(statsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.statistics ?? 'Statistik')),
      body: Column(
        children: [
          // View mode toggle + date navigation.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    final d = ref.read(statsDateProvider);
                    ref
                        .read(statsDateProvider.notifier)
                        .state = viewMode == StatsViewMode.monthly
                        ? DateTime(d.year, d.month - 1, 1)
                        : DateTime(d.year - 1, d.month, 1);
                    ref.invalidate(selectedChartCategoryProvider);
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      viewMode == StatsViewMode.monthly
                          ? DateFormat.yMMMM(
                              Localizations.localeOf(context).toString(),
                            ).format(currentDate)
                          : currentDate.year.toString(),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final d = ref.read(statsDateProvider);
                    ref
                        .read(statsDateProvider.notifier)
                        .state = viewMode == StatsViewMode.monthly
                        ? DateTime(d.year, d.month + 1, 1)
                        : DateTime(d.year + 1, d.month, 1);
                    ref.invalidate(selectedChartCategoryProvider);
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 8),
                SegmentedButton<StatsViewMode>(
                  segments: [
                    ButtonSegment(
                      value: StatsViewMode.monthly,
                      label: Text(l10n?.monthly ?? 'Monat'),
                    ),
                    ButtonSegment(
                      value: StatsViewMode.yearly,
                      label: Text(l10n?.yearly ?? 'Jahr'),
                    ),
                  ],
                  selected: {viewMode},
                  onSelectionChanged: (selection) {
                    ref.read(statsViewModeProvider.notifier).state =
                        selection.first;
                    ref.invalidate(selectedChartCategoryProvider);
                  },
                ),
              ],
            ),
          ),

          // Summary numbers.
          summaryAsync.when(
            data: (summary) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    label: l10n?.totalSpent ?? 'Gesamt',
                    value: formatAmount(
                      summary.totalCents.abs(),
                      symbol: currencySymbol,
                    ),
                  ),
                  _StatCard(
                    label: l10n?.transactions ?? 'Transaktionen',
                    value: summary.transactionCount.toString(),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Pie chart.
          spendingAsync.when(
            data: (spending) => SpendingChart(
              spending: spending,
              selectedCategoryId: selectedCategoryId,
              onCategoryTap: (id) {
                ref.read(selectedChartCategoryProvider.notifier).state = id;
              },
            ),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
          ),

          // Legend.
          spendingAsync.when(
            data: (spending) => _buildLegend(context, spending, currencySymbol),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const Divider(height: 1),

          // Filtered transaction list.
          Expanded(
            child: _FilteredExpenseList(
              start: start,
              end: end,
              selectedCategoryId: selectedCategoryId,
              currencySymbol: currencySymbol,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    List<dynamic> spending,
    String currencySymbol,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: spending.map((cs) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(cs.colorValue),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                cs.categoryName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _FilteredExpenseList extends ConsumerWidget {
  final DateTime start;
  final DateTime end;
  final int? selectedCategoryId;
  final String currencySymbol;

  const _FilteredExpenseList({
    required this.start,
    required this.end,
    required this.selectedCategoryId,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(
      FutureProvider<List<ExpenseEntity>>((ref) async {
        final getExpenses = ref.watch(getExpensesProvider);
        if (selectedCategoryId != null) {
          return getExpenses.byCategory(selectedCategoryId!, start, end);
        }
        return getExpenses.inRange(start, end);
      }),
    );

    final categoriesAsync = ref.watch(allCategoriesProvider);
    final categories = categoriesAsync.value ?? [];
    final catMap = {for (final c in categories) c.id: c};

    return expensesAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)?.noExpenses ?? 'Keine Ausgaben',
            ),
          );
        }
        return ListView.builder(
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index];
            final cat = catMap[e.categoryId];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(
                  cat?.colorValue ?? 0xFF9E9E9E,
                ).withValues(alpha: 0.2),
                child: e.isRecurring
                    ? const Icon(Icons.repeat, size: 18)
                    : Icon(iconFromName(cat?.iconName ?? 'category'), size: 18),
              ),
              title: Text(e.description),
              subtitle: Text(
                DateFormat.yMMMd(
                  Localizations.localeOf(context).toString(),
                ).format(e.date),
              ),
              trailing: Text(
                formatAmount(e.amountCents, symbol: currencySymbol),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}
