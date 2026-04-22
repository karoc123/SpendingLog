// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'SpendingLog';

  @override
  String get amount => 'Betrag';

  @override
  String get date => 'Datum';

  @override
  String get description => 'Beschreibung';

  @override
  String get notes => 'Notizen (optional)';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get name => 'Name';

  @override
  String get enterValidAmount => 'Bitte gültigen Betrag eingeben';

  @override
  String get enterDescription => 'Bitte Beschreibung eingeben';

  @override
  String get selectCategory => 'Bitte Kategorie wählen';

  @override
  String get expenseSaved => 'Ausgabe gespeichert';

  @override
  String get noExpenses => 'Noch keine Ausgaben';

  @override
  String get editExpense => 'Ausgabe bearbeiten';

  @override
  String get committedThisMonth => 'Fixkosten diesen Monat';

  @override
  String get statistics => 'Statistik';

  @override
  String get monthly => 'Monat';

  @override
  String get yearly => 'Jahr';

  @override
  String get totalSpent => 'Gesamt';

  @override
  String get transactions => 'Transaktionen';

  @override
  String get topCategory => 'Top-Kategorie';

  @override
  String get recurringExpenses => 'Wiederkehrende Ausgaben';

  @override
  String get noRecurringExpenses => 'Keine wiederkehrenden Ausgaben';

  @override
  String get addRecurring => 'Wiederkehrende Ausgabe hinzufügen';

  @override
  String get editRecurring => 'Wiederkehrende Ausgabe bearbeiten';

  @override
  String get deleteRecurring => 'Löschen?';

  @override
  String get deleteRecurringConfirm =>
      'Wiederkehrende Ausgabe wirklich löschen?';

  @override
  String get rhythm => 'Rhythmus';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get quarterly => 'Quartalsweise';

  @override
  String get startDate => 'Startdatum';

  @override
  String get endDate => 'Enddatum';

  @override
  String get endDateOptional => 'Enddatum (optional)';

  @override
  String get noEndDate => 'Kein Enddatum';

  @override
  String get nextTransaction => 'Nächste Transaktion';

  @override
  String get active => 'Aktiv';

  @override
  String get settings => 'Einstellungen';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get themeMode => 'Design';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get system => 'System';

  @override
  String get language => 'Sprache';

  @override
  String get currency => 'Währung';

  @override
  String get security => 'Sicherheit';

  @override
  String get biometricAuth => 'Biometrische Authentifizierung';

  @override
  String get biometricsUnavailableWeb => 'Auf Web nicht verfügbar';

  @override
  String get biometricsNotAvailable =>
      'Biometrische Authentifizierung nicht verfügbar';

  @override
  String get biometricReason => 'Bitte authentifizieren Sie sich';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get data => 'Daten';

  @override
  String get manageCategories => 'Kategorien verwalten';

  @override
  String get exportImport => 'Export / Import';

  @override
  String get about => 'Über';

  @override
  String get csvExport => 'CSV Export';

  @override
  String get jsonExport => 'JSON Backup';

  @override
  String get jsonExportDescription =>
      'Vollständige Sicherung aller Daten (Ausgaben, Kategorien, wiederkehrende Ausgaben, Einstellungen).';

  @override
  String get jsonImport => 'JSON-Backup importieren';

  @override
  String get jsonImportDescription =>
      'Stellt alle Daten aus einer JSON-Backup-Datei wieder her. Bestehende Daten werden ersetzt.';

  @override
  String get jsonImportConfirmTitle => 'Backup wiederherstellen?';

  @override
  String get jsonImportConfirmMessage =>
      'Aktuelle Daten werden vollständig durch das ausgewählte Backup ersetzt.';

  @override
  String get jsonImportResult => 'Wiederherstellung abgeschlossen';

  @override
  String get csvImport => 'CSV Import';

  @override
  String get csvImportDescription => 'CSV-Datei mit Ausgaben importieren.';

  @override
  String get exportCsv => 'CSV exportieren';

  @override
  String get exportJson => 'JSON exportieren';

  @override
  String get importCsv => 'CSV importieren';

  @override
  String get exportSuccess => 'Export erfolgreich';

  @override
  String get importSuccess => 'Import erfolgreich';

  @override
  String get entries => 'Einträge';

  @override
  String get from => 'Von';

  @override
  String get to => 'Bis';

  @override
  String get deleteCategory => 'Kategorie löschen';

  @override
  String get deleteCategoryPrompt =>
      'Was soll mit den zugehörigen Ausgaben passieren?';

  @override
  String get deleteWithExpenses => 'Mit Ausgaben löschen';

  @override
  String get reassignExpenses => 'Ausgaben verschieben';

  @override
  String get reassignTo => 'Verschieben nach';

  @override
  String get addCategory => 'Kategorie hinzufügen';

  @override
  String get editCategory => 'Kategorie bearbeiten';

  @override
  String get addSubcategory => 'Unterkategorie hinzufügen';

  @override
  String get icon => 'Symbol';

  @override
  String get color => 'Farbe';

  @override
  String get isSavingsCategory => 'Savings-Kategorie';

  @override
  String get isSavingsCategoryDescription =>
      'Diese Kategorie wird in der Statistik als Ersparnis gewertet.';

  @override
  String get searchTransactions => 'Suchen…';

  @override
  String get filterCategory => 'Kategorie';

  @override
  String get allCategories => 'Alle';

  @override
  String get clearFilter => 'Filter zurücksetzen';

  @override
  String get fixedShort => 'Fix';

  @override
  String get flexShort => 'Flex';

  @override
  String get recurringGenerated => 'Wiederkehrend erzeugt';

  @override
  String get setupTitle => 'Einrichtung';

  @override
  String get setupDescription =>
      'Bitte wähle Sprache, Theme und Standardkategorien.';

  @override
  String get addDefaultCategories => 'Standardkategorien hinzufügen';

  @override
  String get addDefaultCategoriesDescription =>
      'Importiert Kategorien mit passenden Unterkategorien.';

  @override
  String get saving => 'Speichere...';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get dailyTrend => 'Tagesverlauf';

  @override
  String get monthlyTrend => 'Monatsverlauf';

  @override
  String get noChartData => 'Keine Daten';

  @override
  String get category => 'Kategorie';

  @override
  String get categoriesLabel => 'Kategorien';

  @override
  String get expensesLabel => 'Ausgaben';

  @override
  String get expensesSegment => 'Ausgaben';

  @override
  String get savingsSegment => 'Sparen';

  @override
  String get recurringLabel => 'Wiederkehrend';

  @override
  String get settingsLabel => 'Einstellungen';

  @override
  String get includeAmountLabel => 'inkl. Betrag';

  @override
  String get generateExpenseNow => 'Jetzt erzeugen';

  @override
  String get expenseGeneratedNow => 'Ausgabe sofort erzeugt';

  @override
  String get startDateValidationFuture =>
      'Startdatum muss heute oder in der Zukunft liegen';

  @override
  String get endDateValidationFuture =>
      'Enddatum muss heute oder in der Zukunft liegen';

  @override
  String get exportFailed => 'Export fehlgeschlagen';

  @override
  String get importFailed => 'Import fehlgeschlagen';

  @override
  String get importRoutineTitle => 'Import-Routine wählen';

  @override
  String get importRoutinePrompt =>
      'Welches CSV-Format soll importiert werden?';

  @override
  String get errorCopiedClipboard => 'Fehler in Zwischenablage kopiert';
}
