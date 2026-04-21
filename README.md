# SpendingLog

A personal expense tracking app built with Flutter. Track your spending with minimal friction, manage recurring costs, and gain insights through interactive statistics.

For the full product vision, see [docs/vision.md](docs/vision.md).

## Features

- **Fast expense entry** with recent transactions preview on top and form order: notes -> amount -> description -> category
- **Two-step category selection** via a consistent modal picker (parent -> subcategory) across Home, Recurring, and Transactions edit flows
- **Recurring expenses** with configurable rhythm (daily/weekly/monthly/quarterly/yearly), optional end date (inactive from end date), live next-date preview, and a "generate now" button
- **Recurring save feedback** with snackbar validation when mandatory fields are missing (e.g. no category selected)
- **Interactive statistics** with pie drill-down (parent -> subcategory), back button drill unwind before app exit, clickable legend jump-to-transactions, icon badges for major slices, and stacked category-colored bars
- **Transactions view** with month separators including flexible vs fixed monthly totals, transaction count, category path display, and recurring-entry badges
- **Transactions filters** with the same modal category picker and explicit "All categories" reset option
- **Category management** with transaction counts per category
- **CSV/JSON export & import**:
  - **Multiple import formats**: Monekin (standard) and DKB Bank (German bank CSV) with automatic category lookup by recipient and an on-demand `Import` fallback category
  - **Import safeguards**: positive values skipped, deterministic category colors, subcategory color inherits parent, unused seeded defaults cleaned up
- **Context help button** in each main tab screen (Home, Transactions, Statistics, Recurring, Settings)
- **Settings enhancements** with links to GitHub (GPL-3.0), Monekin
- **Biometric protection** with hard lock on cold start or after 15 minutes inactivity (when enabled)
- **Smart suggestions split actions**: left click applies description+category, right click applies description+category+amount
- **Expanded category icon set** (more than doubled) for finer visual categorization
- **Localization** in German (default) and English
- **Centralized theme tokens** for easier future theme variants, including an OLED-friendly dark theme
- **Android navigation** improved to properly handle back button within app hierarchy

## Contributing & Philosophy

Contributions of all kinds are very welcome.  
If you find bugs, have ideas for improvements, or want to discuss design or implementation details, feel free to open an issue or start a discussion. Pull requests are also okay but this is more or less a copilot project, so they are not expected.

**Philosophy**

SpendingLog is built around a simple, user-respecting mindset:

- **No tracking** – your data stays yours
- **No ads** – no distractions, no dark patterns
- **No costs** – free to use
- **No cloud** – everything works fully offline and locally

The goal is a fast, transparent, and trustworthy expense tracker without hidden trade‑offs.

**Inspiration**

This project is partially inspired by [Monekin](https://github.com/enrique-lozano/Monekin) - a great open‑source expense tracking app. Many ideas and concepts were explored there and helped shape parts of SpendingLog.

Thanks to the Monekin project and its contributors!

## Tech Stack

| Layer            | Technology                                |
| ---------------- | ----------------------------------------- |
| Framework        | Flutter 3.41+ / Dart 3.11+                |
| Database         | Drift (SQLite) with code generation       |
| State Management | Riverpod (non-codegen)                    |
| Navigation       | go_router with StatefulShellRoute         |
| Charts           | fl_chart                                  |
| Architecture     | Clean Architecture, feature-based folders |

## Project Structure

```
lib/
├── app/                  # App shell, theme, router
├── core/
│   ├── database/         # Drift database, tables, migrations
│   ├── providers/        # Riverpod provider tree
│   └── utils/            # Currency formatter, icon map
├── features/
│   ├── expenses/         # Expense CRUD, autocomplete
│   ├── categories/       # Category management
│   ├── recurring/        # Recurring expense rules
│   ├── statistics/       # Spending charts & summaries
│   └── settings/         # Settings, export/import
└── l10n/                 # ARB files & generated localizations
```

Each feature follows:

```
feature/
├── data/repositories/    # Repository implementations
├── domain/
│   ├── entities/         # Pure Dart entities
│   ├── repositories/     # Abstract interfaces
│   └── usecases/         # Business logic
└── presentation/
    ├── providers/        # Feature-specific Riverpod providers
    ├── screens/          # Screen widgets
    └── widgets/          # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK 3.41+ (`flutter --version`)
- Dart SDK 3.11+

### Setup

```bash
# Clone the repository
git clone <repo-url> && cd SpendingLog

# Install dependencies
flutter pub get

# Run code generation (Drift database + localization)
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n

# Generate launcher icons (after changing app_icon.png)
dart run flutter_launcher_icons

# Run the app
flutter run
```

### Build

```bash
# Local Android APK with debug signing
flutter build apk --debug

# Web
flutter build web --release
```

For local device installs, prefer the debug-signed APK above. Release-signed Android artifacts are built through the GitHub `release.yml` workflow so the real signing key can stay outside local machines.

If you need a full release build pipeline, see [docs/signing-setup.md](docs/signing-setup.md).

## Testing

```bash
# Run all unit & widget tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests (requires device/emulator)
flutter test integration_test/app_test.dart
```

**Test structure:**

- `test/features/*/domain/usecases/` — Unit tests for all 20 use cases
- `test/features/*/presentation/screens/` — Widget tests for screens
- `test/core/utils/` — Utility tests
- `integration_test/` — End-to-end happy path
- `test/helpers/` — Shared mocks and test data factories

## Adding a Language

1. Create `lib/l10n/app_<code>.arb` (copy from `app_de.arb`)
2. Translate all keys
3. Run `flutter gen-l10n`
4. Add the locale to the currency/language picker in Settings

For the longer-term scaling plan around translations, placeholders, review flow, and release checks, see [docs/i18n-plan.md](docs/i18n-plan.md).

## CI

GitHub Actions workflows in `.github/workflows/`:

- **build-web.yml** — `flutter analyze`, `flutter test`, `flutter build web --release`
- **build-apk.yml** — Android APK build
- **release.yml** — Manual release build (APK + AAB) and GitHub Release upload

## License

This project is licensed under the GPL-3.0 License. See [LICENSE](LICENSE) for details.
