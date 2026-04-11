# SpendingLog

A personal expense tracking app built with Flutter. Track your spending with minimal friction, manage recurring costs, and gain insights through interactive statistics.

For the full product vision, see [docs/vision.md](docs/vision.md).

## Features

- **Fast expense entry** with recent transactions preview on top and form order: notes -> amount -> description -> category
- **Two-step category selection** via a consistent modal picker (parent -> subcategory) across Home, Recurring, and Transactions edit flows
- **Recurring expenses** (monthly/yearly) with live next-date preview during create/edit and a "generate now" button
- **Interactive statistics** with clickable pie + bar chart drill-down filtering
- **Transactions view** with month separators, transaction count, and category path display
- **Category management** with transaction counts per category
- **CSV/JSON export & import**:
  - **Multiple import formats**: Monekin (standard) and DKB Bank (German bank CSV) with automatic category lookup by recipient and an on-demand `Import` fallback category
  - **Import safeguards**: positive values skipped, deterministic category colors, subcategory color inherits parent, unused seeded defaults cleaned up
- **Context help button** in each main tab screen (Home, Transactions, Statistics, Recurring, Settings)
- **Settings enhancements** with links to GitHub (GPL-3.0) and Monekin project
- **Biometric protection** (fingerprint/face on supported devices)
- **Localization** in German (default) and English
- **OLED-friendly dark theme** (true black scaffold, slightly elevated surfaces)
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

This project is partially inspired by  
https://github.com/enrique-lozano/Monekin — a great open‑source expense tracking app.  
Many ideas and concepts were explored there and helped shape parts of SpendingLog.

Thanks to the Monekin project and its contributors!

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.41+ / Dart 3.11+ |
| Database | Drift (SQLite) with code generation |
| State Management | Riverpod (non-codegen) |
| Navigation | go_router with StatefulShellRoute |
| Charts | fl_chart |
| Architecture | Clean Architecture, feature-based folders |

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
# Android APK
flutter build apk --release

# Web
flutter build web --release
```

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

## CI

GitHub Actions workflows in `.github/workflows/`:
- **build-web.yml** — `flutter analyze`, `flutter test`, `flutter build web --release`
- **build-apk.yml** — Android APK build
- **release.yml** — Manual release build (APK + AAB) and GitHub Release upload

## License

This project is licensed under the GPL-3.0 License. See [LICENSE](LICENSE) for details.
