import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ExportImportScreen extends ConsumerStatefulWidget {
  const ExportImportScreen({super.key});

  @override
  ConsumerState<ExportImportScreen> createState() => _ExportImportScreenState();
}

class _ExportImportScreenState extends ConsumerState<ExportImportScreen> {
  DateTime _csvStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _csvEnd = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.exportImport ?? 'Export / Import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // CSV Export section.
          Text(
            l10n?.csvExport ?? 'CSV Export',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n?.from ?? 'Von',
                      isDense: true,
                    ),
                    child: Text(DateFormat.yMd().format(_csvStart)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n?.to ?? 'Bis',
                      isDense: true,
                    ),
                    child: Text(DateFormat.yMd().format(_csvEnd)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _exportCsv,
            icon: const Icon(Icons.file_download),
            label: Text(l10n?.exportCsv ?? 'CSV exportieren'),
          ),

          const SizedBox(height: 24),

          // JSON Export section.
          Text(
            l10n?.jsonExport ?? 'JSON Backup',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.jsonExportDescription ??
                'Vollständige Sicherung aller Daten (Ausgaben, Kategorien, wiederkehrende Ausgaben, Einstellungen).',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _exportJson,
            icon: const Icon(Icons.backup),
            label: Text(l10n?.exportJson ?? 'JSON exportieren'),
          ),

          const SizedBox(height: 24),

          // CSV Import section.
          Text(
            l10n?.csvImport ?? 'CSV Import',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.csvImportDescription ?? 'CSV-Datei mit Ausgaben importieren.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _importCsv,
            icon: const Icon(Icons.file_upload),
            label: Text(l10n?.importCsv ?? 'CSV importieren'),
          ),

          if (_loading) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _csvStart : _csvEnd,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _csvStart = picked;
        } else {
          _csvEnd = picked;
        }
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _loading = true);
    try {
      final csv = await ref
          .read(exportCsvProvider)
          .call(
            _csvStart,
            DateTime(_csvEnd.year, _csvEnd.month, _csvEnd.day, 23, 59, 59),
          );
      await _shareText(csv, 'spending_log_export.csv');
      _showSnackBar(
        AppLocalizations.of(context)?.exportSuccess ?? 'Export erfolgreich',
      );
    } catch (e) {
      _showSnackBar('Export fehlgeschlagen: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportJson() async {
    setState(() => _loading = true);
    try {
      final json = await ref.read(exportJsonProvider).call();
      await _shareText(json, 'spending_log_backup.json');
      _showSnackBar(
        AppLocalizations.of(context)?.exportSuccess ?? 'Export erfolgreich',
      );
    } catch (e) {
      _showSnackBar('Export fehlgeschlagen: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importCsv() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      String csvContent;
      if (kIsWeb) {
        final bytes = result.files.first.bytes;
        if (bytes == null) {
          setState(() => _loading = false);
          return;
        }
        csvContent = String.fromCharCodes(bytes);
      } else {
        final file = File(result.files.first.path!);
        csvContent = await file.readAsString();
      }

      final count = await ref.read(importCsvProvider).call(csvContent);
      _showSnackBar(
        '${AppLocalizations.of(context)?.importSuccess ?? 'Import erfolgreich'}: $count ${AppLocalizations.of(context)?.entries ?? 'Einträge'}',
      );
    } catch (e) {
      _showSnackBar('Import fehlgeschlagen: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _shareText(String content, String fileName) async {
    if (kIsWeb) {
      await Share.share(content, subject: fileName);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(content);
      await Share.shareXFiles([XFile(file.path)], subject: fileName);
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
