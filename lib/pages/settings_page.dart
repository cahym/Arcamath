import 'package:arcamath/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/arcade.dart';
import '../widgets/language_selector.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final cs = Theme.of(context).colorScheme;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final user = FirebaseAuth.instance.currentUser;
    final hue = HSVColor.fromColor(s.seed).hue;

    Widget modeBtn(ThemeMode m, String label, IconData icon) => ArcadeButton(
          compact: true,
          icon: icon,
          label: label,
          color: s.themeMode == m ? p.title : null,
          onPressed: () => n.setThemeMode(m),
        );

    // (a) claro / escuro / sistema
    final theme = ArcadePanel(
      title: l.themeMode,
      child: Wrap(spacing: 10, runSpacing: 4, children: [
        modeBtn(ThemeMode.system, l.themeSystem, Icons.brightness_auto),
        modeBtn(ThemeMode.light, l.themeLight, Icons.light_mode),
        modeBtn(ThemeMode.dark, l.themeDark, Icons.dark_mode),
      ]),
    );

    // (b) tamanho da fonte
    final size = ArcadePanel(
      title: l.fontSize,
      child: Column(children: [
        Slider(
          min: .8,
          max: 1.6,
          divisions: 8,
          value: s.fontScale,
          label: '${(s.fontScale * 100).round()}%',
          onChanged: n.setFontScale,
        ),
        Text('Arcamath 1234 = √(8+1)', style: Theme.of(context).textTheme.bodyLarge),
      ]),
    );

    // (c) tipo da fonte
    final family = ArcadePanel(
      title: l.fontFamily,
      child: DropdownButton<String>(
        isExpanded: true,
        value: s.fontFamily,
        dropdownColor: p.frame,
        items: [
          for (final f in kFontFamilies)
            DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.getFont(f, color: p.text, fontSize: 14))),
        ],
        onChanged: (f) => f == null ? null : n.setFontFamily(f),
      ),
    );

    // (d) cor semente
    final seed = ArcadePanel(
      title: l.seedColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final c in kSeedPresets)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => n.setSeed(c),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: s.seed == c ? p.text : Colors.transparent, width: 3),
                  ),
                  child: s.seed == c ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        Text(l.customColor, style: pixelLabel(context, size: 8)),
        Slider(
          min: 0,
          max: 360,
          value: hue,
          activeColor: s.seed,
          onChanged: (h) => n.setSeed(HSVColor.fromAHSV(1, h, .85, 1).toColor()),
        ),
      ]),
    );

    final language = ArcadePanel(title: l.language, child: const LanguageSelector());

    // som opcional (padrao: desligado)
    final sound = ArcadePanel(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.sound),
        subtitle: Text(l.soundHint),
        secondary: Icon(s.soundOn ? Icons.volume_up : Icons.volume_off),
        value: s.soundOn,
        onChanged: n.setSound,
      ),
    );

    final account = ArcadePanel(
      title: l.account,
      child: Column(children: [
        Text(user?.displayName ?? user?.email ?? ''),
        const SizedBox(height: 14),
        ArcadeButton(icon: Icons.logout, label: l.signOut, color: cs.secondary, onPressed: () => FirebaseAuth.instance.signOut()),
      ]),
    );

    List<Widget> spaced(List<Widget> w) => [for (final x in w) Padding(padding: const EdgeInsets.only(bottom: 18), child: x)];

    return SafeArea(
      child: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 900; // computador: duas colunas
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1000 : 600),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.settingsTitle.toUpperCase(), textAlign: TextAlign.center, style: arcadeStyle(context, size: 20)),
                const SizedBox(height: 24),
                if (wide)
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(children: spaced([theme, size, family]))),
                    const SizedBox(width: 20),
                    Expanded(child: Column(children: spaced([seed, language, sound, account]))),
                  ])
                else
                  Column(children: spaced([theme, size, family, seed, language, sound, account])),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
