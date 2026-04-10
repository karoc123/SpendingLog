import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/providers/core_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Generate any pending recurring expense entries on launch.
  try {
    await container.read(generateRecurringEntriesProvider).call();
  } catch (_) {
    // Non-critical — continue launching even if generation fails.
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SpendingLogApp(),
    ),
  );
}
