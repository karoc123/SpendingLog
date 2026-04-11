# i18n Scaling Plan

This document describes how SpendingLog should evolve from two languages to a maintainable multi-language setup.

## Goals

- Keep `lib/l10n/*.arb` as the single source of truth for user-facing strings.
- Make new language additions predictable and low-risk.
- Avoid inline UI strings in feature code.
- Keep translation review lightweight enough for small releases.

## Current Direction

- German and English are already generated from ARB files.
- New onboarding strings and transaction summary labels should continue to be moved into ARB instead of staying inline.
- Feature work should pay into the localization system incrementally instead of postponing cleanup.

## Rules For New Strings

1. Every new user-visible string goes into ARB first.
2. Prefer short, reusable keys only when the wording is truly shared across screens.
3. Screen-specific phrases should use scoped keys, for example `setupTitle`, `setupDescription`, `recurringGenerated`.
4. Strings with variables should use placeholders instead of concatenating translated fragments in Dart.
5. Ambiguous text should get a short translator note in the ARB file.

## Placeholder Strategy

- Use placeholders for dynamic values like counts, currency totals, month labels, and category names.
- Prefer one translated sentence template over several partially translated fragments.
- When formatting dates, currencies, or numbers, do that in Dart and only pass final formatted values into localized templates.

Example target pattern:

- `monthSummaryHeader(monthLabel, flexLabel, flexAmount, fixedLabel, fixedAmount)`

This avoids grammar problems when future languages need a different word order.

## Workflow For Adding A New Language

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb`.
2. Translate all keys.
3. Run `flutter gen-l10n`.
4. Add the locale to `supportedLocales` if needed.
5. Verify UI layout for text expansion on narrow screens.
6. Check onboarding, settings, statistics, and transaction headers specifically because these areas mix short labels and formatted values.

## Review Checklist

- No new inline strings in Dart widgets.
- All ARB files contain the same key set.
- Placeholder names stay identical across languages.
- Long labels do not break segmented buttons, chips, or month header rows.
- `flutter gen-l10n` has been run before commit/release.

## Recommended Next Steps

1. Move any remaining inline onboarding fallback strings into ARB-backed labels only.
2. Convert complex composed labels like the transaction month header into one localized template with placeholders.
3. Add one lightweight test that fails if key counts drift between ARB files.
4. Consider a third language only after the placeholder-based header/template path is in place.