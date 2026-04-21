import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'SpendingLog'**
  String get appTitle;

  /// No description provided for @amount.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get date;

  /// No description provided for @description.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get description;

  /// No description provided for @notes.
  ///
  /// In de, this message translates to:
  /// **'Notizen (optional)'**
  String get notes;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get confirm;

  /// No description provided for @edit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get edit;

  /// No description provided for @name.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterValidAmount.
  ///
  /// In de, this message translates to:
  /// **'Bitte gültigen Betrag eingeben'**
  String get enterValidAmount;

  /// No description provided for @enterDescription.
  ///
  /// In de, this message translates to:
  /// **'Bitte Beschreibung eingeben'**
  String get enterDescription;

  /// No description provided for @selectCategory.
  ///
  /// In de, this message translates to:
  /// **'Bitte Kategorie wählen'**
  String get selectCategory;

  /// No description provided for @expenseSaved.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe gespeichert'**
  String get expenseSaved;

  /// No description provided for @noExpenses.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ausgaben'**
  String get noExpenses;

  /// No description provided for @editExpense.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe bearbeiten'**
  String get editExpense;

  /// No description provided for @committedThisMonth.
  ///
  /// In de, this message translates to:
  /// **'Fixkosten diesen Monat'**
  String get committedThisMonth;

  /// No description provided for @statistics.
  ///
  /// In de, this message translates to:
  /// **'Statistik'**
  String get statistics;

  /// No description provided for @monthly.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get yearly;

  /// No description provided for @totalSpent.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get totalSpent;

  /// No description provided for @transactions.
  ///
  /// In de, this message translates to:
  /// **'Transaktionen'**
  String get transactions;

  /// No description provided for @topCategory.
  ///
  /// In de, this message translates to:
  /// **'Top-Kategorie'**
  String get topCategory;

  /// No description provided for @recurringExpenses.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrende Ausgaben'**
  String get recurringExpenses;

  /// No description provided for @noRecurringExpenses.
  ///
  /// In de, this message translates to:
  /// **'Keine wiederkehrenden Ausgaben'**
  String get noRecurringExpenses;

  /// No description provided for @addRecurring.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrende Ausgabe hinzufügen'**
  String get addRecurring;

  /// No description provided for @editRecurring.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrende Ausgabe bearbeiten'**
  String get editRecurring;

  /// No description provided for @deleteRecurring.
  ///
  /// In de, this message translates to:
  /// **'Löschen?'**
  String get deleteRecurring;

  /// No description provided for @deleteRecurringConfirm.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrende Ausgabe wirklich löschen?'**
  String get deleteRecurringConfirm;

  /// No description provided for @rhythm.
  ///
  /// In de, this message translates to:
  /// **'Rhythmus'**
  String get rhythm;

  /// No description provided for @daily.
  ///
  /// In de, this message translates to:
  /// **'Täglich'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In de, this message translates to:
  /// **'Wöchentlich'**
  String get weekly;

  /// No description provided for @quarterly.
  ///
  /// In de, this message translates to:
  /// **'Quartalsweise'**
  String get quarterly;

  /// No description provided for @startDate.
  ///
  /// In de, this message translates to:
  /// **'Startdatum'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In de, this message translates to:
  /// **'Enddatum'**
  String get endDate;

  /// No description provided for @endDateOptional.
  ///
  /// In de, this message translates to:
  /// **'Enddatum (optional)'**
  String get endDateOptional;

  /// No description provided for @noEndDate.
  ///
  /// In de, this message translates to:
  /// **'Kein Enddatum'**
  String get noEndDate;

  /// No description provided for @nextTransaction.
  ///
  /// In de, this message translates to:
  /// **'Nächste Transaktion'**
  String get nextTransaction;

  /// No description provided for @active.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get active;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In de, this message translates to:
  /// **'Erscheinungsbild'**
  String get appearance;

  /// No description provided for @themeMode.
  ///
  /// In de, this message translates to:
  /// **'Design'**
  String get themeMode;

  /// No description provided for @light.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @currency.
  ///
  /// In de, this message translates to:
  /// **'Währung'**
  String get currency;

  /// No description provided for @security.
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get security;

  /// No description provided for @biometricAuth.
  ///
  /// In de, this message translates to:
  /// **'Biometrische Authentifizierung'**
  String get biometricAuth;

  /// No description provided for @biometricsUnavailableWeb.
  ///
  /// In de, this message translates to:
  /// **'Auf Web nicht verfügbar'**
  String get biometricsUnavailableWeb;

  /// No description provided for @biometricsNotAvailable.
  ///
  /// In de, this message translates to:
  /// **'Biometrische Authentifizierung nicht verfügbar'**
  String get biometricsNotAvailable;

  /// No description provided for @biometricReason.
  ///
  /// In de, this message translates to:
  /// **'Bitte authentifizieren Sie sich'**
  String get biometricReason;

  /// No description provided for @enabled.
  ///
  /// In de, this message translates to:
  /// **'Aktiviert'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In de, this message translates to:
  /// **'Deaktiviert'**
  String get disabled;

  /// No description provided for @data.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get data;

  /// No description provided for @manageCategories.
  ///
  /// In de, this message translates to:
  /// **'Kategorien verwalten'**
  String get manageCategories;

  /// No description provided for @exportImport.
  ///
  /// In de, this message translates to:
  /// **'Export / Import'**
  String get exportImport;

  /// No description provided for @about.
  ///
  /// In de, this message translates to:
  /// **'Über'**
  String get about;

  /// No description provided for @csvExport.
  ///
  /// In de, this message translates to:
  /// **'CSV Export'**
  String get csvExport;

  /// No description provided for @jsonExport.
  ///
  /// In de, this message translates to:
  /// **'JSON Backup'**
  String get jsonExport;

  /// No description provided for @jsonExportDescription.
  ///
  /// In de, this message translates to:
  /// **'Vollständige Sicherung aller Daten (Ausgaben, Kategorien, wiederkehrende Ausgaben, Einstellungen).'**
  String get jsonExportDescription;

  /// No description provided for @csvImport.
  ///
  /// In de, this message translates to:
  /// **'CSV Import'**
  String get csvImport;

  /// No description provided for @csvImportDescription.
  ///
  /// In de, this message translates to:
  /// **'CSV-Datei mit Ausgaben importieren.'**
  String get csvImportDescription;

  /// No description provided for @exportCsv.
  ///
  /// In de, this message translates to:
  /// **'CSV exportieren'**
  String get exportCsv;

  /// No description provided for @exportJson.
  ///
  /// In de, this message translates to:
  /// **'JSON exportieren'**
  String get exportJson;

  /// No description provided for @importCsv.
  ///
  /// In de, this message translates to:
  /// **'CSV importieren'**
  String get importCsv;

  /// No description provided for @exportSuccess.
  ///
  /// In de, this message translates to:
  /// **'Export erfolgreich'**
  String get exportSuccess;

  /// No description provided for @importSuccess.
  ///
  /// In de, this message translates to:
  /// **'Import erfolgreich'**
  String get importSuccess;

  /// No description provided for @entries.
  ///
  /// In de, this message translates to:
  /// **'Einträge'**
  String get entries;

  /// No description provided for @from.
  ///
  /// In de, this message translates to:
  /// **'Von'**
  String get from;

  /// No description provided for @to.
  ///
  /// In de, this message translates to:
  /// **'Bis'**
  String get to;

  /// No description provided for @deleteCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie löschen'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryPrompt.
  ///
  /// In de, this message translates to:
  /// **'Was soll mit den zugehörigen Ausgaben passieren?'**
  String get deleteCategoryPrompt;

  /// No description provided for @deleteWithExpenses.
  ///
  /// In de, this message translates to:
  /// **'Mit Ausgaben löschen'**
  String get deleteWithExpenses;

  /// No description provided for @reassignExpenses.
  ///
  /// In de, this message translates to:
  /// **'Ausgaben verschieben'**
  String get reassignExpenses;

  /// No description provided for @reassignTo.
  ///
  /// In de, this message translates to:
  /// **'Verschieben nach'**
  String get reassignTo;

  /// No description provided for @addCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie hinzufügen'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie bearbeiten'**
  String get editCategory;

  /// No description provided for @addSubcategory.
  ///
  /// In de, this message translates to:
  /// **'Unterkategorie hinzufügen'**
  String get addSubcategory;

  /// No description provided for @icon.
  ///
  /// In de, this message translates to:
  /// **'Symbol'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In de, this message translates to:
  /// **'Farbe'**
  String get color;

  /// No description provided for @searchTransactions.
  ///
  /// In de, this message translates to:
  /// **'Suchen…'**
  String get searchTransactions;

  /// No description provided for @filterCategory.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get filterCategory;

  /// No description provided for @allCategories.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get allCategories;

  /// No description provided for @clearFilter.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get clearFilter;

  /// No description provided for @fixedShort.
  ///
  /// In de, this message translates to:
  /// **'Fix'**
  String get fixedShort;

  /// No description provided for @flexShort.
  ///
  /// In de, this message translates to:
  /// **'Flex'**
  String get flexShort;

  /// No description provided for @recurringGenerated.
  ///
  /// In de, this message translates to:
  /// **'Wiederkehrend erzeugt'**
  String get recurringGenerated;

  /// No description provided for @setupTitle.
  ///
  /// In de, this message translates to:
  /// **'Einrichtung'**
  String get setupTitle;

  /// No description provided for @setupDescription.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle Sprache, Theme und Standardkategorien.'**
  String get setupDescription;

  /// No description provided for @addDefaultCategories.
  ///
  /// In de, this message translates to:
  /// **'Standardkategorien hinzufügen'**
  String get addDefaultCategories;

  /// No description provided for @addDefaultCategoriesDescription.
  ///
  /// In de, this message translates to:
  /// **'Importiert Kategorien mit passenden Unterkategorien.'**
  String get addDefaultCategoriesDescription;

  /// No description provided for @saving.
  ///
  /// In de, this message translates to:
  /// **'Speichere...'**
  String get saving;

  /// No description provided for @continueLabel.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get continueLabel;

  /// No description provided for @dailyTrend.
  ///
  /// In de, this message translates to:
  /// **'Tagesverlauf'**
  String get dailyTrend;

  /// No description provided for @monthlyTrend.
  ///
  /// In de, this message translates to:
  /// **'Monatsverlauf'**
  String get monthlyTrend;

  /// No description provided for @noChartData.
  ///
  /// In de, this message translates to:
  /// **'Keine Daten'**
  String get noChartData;

  /// No description provided for @category.
  ///
  /// In de, this message translates to:
  /// **'Kategorie'**
  String get category;

  /// No description provided for @includeAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'inkl. Betrag'**
  String get includeAmountLabel;

  /// No description provided for @generateExpenseNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt erzeugen'**
  String get generateExpenseNow;

  /// No description provided for @expenseGeneratedNow.
  ///
  /// In de, this message translates to:
  /// **'Ausgabe sofort erzeugt'**
  String get expenseGeneratedNow;

  /// No description provided for @startDateValidationFuture.
  ///
  /// In de, this message translates to:
  /// **'Startdatum muss heute oder in der Zukunft liegen'**
  String get startDateValidationFuture;

  /// No description provided for @endDateValidationFuture.
  ///
  /// In de, this message translates to:
  /// **'Enddatum muss heute oder in der Zukunft liegen'**
  String get endDateValidationFuture;

  /// No description provided for @exportFailed.
  ///
  /// In de, this message translates to:
  /// **'Export fehlgeschlagen'**
  String get exportFailed;

  /// No description provided for @importFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen'**
  String get importFailed;

  /// No description provided for @importRoutineTitle.
  ///
  /// In de, this message translates to:
  /// **'Import-Routine wählen'**
  String get importRoutineTitle;

  /// No description provided for @importRoutinePrompt.
  ///
  /// In de, this message translates to:
  /// **'Welches CSV-Format soll importiert werden?'**
  String get importRoutinePrompt;

  /// No description provided for @errorCopiedClipboard.
  ///
  /// In de, this message translates to:
  /// **'Fehler in Zwischenablage kopiert'**
  String get errorCopiedClipboard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
