import 'package:arcamath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'arcade.dart';

Future<void> showHelpDialog(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.helpTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(child: Text(l.helpBody, style: const TextStyle(height: 1.5))),
      ),
      actions: [ArcadeButton(label: l.close, compact: true, onPressed: () => Navigator.of(ctx).pop())],
    ),
  );
}
