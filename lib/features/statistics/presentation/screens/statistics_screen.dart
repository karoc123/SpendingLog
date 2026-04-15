import 'package:fl_chart/fl_chart.dart';
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
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/providers/expense_providers.dart';
import '../../domain/usecases/get_spending_by_category.dart';
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
    final parentCategoryId = ref.watch(selectedParentChartCategoryProvider);
    final subcategoryId = ref.watch(selectedSubChartCategoryProvider);
    final spendingAsync = parentCategoryId == null
        ? ref.watch(spendingByCategoryProvider)
        : ref.watch(subcategorySpendingProvider(parentCategoryId));
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final selectedCategoryId = subcategoryId ?? parentCategoryId;
    final currencySymbol = ref.watch(currencySymbolProvider).value ?? '€';
    final (start, end) = ref.watch(statsDateRangeProvider);
    final filteredExpensesAsync = ref.watch(
      filteredStatsExpensesProvider((
        start: start,
        end: end,
        categoryId: selectedCategoryId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.statistics ?? 'Statistik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => showScreenHelp(
              context,
              deTitle: 'Hilfe: Statistik',
              enTitle: 'Help: Statistics',
              deBody:
                  'Tippe im Kreisdiagramm auf eine Kategorie oder im Balkendiagramm auf einen Zeitraum, um gefilterte Transaktionen zu öffnen.',
              enBody:
                  'Tap pie chart categories or bar chart periods to open filtered transactions.',
            ),
          ),
        ],
      ),
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
                    ref
                            .read(selectedParentChartCategoryProvider.notifier)
                            .state =
                        null;
                    ref.read(selectedSubChartCategoryProvider.notifier).state =
                        null;
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
                    ref
                            .read(selectedParentChartCategoryProvider.notifier)
                            .state =
                        null;
                    ref.read(selectedSubChartCategoryProvider.notifier).state =
                        null;
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
                    ref
                            .read(selectedParentChartCategoryProvider.notifier)
                            .state =
                        null;
                    ref.read(selectedSubChartCategoryProvider.notifier).state =
                        null;
                  },
                ),
              ],
            ),
          ),

          if (parentCategoryId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ref
                              .read(
                                selectedParentChartCategoryProvider.notifier,
                              )
                              .state =
                          null;
                      ref
                              .read(selectedSubChartCategoryProvider.notifier)
                              .state =
                          null;
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n?.allCategories ?? 'Alle Kategorien'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: categoriesAsync.when(
                      data: (categories) {
                        final activeLabel = _activeFilterLabel(
                          categories,
                          parentCategoryId: parentCategoryId,
                          subcategoryId: subcategoryId,
                        );
                        if (activeLabel == null) {
                          return const SizedBox.shrink();
                        }
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Chip(label: Text(activeLabel)),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),

          // Summary numbers.
          filteredExpensesAsync.when(
            data: (expenses) {
              final totalCents = expenses.fold<int>(
                0,
                (sum, expense) => sum + expense.amountCents,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCard(
                      label: l10n?.totalSpent ?? 'Gesamt',
                      value: formatAmount(
                        totalCents.abs(),
                        symbol: currencySymbol,
                      ),
                    ),
                    _StatCard(
                      label: l10n?.transactions ?? 'Transaktionen',
                      value: expenses.length.toString(),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 8),

          // Pie chart + legend.
          spendingAsync.when(
            data: (spending) {
              final sorted = [...spending]
                ..sort(
                  (a, b) => b.totalCents.abs().compareTo(a.totalCents.abs()),
                );
              final visibleSpending = subcategoryId == null
                  ? sorted
                  : sorted.where((s) => s.categoryId == subcategoryId).toList();
              return SizedBox(
                height: 240,
                child: Row(
                  children: [
                    Expanded(
                      child: SpendingChart(
                        spending: visibleSpending,
                        selectedCategoryId: selectedCategoryId,
                        onCategoryTap: (id) {
                          if (parentCategoryId == null) {
                            ref
                                    .read(
                                      selectedParentChartCategoryProvider
                                          .notifier,
                                    )
                                    .state =
                                id;
                            ref
                                    .read(
                                      selectedSubChartCategoryProvider.notifier,
                                    )
                                    .state =
                                null;
                            return;
                          }
                          ref
                              .read(selectedSubChartCategoryProvider.notifier)
                              .state = id == subcategoryId
                              ? null
                              : id;
                        },
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: _buildLegend(
                        context,
                        visibleSpending,
                        currencySymbol,
                        onTap: (id) {
                          _openTransactions(
                            context,
                            start: start,
                            end: end,
                            categoryId: id,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                SizedBox(height: 240, child: Center(child: Text('Error: $e'))),
          ),

          const Divider(height: 1),

          // Period bar chart (clickable drilldown).
          Expanded(
            child: filteredExpensesAsync.when(
              data: (expenses) => categoriesAsync.when(
                data: (categories) => _SpendingBarChart(
                  viewMode: viewMode,
                  currentDate: currentDate,
                  expenses: expenses,
                  categories: categories,
                  onBucketTap: (bucket) {
                    _openTransactions(
                      context,
                      start: bucket.start,
                      end: bucket.end,
                      categoryId: selectedCategoryId,
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  String? _activeFilterLabel(
    List<CategoryEntity> categories, {
    required int? parentCategoryId,
    required int? subcategoryId,
  }) {
    final activeId = subcategoryId ?? parentCategoryId;
    if (activeId == null) return null;
    final category = categories.where((c) => c.id == activeId).firstOrNull;
    return category?.name;
  }

  void _openTransactions(
    BuildContext context, {
    required DateTime start,
    required DateTime end,
    int? categoryId,
  }) {
    final location = Uri(
      path: '/transactions',
      queryParameters: {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        if (categoryId != null) 'categoryId': '$categoryId',
      },
    ).toString();
    context.push(location);
  }

  Widget _buildLegend(
    BuildContext context,
    List<CategorySpending> spending,
    String currencySymbol, {
    required ValueChanged<int> onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      child: ListView.separated(
        itemCount: spending.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final cs = spending[index];
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onTap(cs.categoryId),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: Color(
                      cs.colorValue,
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      iconFromName(cs.iconName),
                      size: 12,
                      color: Color(cs.colorValue),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cs.categoryName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          formatAmount(
                            cs.totalCents.abs(),
                            symbol: currencySymbol,
                          ),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

class _BarBucket {
  final DateTime start;
  final DateTime end;
  final int totalCents;
  final String label;
  final List<BarChartRodStackItem> stackItems;

  const _BarBucket({
    required this.start,
    required this.end,
    required this.totalCents,
    required this.label,
    required this.stackItems,
  });
}

class _SpendingBarChart extends StatelessWidget {
  final StatsViewMode viewMode;
  final DateTime currentDate;
  final List<ExpenseEntity> expenses;
  final List<CategoryEntity> categories;
  final ValueChanged<_BarBucket> onBucketTap;

  const _SpendingBarChart({
    required this.viewMode,
    required this.currentDate,
    required this.expenses,
    required this.categories,
    required this.onBucketTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final buckets = _buildBuckets(locale);
    final maxY = buckets
        .map((b) => b.totalCents.abs().toDouble())
        .fold<double>(0, (max, v) => v > max ? v : max);

    if (buckets.every((b) => b.totalCents == 0)) {
      return Center(
        child: Text(
          AppLocalizations.of(context)?.noExpenses ?? 'Keine Ausgaben',
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewMode == StatsViewMode.monthly
                ? 'Tagesverlauf'
                : 'Monatsverlauf',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY == 0 ? 1 : maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions ||
                        response == null) {
                      return;
                    }
                    final spot = response.spot;
                    if (spot == null) return;
                    final index = spot.touchedBarGroupIndex;
                    if (index < 0 || index >= buckets.length) return;
                    onBucketTap(buckets[index]);
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        final shouldShow = viewMode == StatsViewMode.monthly
                            ? i % 5 == 0
                            : true;
                        if (!shouldShow) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            buckets[i].label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].totalCents.abs().toDouble(),
                          width: viewMode == StatsViewMode.monthly ? 6 : 12,
                          borderRadius: BorderRadius.circular(4),
                          color: const Color(0x00000000),
                          rodStackItems: buckets[i].stackItems,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_BarBucket> _buildBuckets(String locale) {
    final categoryMap = {for (final c in categories) c.id: c};

    List<BarChartRodStackItem> buildStackItems(List<ExpenseEntity> items) {
      final byCategory = <int, int>{};
      for (final e in items) {
        byCategory[e.categoryId] =
            (byCategory[e.categoryId] ?? 0) + e.amountCents;
      }
      final sorted = byCategory.entries.toList()
        ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

      var from = 0.0;
      final stacks = <BarChartRodStackItem>[];
      for (final entry in sorted) {
        final amount = entry.value.abs().toDouble();
        final to = from + amount;
        final color = Color(categoryMap[entry.key]?.colorValue ?? 0xFF9E9E9E);
        stacks.add(BarChartRodStackItem(from, to, color));
        from = to;
      }
      return stacks;
    }

    if (viewMode == StatsViewMode.yearly) {
      return [
        for (var month = 1; month <= 12; month++)
          (() {
            final start = DateTime(currentDate.year, month, 1);
            final end = DateTime(currentDate.year, month + 1, 0, 23, 59, 59);
            final bucketExpenses = expenses
                .where(
                  (e) =>
                      e.date.year == currentDate.year && e.date.month == month,
                )
                .toList();
            final total = bucketExpenses.fold<int>(
              0,
              (sum, e) => sum + e.amountCents,
            );
            return _BarBucket(
              start: start,
              end: end,
              totalCents: total,
              label: DateFormat.MMM(locale).format(start),
              stackItems: buildStackItems(bucketExpenses),
            );
          })(),
      ];
    }

    final days = DateTime(currentDate.year, currentDate.month + 1, 0).day;
    return [
      for (var day = 1; day <= days; day++)
        (() {
          final start = DateTime(currentDate.year, currentDate.month, day);
          final end = DateTime(
            currentDate.year,
            currentDate.month,
            day,
            23,
            59,
            59,
          );
          final bucketExpenses = expenses
              .where(
                (e) =>
                    e.date.year == currentDate.year &&
                    e.date.month == currentDate.month &&
                    e.date.day == day,
              )
              .toList();
          final total = bucketExpenses.fold<int>(
            0,
            (sum, e) => sum + e.amountCents,
          );
          return _BarBucket(
            start: start,
            end: end,
            totalCents: total,
            label: '$day',
            stackItems: buildStackItems(bucketExpenses),
          );
        })(),
    ];
  }
}
