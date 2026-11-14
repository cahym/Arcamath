import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants.dart';
import 'pages/game_page.dart';
import 'pages/login_page.dart';
import 'pages/ranking_page.dart';
import 'pages/settings_page.dart';
import 'pages/shell_page.dart';
import 'state/providers.dart';

/// Faz o go_router reavaliar o redirect sempre que o login/logout acontece.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<User?> s) {
    _sub = s.listen((_) => notifyListeners());
  }
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

String _lastRoute(SharedPreferences p) {
  final saved = p.getString(kLastRouteKey);
  return kValidRoutes.contains(saved) ? saved! : '/game';
}

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  final refresh = _AuthRefresh(FirebaseAuth.instance.authStateChanges());
  ref.onDispose(refresh.dispose);

  NoTransitionPage<void> page(Widget w) => NoTransitionPage<void>(child: w);

  final router = GoRouter(
    // Reabriu o app? Volta para a ultima pagina (se estiver logado; senao o redirect manda p/ login).
    initialLocation: _lastRoute(prefs),
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = FirebaseAuth.instance.currentUser != null;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return _lastRoute(prefs);
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => ShellPage(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: '/game', pageBuilder: (_, __) => page(const GamePage())),
          GoRoute(path: '/ranking', pageBuilder: (_, __) => page(const RankingPage())),
          GoRoute(path: '/settings', pageBuilder: (_, __) => page(const SettingsPage())),
        ],
      ),
    ],
  );

  // SharedPreferences: grava a pagina atual a cada navegacao.
  router.routerDelegate.addListener(() {
    final loc = router.routerDelegate.currentConfiguration.uri.path;
    if (kValidRoutes.contains(loc)) prefs.setString(kLastRouteKey, loc);
  });

  return router;
});
