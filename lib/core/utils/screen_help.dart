import 'package:flutter/material.dart';

void showScreenHelp(
  BuildContext context, {
  required String deTitle,
  required String enTitle,
  required String deBody,
  required String enBody,
}) {
  final isGerman = Localizations.localeOf(context).languageCode == 'de';
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isGerman ? deTitle : enTitle),
      content: Text(isGerman ? deBody : enBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(isGerman ? 'Schliessen' : 'Close'),
        ),
      ],
    ),
  );
}
