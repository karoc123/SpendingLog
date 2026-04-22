import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/expenses/presentation/screens/home_screen.dart';
import '../features/expenses/presentation/screens/transactions_screen.dart';
import '../features/statistics/presentation/screens/statistics_screen.dart';
import '../features/recurring/presentation/screens/recurring_expenses_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/categories/presentation/screens/category_management_screen.dart';
import '../features/settings/presentation/screens/export_import_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) {
                final start = state.uri.queryParameters['start'];
                final end = state.uri.queryParameters['end'];
                final categoryId = state.uri.queryParameters['categoryId'];
                final search = state.uri.queryParameters['search'];
                final segment = state.uri.queryParameters['segment'];

                return TransactionsScreen(
                  initialStart: start != null ? DateTime.tryParse(start) : null,
                  initialEnd: end != null ? DateTime.tryParse(end) : null,
                  initialCategoryId: categoryId != null
                      ? int.tryParse(categoryId)
                      : null,
                  initialSearchQuery: search,
                  initialSegment: segment,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recurring',
              builder: (context, state) {
                final name = state.uri.queryParameters['name'];
                final amountCents = state.uri.queryParameters['amountCents'];
                final categoryId = state.uri.queryParameters['categoryId'];
                final startDate = state.uri.queryParameters['startDate'];

                return RecurringExpensesScreen(
                  prefillName: name,
                  prefillAmountCents: amountCents != null
                      ? int.tryParse(amountCents)
                      : null,
                  prefillCategoryId: categoryId != null
                      ? int.tryParse(categoryId)
                      : null,
                  prefillStartDate: startDate != null
                      ? DateTime.tryParse(startDate)
                      : null,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'categories',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const CategoryManagementScreen(),
                ),
                GoRoute(
                  path: 'export',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ExportImportScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && navigationShell.currentIndex != 0) {
          // If we can't pop (not at home tab), go to home tab instead.
          navigationShell.goBranch(0, initialLocation: true);
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              selectedIcon: Icon(Icons.pie_chart),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.repeat_outlined),
              selectedIcon: Icon(Icons.repeat),
              label: '',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '',
            ),
          ],
        ),
      ),
    );
  }
}
