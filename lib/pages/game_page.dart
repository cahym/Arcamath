import 'package:arcamath/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../data/repository.dart';
import '../game/expression.dart';
import '../game/game_controller.dart';
import '../game/l10n_helpers.dart';
import '../game/level.dart';
import '../state/providers.dart';
import '../widgets/arcade.dart';
import '../widgets/cabinet.dart';
import '../widgets/latex_preview.dart';

/// Maior pontuacao do ranking (usada no "RECORDE").
final _topProvider = FutureProvider.autoDispose<List<RankEntry>>(
  (ref) => ref.read(repositoryProvider).topPlayers(limit: 1),
);

/// Posicao do usuario no ranking (null enquanto ele ainda nao pontuou).
/// Le a pontuacao uma vez (ref.read); o _Hud pede a atualizacao quando a pontuacao muda.
final _myRankProvider = FutureProvider.autoDispose<int?>((ref) async {
  final data = await ref.read(userDocProvider.future);
  final score = (data?['score'] as num?)?.toInt() ?? 0;
  if (score <= 0) return null;
  return ref.read(repositoryProvider).myRank(score);
});

/// Tela principal: um gabinete de fliperama.
///  - TELA: placar, recorde + posicao no ranking, coracoes (dicas), expressao, botoes DICA / VERIFICAR / PULAR
///    e, ao lado (ou abaixo, no celular), a faixa de controle com os operadores como botoes redondos,
///    o joystick e a plaquinha de ficha.
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final round = ref.watch(gameProvider.select((g) => g.round));
    return SafeArea(
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxWidth < 760;
        final side = compact ? 8.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, compact ? 8 : 20, side, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: ArcadeCabinet(
                compact: compact,
                screen: _ScreenContent(round: round, compact: compact),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ------------------------------------------------------------------ conteudo da tela

class _ScreenContent extends StatelessWidget {
  const _ScreenContent({required this.round, required this.compact});
  final Future<int> round;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    // FutureBuilder: aguarda o Firestore + solucionador informarem um numero valido.
    final main = FutureBuilder<int>(
      future: round,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.symmetric(vertical: 70), child: ArcadeLoader());
        }
        if (snap.hasError) return _RoundError(error: snap.error!);
        return _Play(number: snap.data!, compact: compact);
      },
    );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Hud(compact: compact),
      const SizedBox(height: 12),
      Container(height: 2, color: p.grid.withValues(alpha: .7)),
      SizedBox(height: compact ? 14 : 18),
      if (compact) ...[
        main,
        const SizedBox(height: 18),
        const _Deck(compact: true),
      ] else
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: main),
          const SizedBox(width: 18),
          const SizedBox(width: 290, child: _Deck(compact: false)),
        ]),
    ]);
  }
}

class _Hud extends ConsumerWidget {
  const _Hud({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(userDocProvider).asData?.value;
    final score = (data?['score'] as num?)?.toInt() ?? 0;
    final solved = (data?['solvedCount'] as num?)?.toInt() ?? 0;
    final top = ref.watch(_topProvider).asData?.value;
    final high = (top == null || top.isEmpty) ? 0 : top.first.score;
    final rank = ref.watch(_myRankProvider).value;
    final hints = ref.watch(gameProvider.select((g) => g.hints));
    final size = compact ? 13.0 : 20.0;

    // Quando minha pontuacao muda, atualiza recorde e posicao depois que o servidor tiver tempo de confirmar.
    ref.listen<int?>(
      userDocProvider.select((v) => (v.value?['score'] as num?)?.toInt()),
      (a, b) {
        if (a != b) {
          Future<void>.delayed(const Duration(seconds: 3), () {
            if (!context.mounted) return;
            ref.invalidate(_topProvider);
            ref.invalidate(_myRankProvider);
          });
        }
      },
    );

    Widget cell(String label, Widget value, CrossAxisAlignment a) => Column(
          crossAxisAlignment: a,
          children: [Text(label, style: pixelLabel(context, size: compact ? 8 : 10)), const SizedBox(height: 8), value],
        );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: cell(
          l.score.toUpperCase(),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AnimatedCount(value: score, style: arcadeStyle(context, size: size), pad: 6),
            const SizedBox(height: 6),
            Text(l.solvedCount(solved), style: pixelLabel(context, size: 8)),
          ]),
          CrossAxisAlignment.start,
        ),
      ),
      Expanded(
        child: cell(
          l.highScore,
          Column(children: [
            AnimatedCount(value: high, style: arcadeStyle(context, size: size), pad: 6),
            const SizedBox(height: 6),
            Text(l.yourRank(rank == null ? '—' : '#$rank'), style: pixelLabel(context, size: 8)),
          ]),
          CrossAxisAlignment.center,
        ),
      ),
      Expanded(
        // Os 3 coracoes sao as dicas disponiveis.
        child: cell(
          l.hint,
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Padding(padding: const EdgeInsets.only(left: 4), child: PixelHeart(filled: i >= hints, size: compact ? 18 : 28)),
          ]),
          CrossAxisAlignment.end,
        ),
      ),
    ]);
  }
}

class _RoundError extends ConsumerWidget {
  const _RoundError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final msg = error is AllSolvedException ? l.allSolved : l.loadError(error.toString());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(children: [
        Text(msg, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ArcadeButton(label: l.retry, onPressed: () => ref.read(gameProvider.notifier).retry()),
      ]),
    );
  }
}

// ------------------------------------------------------------------ rodada

class _Play extends ConsumerWidget {
  const _Play({required this.number, required this.compact});
  final int number;
  final bool compact;

  /// Atalhos de teclado (jogo para computador).
  KeyEventResult _onKey(WidgetRef ref, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final n = ref.read(gameProvider.notifier);
    final level = ref.read(gameProvider).level;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      n.check(number);
    } else if (k == LogicalKeyboardKey.backspace) {
      n.backspace();
    } else if (k == LogicalKeyboardKey.arrowLeft) {
      n.moveSelection(-1);
    } else if (k == LogicalKeyboardKey.arrowRight) {
      n.moveSelection(1);
    } else if (k == LogicalKeyboardKey.escape) {
      n.clear();
    } else {
      final ch = e.character;
      if (ch == null || ch.isEmpty) return KeyEventResult.ignored;
      switch (ch.toLowerCase()) {
        case 'h':
          n.hint(number);
        case 's':
          n.skip(number);
        default:
          final t = switch (ch.toLowerCase()) { '^' => '**', 'r' => '√', 'c' => '∛', _ => ch };
          if (!level.tray.contains(t)) return KeyEventResult.ignored;
          n.addToken(t);
      }
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final cs = Theme.of(context).colorScheme;
    final game = ref.watch(gameProvider);
    final n = ref.read(gameProvider.notifier);
    final busy = game.flying;
    final tex = previewLatex(tokensFor(number, game.gaps));
    final v = game.verdict;
    final small = pixelLabel(context, size: compact ? 8 : 9);

    final msgs = <Widget>[];
    if (v != null) {
      msgs.add(Text(
        verdictText(l, v),
        textAlign: TextAlign.center,
        style: pixelLabel(context, size: 10, color: v.kind == VerdictKind.correct ? p.title : cs.error),
      ));
    }
    if (game.hints >= 1) {
      final sol = game.solution;
      if (sol == null) {
        msgs.add(Text(l.hintNone, textAlign: TextAlign.center, style: small));
      } else {
        msgs.add(Text(l.hintEquals(sol.leftDigits), textAlign: TextAlign.center, style: small));
        if (game.hints >= 2) {
          msgs.add(Text(l.hintSymbols(sol.symbols.map(tokenLabel).join('  ')), textAlign: TextAlign.center, style: small));
        }
        if (game.hints >= 3) msgs.add(Text(l.hintReveal, textAlign: TextAlign.center, style: small));
      }
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) => _onKey(ref, e),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // nivel (centro) + DICA (canto superior direito)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Expanded(child: _LevelMenu()),
          const SizedBox(width: 8),
          ArcadeButton(
            compact: true,
            icon: Icons.lightbulb,
            label: '${l.hint} ${game.hints}/3',
            color: p.shadow,
            onPressed: (busy || game.hints >= 3) ? null : () => n.hint(number),
          ),
        ]),
        SizedBox(height: compact ? 14 : 22),
        _NumberRow(number: number, compact: compact),
        const SizedBox(height: 10),
        // VERIFICAR: logo abaixo da expressao, centralizado
        Center(
          child: ArcadeButton(
            large: true,
            icon: Icons.check,
            label: l.check,
            color: p.title,
            onPressed: busy ? null : () => n.check(number),
          ),
        ),
        const SizedBox(height: 16),
        Container(height: 2, color: p.grid.withValues(alpha: .7)),
        const SizedBox(height: 10),
        Text(l.latexTitle.toUpperCase(), textAlign: TextAlign.center, style: pixelLabel(context, size: 8)),
        const SizedBox(height: 6),
        Center(child: LatexPreview(tex)),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(children: [
            for (final m in msgs) Padding(padding: const EdgeInsets.only(top: 12), child: m),
          ]),
        ),
        const SizedBox(height: 16),
        // PULAR: canto inferior esquerdo
        Row(children: [
          ArcadeButton(
            compact: true,
            icon: Icons.skip_next,
            label: l.skip,
            onPressed: busy ? null : () => n.skip(number),
          ),
          const Spacer(),
        ]),
      ]),
    );
  }
}

/// Seletor de nivel no estilo "YES ◀  NO" das referencias.
class _LevelMenu extends ConsumerWidget {
  const _LevelMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final level = ref.watch(gameProvider.select((g) => g.level));
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 10,
      children: [
        for (final lv in Level.values)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => ref.read(gameProvider.notifier).setLevel(lv),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  levelName(l, lv).toUpperCase(),
                  style: pixelLabel(context, size: 10, color: lv == level ? p.text : p.text.withValues(alpha: .45)),
                ),
                SizedBox(width: 20, child: lv == level ? Icon(Icons.arrow_left, color: p.title, size: 24) : null),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Digitos em UMA linha horizontal; as lacunas de operadores ficam logo ABAIXO, entre os digitos.
class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.number, required this.compact});
  final int number;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final digits = number.toString().padLeft(4, '0').split('');
    final digitW = compact ? 52.0 : 80.0, digitH = compact ? 62.0 : 90.0;
    const slotGap = 12.0, slotMin = 56.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < 5; i++) ...[
          Column(children: [SizedBox(height: digitH + slotGap), _Slot(index: i)]),
          if (i < 4)
            Column(children: [
              SizedBox(
                width: digitW,
                height: digitH,
                child: Center(child: Text(digits[i], style: arcadeStyle(context, size: compact ? 40 : 60))),
              ),
              const SizedBox(height: slotGap + slotMin),
            ]),
        ],
      ]),
    );
  }
}

/// Lacuna entre digitos: alvo de clique e de arraste.
class _Slot extends ConsumerWidget {
  const _Slot({required this.index});
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.arcade;
    final game = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    final tokens = game.gaps[index];
    final selected = game.selected == index;

    return DragTarget<String>(
      onAcceptWithDetails: (d) => notifier.addToken(d.data, gap: index),
      builder: (context, candidates, _) {
        final hot = selected || candidates.isNotEmpty;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => notifier.select(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
              padding: const EdgeInsets.all(6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hot ? p.title.withValues(alpha: .16) : p.bg.withValues(alpha: .35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hot ? p.title : p.grid, width: hot ? 4 : 3),
                boxShadow: hot ? [BoxShadow(color: p.shadow, offset: const Offset(3, 3))] : null,
              ),
              child: tokens.isEmpty
                  ? Icon(Icons.add, size: 16, color: p.text.withValues(alpha: .35))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      for (var k = 0; k < tokens.length; k++)
                        Padding(
                          padding: EdgeInsets.only(left: k == 0 ? 0 : 4),
                          child: _Chip(token: tokens[k], flying: game.flying, onTap: () => notifier.removeAt(index, k)),
                        ),
                    ]),
            ),
          ),
        );
      },
    );
  }
}

/// Simbolo colocado numa lacuna. Ao acertar (flying) ele desce e some, "voltando" ao painel.
class _Chip extends StatelessWidget {
  const _Chip({required this.token, required this.flying, required this.onTap});
  final String token;
  final bool flying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.arcade;
    const d = Duration(milliseconds: 650);
    return AnimatedSlide(
      duration: d,
      curve: Curves.easeInBack,
      offset: flying ? const Offset(0, 7) : Offset.zero,
      child: AnimatedOpacity(
        duration: d,
        opacity: flying ? 0 : 1,
        child: AnimatedScale(
          duration: d,
          scale: flying ? .3 : 1,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: p.title,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: p.shadow, offset: const Offset(2, 2))],
              ),
              child: Text(tokenLabel(token), style: symbolStyle(p.bg, size: 20)),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ painel de controle

/// Cor do botao conforme o tipo de operador.
Color _domeColor(String t) => switch (t) {
      '+' || '-' || '*' || '/' => const Color(0xFFE53935), // aritmetica: vermelho
      '**' || '√' || '∛' || '!' => const Color(0xFF2ECC71), // potencia/raiz/fatorial: verde
      '⌊' || '⌋' || '⌈' || '⌉' => const Color(0xFFF5C518), // base/teto: amarelo
      _ => const Color(0xFF2E7DFF), // ( ) | = : azul
    };

class _Deck extends ConsumerWidget {
  const _Deck({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final game = ref.watch(gameProvider);
    final tokens = game.level.tray;
    final size = compact ? 42.0 : 50.0;
    const gap = 10.0;
    // Faixa lateral (tela larga): botoes em 4 colunas. Celular: ate 8 colunas, em faixa mais baixa.
    final cols = compact ? (tokens.length / 2).ceil().clamp(4, 8) : 4;
    final gridW = cols * size + (cols - 1) * gap + 1;

    final grid = FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: gridW,
        child: Wrap(spacing: gap, runSpacing: 8, children: [
          for (final t in tokens) _Key(token: t, size: size, enabled: !game.flying),
        ]),
      ),
    );
    final multi = Text(
      l.multiOperatorHint,
      textAlign: TextAlign.center,
      style: pixelLabel(context, size: compact ? 8 : 9, color: p.title).copyWith(height: 1.7),
    );
    final hint = Text(
      l.trayHint,
      textAlign: TextAlign.center,
      style: pixelLabel(context, size: 7, color: p.text.withValues(alpha: .85)).copyWith(height: 1.8),
    );
    final title = Text(l.trayTitle.toUpperCase(), textAlign: TextAlign.center, style: pixelLabel(context, size: 9, color: p.text));

    return DeckPanel(
      compact: compact,
      color: p.grid,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        title,
        const SizedBox(height: 10),
        multi,
        const SizedBox(height: 12),
        grid,
        if (!compact) ...[
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Joystick(size: 70),
            CoinPlate(label: l.insertCoin),
          ]),
        ],
        const SizedBox(height: 14),
        hint,
      ]),
    );
  }
}

/// Botao redondo do painel: clique adiciona na lacuna selecionada; arrastar solta em qualquer lacuna.
class _Key extends ConsumerWidget {
  const _Key({required this.token, required this.size, required this.enabled});
  final String token;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _domeColor(token);
    final button = DomeButton(
      color: color,
      label: tokenLabel(token),
      size: size,
      onPressed: enabled ? () => ref.read(gameProvider.notifier).addToken(token) : null,
    );
    return Draggable<String>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: DomeButton(color: color, label: tokenLabel(token), size: size * 1.15, onPressed: () {}),
      ),
      childWhenDragging: Opacity(opacity: .35, child: button),
      child: button,
    );
  }
}
