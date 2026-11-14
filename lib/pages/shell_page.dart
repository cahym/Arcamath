import 'package:arcamath/l10n/app_localizations.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../widgets/arcade.dart';
import '../widgets/help_dialog.dart';

/// Casca de todas as paginas pos-login: fundo arcade + CurvedNavigationBar fixa na base.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  final _navKey = GlobalKey<CurvedNavigationBarState>();

  int get _index {
    final i = kValidRoutes.indexWhere(widget.location.startsWith);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final icon = cs.onPrimary;

    return Scaffold(
      extendBody: true,
      body: ArcadeBackground(child: widget.child),
      bottomNavigationBar: Align(
        heightFactor: 1,
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: CurvedNavigationBar(
            key: _navKey,
            index: _index,
            height: 62,
            color: cs.primary,
            buttonBackgroundColor: cs.primary,
            backgroundColor: Colors.transparent,
            animationDuration: const Duration(milliseconds: 350),
            items: [
              Tooltip(message: l.navGame, child: Icon(Icons.sports_esports, color: icon)),
              Tooltip(message: l.navRanking, child: Icon(Icons.emoji_events, color: icon)),
              Tooltip(message: l.navSettings, child: Icon(Icons.settings, color: icon)),
              Tooltip(message: l.navHelp, child: Icon(Icons.help_outline, color: icon)),
            ],
            onTap: (i) {
              if (i == 3) {
                // Ajuda abre um dialogo e devolve a barra para a aba atual.
                showHelpDialog(context).then((_) => _navKey.currentState?.setPage(_index));
              } else {
                context.go(kValidRoutes[i]);
              }
            },
          ),
        ),
      ),
    );
  }
}
