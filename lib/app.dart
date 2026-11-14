import 'package:arcamath/l10n/app_localizations.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'game/game_controller.dart';
import 'router.dart';
import 'state/providers.dart';
import 'widgets/arcade.dart';

class ArcamathApp extends ConsumerWidget {
  const ArcamathApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);

    // Trocou de conta? Descarta a rodada/estado do jogador anterior.
    ref.listen(authUserProvider, (prev, next) {
      if (prev?.asData?.value?.uid != next.asData?.value?.uid) ref.invalidate(gameProvider);
    });

    return MaterialApp.router(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: buildTheme(Brightness.light, s),
      darkTheme: buildTheme(Brightness.dark, s),
      themeMode: s.themeMode, // inicia em ThemeMode.system
      locale: s.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(s.fontScale)),
        child: ScanlineOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
