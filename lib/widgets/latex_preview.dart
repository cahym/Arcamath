import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renderiza a formula montada pelo usuario em LaTeX (flutter_math_fork).
class LatexPreview extends StatelessWidget {
  const LatexPreview(this.tex, {super.key});
  final String tex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Math.tex(
        tex,
        textStyle: TextStyle(fontSize: 26, color: cs.onSurface),
        onErrorFallback: (_) => Text(tex, style: TextStyle(color: cs.error)),
      ),
    );
  }
}
