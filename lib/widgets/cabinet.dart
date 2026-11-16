import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'arcade.dart';

Color _shade(Color c, double d) {
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness + d).clamp(0.0, 1.0)).toColor();
}

/// Gabinete de fliperama: letreiro (marquee) + corpo com a tela CRT.
/// [screen] vai dentro da tela (inclusive a faixa de botoes, ver [DeckPanel]).
class ArcadeCabinet extends StatelessWidget {
  const ArcadeCabinet({super.key, required this.screen, required this.compact});
  final Widget screen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .5), blurRadius: 32, offset: const Offset(0, 16))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Marquee(compact: compact),
          _Body(compact: compact, screen: screen),
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------ letreiro

class _Marquee extends StatelessWidget {
  const _Marquee({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    final starBox = SizedBox(
      width: compact ? 52 : 110,
      child: Center(child: Icon(Icons.star, color: const Color(0xFFFFD54F), size: compact ? 26 : 44)),
    );
    final divider = Container(width: 4, color: _shade(p.frame, -.12));
    return Container(
      height: compact ? 64 : 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_shade(p.frame, .10), p.frame],
        ),
        border: Border(bottom: BorderSide(color: _shade(p.frame, -.18), width: 6)),
      ),
      child: Row(children: [
        starBox,
        divider,
        Expanded(
          child: CustomPaint(
            painter: _CheckerPainter(
              Color.lerp(p.frame, p.text, .10)!,
              Color.lerp(p.frame, p.shadow, .35)!,
              compact ? 12 : 16,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('ARCAMATH', style: arcadeStyle(context, size: compact ? 22 : 36)),
                ),
              ),
            ),
          ),
        ),
        divider,
        starBox,
      ]),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  _CheckerPainter(this.a, this.b, this.cell);
  final Color a, b;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final pa = Paint()..color = a, pb = Paint()..color = b;
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), (x + y).isEven ? pa : pb);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter old) => old.a != a || old.b != b || old.cell != cell;
}

// ------------------------------------------------------------------ corpo + tela

class _Body extends StatelessWidget {
  const _Body({required this.compact, required this.screen});
  final bool compact;
  final Widget screen;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    return LayoutBuilder(builder: (context, c) {
      final inset = math.min(c.maxWidth * .045, 34.0);
      return CustomPaint(
        painter: _BodyPainter(
          dark: Color.lerp(p.bg, Colors.black, .55)!,
          wall: Color.lerp(p.frame, p.bg, .35)!,
          light: p.title.withValues(alpha: .75),
          inset: inset,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(inset + 8, compact ? 14 : 24, inset + 8, compact ? 14 : 24),
          child: CrtFrame(
            padding: EdgeInsets.fromLTRB(compact ? 12 : 26, compact ? 16 : 22, compact ? 12 : 26, compact ? 16 : 22),
            child: screen,
          ),
        ),
      );
    });
  }
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({required this.dark, required this.wall, required this.light, required this.inset});
  final Color dark, wall, light;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [dark, Color.lerp(dark, Colors.black, .45)!],
        ).createShader(rect),
    );
    final w = Paint()..color = wall;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(inset, inset * .9)
        ..lineTo(inset, size.height - inset * .9)
        ..lineTo(0, size.height)
        ..close(),
      w,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(size.width - inset, inset * .9)
        ..lineTo(size.width - inset, size.height - inset * .9)
        ..lineTo(size.width, size.height)
        ..close(),
      w,
    );
    // luzinhas ao longo das laterais (como no gabinete de referencia)
    final dot = Paint()..color = light;
    for (double y = inset + 6; y < size.height - inset; y += 26) {
      canvas.drawRect(Rect.fromLTWH(inset * .45 - 2, y, 4, 4), dot);
      canvas.drawRect(Rect.fromLTWH(size.width - inset * .45 - 2, y, 4, 4), dot);
    }
  }

  @override
  bool shouldRepaint(_BodyPainter old) => old.dark != dark || old.wall != wall || old.light != light || old.inset != inset;
}

// ------------------------------------------------------------------ faixa de controle

/// Faixa de controle (botoes, joystick e plaquinha de ficha) com cantos arredondados.
/// Fica dentro da tela do jogo.
class DeckPanel extends StatelessWidget {
  const DeckPanel({super.key, required this.child, required this.compact, required this.color});
  final Widget child;
  final bool compact;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(color, Colors.white, .12)!, Color.lerp(color, Colors.black, .3)!],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color.lerp(color, Colors.white, .35)!, width: 3),
      ),
      child: child,
    );
  }
}

/// Botao redondo de fliperama (domo 3D) que afunda ao ser pressionado.
class DomeButton extends StatefulWidget {
  const DomeButton({super.key, required this.color, required this.label, required this.onPressed, this.size = 50});
  final Color color;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  @override
  State<DomeButton> createState() => _DomeButtonState();
}

class _DomeButtonState extends State<DomeButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final s = widget.size;
    final dark = _shade(c, -.22), light = _shade(c, .2);
    final fg = ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : const Color(0xFF1A1030);
    final enabled = widget.onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : .5,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: widget.onPressed,
          child: SizedBox(
            width: s,
            height: s + 6,
            child: Stack(children: [
              // base (anel escuro no painel)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: .6),
                    border: Border.all(color: Colors.black.withValues(alpha: .35), width: 2),
                  ),
                ),
              ),
              // domo
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 3,
                right: 3,
                top: _down ? 4 : 0,
                child: Container(
                  height: s - 6,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(center: const Alignment(-.35, -.45), radius: .95, colors: [light, c, dark]),
                    border: Border.all(color: dark, width: 2),
                    boxShadow: [BoxShadow(color: dark, offset: Offset(0, _down ? 1 : 4))],
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Positioned(
                      top: s * .1,
                      left: s * .2,
                      child: Container(
                        width: s * .22,
                        height: s * .11,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .38), borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    Text(widget.label, style: symbolStyle(fg, size: s * .4)),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Joystick decorativo.
class Joystick extends StatelessWidget {
  const Joystick({super.key, this.size = 84});
  final double size;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(size, size * 1.2), painter: _JoystickPainter());
}

class _JoystickPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // base
    canvas.drawOval(Rect.fromLTWH(w * .05, h * .74, w * .9, h * .22), Paint()..color = Colors.black.withValues(alpha: .8));
    canvas.drawOval(Rect.fromLTWH(w * .2, h * .78, w * .6, h * .13), Paint()..color = const Color(0xFF3A3A44));
    // haste
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * .46, h * .34, w * .08, h * .5), const Radius.circular(3)),
      Paint()..color = const Color(0xFFB8B8C4),
    );
    // bola vermelha
    final ball = Rect.fromCircle(center: Offset(w * .5, h * .27), radius: w * .27);
    canvas.drawCircle(
      ball.center,
      ball.width / 2,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.5),
          colors: [Color(0xFFFF8A80), Color(0xFFE53935), Color(0xFF8E1B1B)],
        ).createShader(ball),
    );
    canvas.drawCircle(Offset(w * .42, h * .19), w * .06, Paint()..color = Colors.white.withValues(alpha: .6));
  }

  @override
  bool shouldRepaint(_JoystickPainter old) => false;
}

/// Plaquinha "INSERT COIN" com duas fendas.
class CoinPlate extends StatelessWidget {
  const CoinPlate({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    Widget slot() => Container(
          width: 18,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: p.title.withValues(alpha: .8), width: 2),
          ),
          alignment: Alignment.center,
          child: Container(width: 3, height: 18, color: p.title.withValues(alpha: .5)),
        );
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: .6), width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, textAlign: TextAlign.center, style: pixelLabel(context, size: 8, color: p.title)),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [slot(), const SizedBox(width: 14), slot()]),
        ],
      ),
    );
  }
}
