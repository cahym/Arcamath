import 'package:arcamath/l10n/app_localizations.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/arcade.dart';
import '../widgets/language_selector.dart';

/// Login com e-mail/senha OU Google (firebase_ui_auth), tudo centralizado numa unica coluna.
/// O redirecionamento apos o login e feito pelo go_router (refreshListenable no estado de auth).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// Tamanho do texto do formulario do FirebaseUI (incluindo "Nao tem uma conta? Inscreva-se").
  static const double _formFont = 13;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final base = Theme.of(context);
    TextStyle? big(TextStyle? s) => s?.copyWith(fontSize: _formFont);

    // O tema so vale dentro do login: Scaffold transparente (fundo estrelado) + fontes do formulario maiores.
    return ArcadeBackground(
      child: Theme(
        data: base.copyWith(
          scaffoldBackgroundColor: Colors.transparent,
          textTheme: base.textTheme.copyWith(
            bodyLarge: big(base.textTheme.bodyLarge),
            bodyMedium: big(base.textTheme.bodyMedium),
            bodySmall: big(base.textTheme.bodySmall),
            labelLarge: big(base.textTheme.labelLarge),
            labelMedium: big(base.textTheme.labelMedium),
            titleSmall: big(base.textTheme.titleSmall),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(textStyle: TextStyle(fontSize: _formFont, fontFamily: base.textTheme.bodyMedium?.fontFamily)),
          ),
        ),
        child: SignInScreen(
          providers: [
            EmailAuthProvider(),
            GoogleProvider(clientId: kGoogleClientId),
          ],
          // Tudo vai em subtitle/footer (exibidos em qualquer largura), sem painel lateral.
          subtitleBuilder: (context, action) => Padding(
            padding: const EdgeInsets.only(bottom: 28, top: 24),
            child: Column(children: [
              FittedBox(child: Text(kAppName.toUpperCase(), style: arcadeStyle(context, size: 44))),
              const SizedBox(height: 28),
              BlinkingText(l.pressStart, style: arcadeStyle(context, size: 16)),
              const SizedBox(height: 18),
              Text(l.areYouReady, textAlign: TextAlign.center, style: pixelLabel(context, size: 10, color: p.text)),
              const SizedBox(height: 10),
              Text(l.loginSubtitle, textAlign: TextAlign.center, style: pixelLabel(context, size: 8)),
              const SizedBox(height: 24),
              const LanguageSelector(),
            ]),
          ),
          footerBuilder: (context, action) => Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Text(
              l.madeBy(kTeamMembers.join(' & ')),
              textAlign: TextAlign.center,
              style: pixelLabel(context, size: 8).copyWith(height: 1.8),
            ),
          ),
        ),
      ),
    );
  }
}
