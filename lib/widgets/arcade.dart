import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Fonte pixelada (Press Start 2P) com sombra "dura" deslocada, como nas imagens de referencia.
TextStyle arcadeStyle(BuildContext context, {double size = 24, Color? color, double glow = 0}) {
  final p = context.arcade;
  return GoogleFonts.pressStart2p(
    fontSize: size,
    color: color ?? p.title,
    shadows: [Shadow(color: p.shadow, offset: Offset(size * .09, size * .09))],
  );
}

/// Rotulo pequeno (SCORE, HIGH SCORE...).
TextStyle pixelLabel(BuildContext context, {double size = 10, Color? color}) =>
    GoogleFonts.pressStart2p(fontSize: size, color: color ?? context.arcade.text.withValues(alpha: .85));

/// Estilo para simbolos matematicos (boa cobertura de glifos).
TextStyle symbolStyle(Color color, {double size = 20}) =>
    GoogleFonts.robotoMono(fontSize: size, fontWeight: FontWeight.w700, color: color);

Color _darken(Color c, [double amount = .2]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

/// Botao de fliperama: cantos arredondados, sombra dura embaixo que "afunda" ao clicar.
class ArcadeButton extends StatefulWidget {
  const ArcadeButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.color,
    this.compact = false,
    this.symbol = false,
    this.tooltip,
  });
  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final Color? color;
  final bool compact, symbol;
  final String? tooltip;

  @override
  State<ArcadeButton> createState() => _ArcadeButtonState();
}

class _ArcadeButtonState extends State<ArcadeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    final enabled = widget.onPressed != null;
    var base = widget.color ?? Color.lerp(p.frame, p.text, .16)!;
    if (!enabled) base = Color.lerp(p.frame, p.bg, .5)!;
    final fg = !enabled
        ? p.text.withValues(alpha: .4)
        : (ThemeData.estimateBrightnessForColor(base) == Brightness.dark ? const Color(0xFFFFF5E0) : const Color(0xFF1A1030));
    final depth = _down ? 1.0 : 5.0;

    final content = Row(mainAxisSize: MainAxisSize.min, children: [
      if (widget.icon != null) Icon(widget.icon, color: fg, size: widget.compact ? 18 : 20),
      if (widget.icon != null && widget.label != null) const SizedBox(width: 8),
      if (widget.label != null)
        Text(
          widget.label!,
          style: widget.symbol
              ? symbolStyle(fg, size: widget.compact ? 18 : 22)
              : GoogleFonts.pressStart2p(fontSize: widget.compact ? 9 : 11, color: fg),
        ),
    ]);

    Widget button = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            transform: Matrix4.translationValues(0, 5 - depth, 0),
            constraints: BoxConstraints(minWidth: widget.compact ? 40 : 56, minHeight: widget.compact ? 40 : 48),
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 10 : 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: fg.withValues(alpha: .3), width: 2),
              boxShadow: [BoxShadow(color: _darken(base), offset: Offset(0, depth))],
            ),
            child: content,
          ),
        ),
      ),
    );
    if (widget.tooltip != null) button = Tooltip(message: widget.tooltip!, child: button);
    return button;
  }
}

/// Painel com moldura arredondada e sombra dura.
class ArcadePanel extends StatelessWidget {
  const ArcadePanel({super.key, required this.child, this.title, this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: p.frame.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.grid, width: 4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .35), offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(title!.toUpperCase(), style: GoogleFonts.pressStart2p(fontSize: 11, color: p.title)),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Tela de monitor CRT (referencia roxa): bezel, grade, brilho no canto e cantos bem arredondados.
class CrtFrame extends StatelessWidget {
  const CrtFrame({super.key, required this.child, this.padding = const EdgeInsets.all(28)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: p.grid,
        borderRadius: BorderRadius.circular(44),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 28, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: CustomPaint(
          painter: _CrtPainter(screen: p.screen, grid: p.grid),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _CrtPainter extends CustomPainter {
  _CrtPainter({required this.screen, required this.grid});
  final Color screen, grid;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [screen, Color.lerp(screen, Colors.black, .35)!],
        ).createShader(rect),
    );
    final g = Paint()
      ..color = grid.withValues(alpha: .45)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (double y = 0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    // brilho de vidro no canto superior esquerdo
    final gloss = Path()
      ..moveTo(20, size.height * .30)
      ..quadraticBezierTo(20, 20, size.width * .22, 20);
    canvas.drawPath(
      gloss,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(_CrtPainter old) => old.screen != screen || old.grid != grid;
}

/// Coracao em pixel art (vidas / dicas restantes).
class PixelHeart extends StatelessWidget {
  const PixelHeart({super.key, required this.filled, this.size = 26});
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    return CustomPaint(
      size: Size(size, size * 6 / 7),
      painter: _HeartPainter(filled ? p.title : p.grid.withValues(alpha: .6), filled ? p.shadow : Colors.transparent),
    );
  }
}

class _HeartPainter extends CustomPainter {
  _HeartPainter(this.color, this.shade);
  final Color color, shade;
  static const _rows = ['0110110', '1111111', '1111111', '0111110', '0011100', '0001000'];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 7;
    for (var y = 0; y < _rows.length; y++) {
      for (var x = 0; x < 7; x++) {
        if (_rows[y][x] != '1') continue;
        final r = Rect.fromLTWH(x * c, y * c, c + .5, c + .5);
        canvas.drawRect(r, Paint()..color = color);
        if (y >= 4) canvas.drawRect(r, Paint()..color = shade.withValues(alpha: .35));
      }
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) => old.color != color || old.shade != shade;
}

/// Indicador de progresso diferente do padrao (grade pulsante, pacote flutter_spinkit).
class ArcadeLoader extends StatelessWidget {
  const ArcadeLoader({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: SpinKitFadingGrid(color: context.arcade.title, shape: BoxShape.rectangle, size: 56),
      );
}

/// Texto piscante estilo "PRESS START".
class BlinkingText extends StatefulWidget {
  const BlinkingText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;
  @override
  State<BlinkingText> createState() => _BlinkingTextState();
}

class _BlinkingTextState extends State<BlinkingText> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: .1, end: 1).animate(_c),
        child: Text(widget.text, textAlign: TextAlign.center, style: widget.style),
      );
}

/// Fundo: gradiente + campo de estrelas (referencia "PRESS START").
class ArcadeBackground extends StatelessWidget {
  const ArcadeBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.bg, Color.alphaBlend(p.grid.withValues(alpha: .35), p.bg)],
        ),
      ),
      child: CustomPaint(painter: _StarsPainter(p.text.withValues(alpha: .55)), child: child),
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 90; i++) {
      final s = rnd.nextBool() ? 2.0 : 3.0;
      final paint = Paint()..color = color.withValues(alpha: .25 + rnd.nextDouble() * .5);
      canvas.drawRect(Rect.fromLTWH(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height, s, s), paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.color != color;
}

/// Linhas de varredura de um monitor CRT, por cima de todo o app.
class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(children: [
        child,
        const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScanPainter()))),
      ]);
}

class _ScanPainter extends CustomPainter {
  const _ScanPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withValues(alpha: .06);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(_ScanPainter old) => false;
}
