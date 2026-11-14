import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../state/providers.dart';

/// Paleta retro derivada da cor semente (matiz). No violeta padrao, o titulo sai laranja
/// com sombra magenta, como nas imagens de referencia.
class ArcadePalette extends ThemeExtension<ArcadePalette> {
  const ArcadePalette({
    required this.bg,
    required this.screen,
    required this.frame,
    required this.grid,
    required this.title,
    required this.shadow,
    required this.text,
  });

  final Color bg, screen, frame, grid, title, shadow, text;

  factory ArcadePalette.fromSeed(Color seed, Brightness b) {
    final h = HSLColor.fromColor(seed).hue;
    Color hsl(double hue, double s, double l) => HSLColor.fromAHSL(1, hue % 360, s, l).toColor();
    if (b == Brightness.dark) {
      return ArcadePalette(
        bg: hsl(h, .55, .09),
        screen: hsl(h, .50, .17),
        frame: hsl(h, .45, .25),
        grid: hsl(h, .40, .36),
        title: hsl(h + 150, 1, .58),
        shadow: hsl(h + 70, .9, .50),
        text: const Color(0xFFF7E8C6),
      );
    }
    return ArcadePalette(
      bg: hsl(h, .60, .94),
      screen: hsl(h, .55, .88),
      frame: hsl(h, .45, .80),
      grid: hsl(h, .35, .62),
      title: hsl(h + 150, 1, .42),
      shadow: hsl(h + 70, .85, .55),
      text: hsl(h, .55, .16),
    );
  }

  @override
  ArcadePalette copyWith({Color? bg, Color? screen, Color? frame, Color? grid, Color? title, Color? shadow, Color? text}) =>
      ArcadePalette(
        bg: bg ?? this.bg,
        screen: screen ?? this.screen,
        frame: frame ?? this.frame,
        grid: grid ?? this.grid,
        title: title ?? this.title,
        shadow: shadow ?? this.shadow,
        text: text ?? this.text,
      );

  @override
  ArcadePalette lerp(ThemeExtension<ArcadePalette>? other, double t) {
    if (other is! ArcadePalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ArcadePalette(
      bg: l(bg, other.bg),
      screen: l(screen, other.screen),
      frame: l(frame, other.frame),
      grid: l(grid, other.grid),
      title: l(title, other.title),
      shadow: l(shadow, other.shadow),
      text: l(text, other.text),
    );
  }
}

extension ArcadeContext on BuildContext {
  ArcadePalette get arcade => Theme.of(this).extension<ArcadePalette>()!;
}

ThemeData buildTheme(Brightness brightness, SettingsState s) {
  final p = ArcadePalette.fromSeed(s.seed, brightness);
  final scheme = ColorScheme.fromSeed(seedColor: s.seed, brightness: brightness).copyWith(
    primary: p.title,
    onPrimary: p.bg,
    secondary: p.shadow,
    onSecondary: Colors.white,
    surface: p.bg,
    onSurface: p.text,
    surfaceContainerHighest: p.frame,
    surfaceContainerHigh: p.frame,
    outline: p.grid,
    outlineVariant: p.grid,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, extensions: [p]);
  var text = GoogleFonts.getTextTheme(s.fontFamily, base.textTheme);
  // Press Start 2P e muito largo: reduz os tamanhos-base para o texto corrido caber.
  if (s.fontFamily == 'Press Start 2P') text = text.apply(fontSizeFactor: .7);
  return base.copyWith(
    textTheme: text.apply(bodyColor: p.text, displayColor: p.text),
    scaffoldBackgroundColor: p.bg,
  );
}
