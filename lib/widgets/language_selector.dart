import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// Escolha de idioma com bandeirinhas (login e configuracoes).
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  static const _langs = [('en', 'US', 'English'), ('pt', 'BR', 'Português')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = Localizations.localeOf(context).languageCode;
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        for (final (code, country, name) in _langs)
          Tooltip(
            message: name,
            child: InkWell(
              onTap: () => ref.read(settingsProvider.notifier).setLocale(Locale(code)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: current == code ? cs.secondary : Colors.transparent, width: 3),
                  boxShadow: current == code ? [BoxShadow(color: cs.secondary.withValues(alpha: .6), blurRadius: 10)] : null,
                ),
                child: CountryFlag.fromCountryCode(country, theme: const ImageTheme(width: 44, height: 30)),
              ),
            ),
          ),
      ],
    );
  }
}
