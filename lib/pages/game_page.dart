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
import '../widgets/latex_preview.dart';

/// Maior pontuacao do ranking (placar "HIGH SCORE" do topo).
final _highScoreProvider = FutureProvider.autoDispose<int>((ref) async {
  final top = await ref.read(repositoryProvider).topPlayers(limit: 1);
  return top.isEmpty ? 0 : top.first.score;
});

/// Tela principal pensada para computador: HUD no topo, tela CRT com os NUMEROS NA HORIZONTAL
/// e os OPERADORES ABAIXO deles (lacunas sob os espacos entre digitos + bandeja de simbolos).
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final round = ref.watch(gameProvider.select((g) => g.round));
    return SafeArea(
      child: LayoutBuilder(builder: (context, c) {
        final compact = c.maxWidth < 720;
        final side = compact ? 12.0 : 32.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(side, 20, side, 110),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _Hud(compact: compact),
                const SizedBox(height: 18),
                // FutureBuilder: aguarda o Firestore + solucionador informarem um numero valido.
                FutureBuilder<int>(
                  future: round,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(padding: EdgeInsets.all(64), child: ArcadeLoader());
                    }
                    if (snap.hasError) return _RoundError(error: snap.error!);
                    return _Round(number: snap.data!, compact: compact);
                  },
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

// ------------------------------------------------------------------ HUD

class _Hud extends ConsumerWidget {
  const _Hud({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final data = ref.watch(userDocProvider).when(
      data: (value) => value,
      loading: () => null,
      error: (_, __) => null,
    );
    final score = (data?['score'] as num?)?.toInt() ?? 0;
    final solved = (data?['solvedCount'] as num?)?.toInt() ?? 0;
    final high = ref.watch(_highScoreProvider).when(
      data: (value) => value,
      loading: () => 0,
      error: (_, __) => 0,
    );
    final hints = ref.watch(gameProvider.select((g) => g.hints));
    final size = compact ? 14.0 : 20.0;

    Widget cell(String label, Widget value, CrossAxisAlignment a) => Column(
          crossAxisAlignment: a,
          children: [Text(label, style: pixelLabel(context)), const SizedBox(height: 8), value],
        );

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: cell(
          l.score.toUpperCase(),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(score.toString().padLeft(6, '0'), style: arcadeStyle(context, size: size)),
            const SizedBox(height: 6),
            Text(l.solvedCount(solved), style: pixelLabel(context, size: 8)),
          ]),
          CrossAxisAlignment.start,
        ),
      ),
      Expanded(
        child: cell(l.highScore, Text(high.toString().padLeft(6, '0'), style: arcadeStyle(context, size: size)),
            CrossAxisAlignment.center),
      ),
      Expanded(
        // Os 3 coracoes sao as dicas disponiveis.
        child: cell(
          l.hint,
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (var i = 0; i < 3; i++)
              Padding(padding: const EdgeInsets.only(left: 4), child: PixelHeart(filled: i >= hints, size: compact ? 20 : 28)),
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
    return ArcadePanel(
      child: Column(children: [
        Text(msg, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ArcadeButton(label: l.retry, onPressed: () => ref.read(gameProvider.notifier).retry()),
      ]),
    );
  }
}

// ------------------------------------------------------------------ rodada

class _Round extends ConsumerWidget {
  const _Round({required this.number, required this.compact});
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
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) => _onKey(ref, e),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Cabinet(number: number, compact: compact),
        const SizedBox(height: 20),
        _Controls(number: number),
      ]),
    );
  }
}

/// Tela CRT: nivel, numero (horizontal) com lacunas de operadores abaixo, LaTeX e mensagens.
class _Cabinet extends ConsumerWidget {
  const _Cabinet({required this.number, required this.compact});
  final int number;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final cs = Theme.of(context).colorScheme;
    final game = ref.watch(gameProvider);
    final tex = previewLatex(tokensFor(number, game.gaps));
    final v = game.verdict;
    final small = pixelLabel(context, size: compact ? 9 : 10);

    final msgs = <Widget>[];
    if (v != null) {
      msgs.add(Text(
        verdictText(l, v),
        textAlign: TextAlign.center,
        style: pixelLabel(context, size: 11, color: v.kind == VerdictKind.correct ? p.title : cs.error),
      ));
    }
    if (game.hints >= 1) {
      final sol = game.solution;
      if (sol == null) {
        msgs.add(Text(l.hintNone, textAlign: TextAlign.center, style: small));
      } else {
        if (game.hints >= 1) msgs.add(Text(l.hintEquals(sol.leftDigits), textAlign: TextAlign.center, style: small));
        if (game.hints >= 2) {
          msgs.add(Text(l.hintSymbols(sol.symbols.map(tokenLabel).join('  ')), textAlign: TextAlign.center, style: small));
        }
        if (game.hints >= 3) msgs.add(Text(l.hintReveal, textAlign: TextAlign.center, style: small));
      }
    }

    return CrtFrame(
      padding: EdgeInsets.fromLTRB(compact ? 14 : 32, 24, compact ? 14 : 32, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _LevelMenu(),
        SizedBox(height: compact ? 20 : 30),
        _NumberRow(number: number, compact: compact),
        const SizedBox(height: 22),
        Container(height: 2, color: p.grid.withValues(alpha: .7)),
        const SizedBox(height: 12),
        Text(l.latexTitle.toUpperCase(), textAlign: TextAlign.center, style: pixelLabel(context, size: 8)),
        const SizedBox(height: 6),
        Center(child: LatexPreview(tex)),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: Column(children: [
            for (final m in msgs) Padding(padding: const EdgeInsets.only(top: 12), child: m),
          ]),
        ),
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
      spacing: 26,
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
                  style: pixelLabel(context, size: 11, color: lv == level ? p.text : p.text.withValues(alpha: .45)),
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
    final digitW = compact ? 56.0 : 80.0, digitH = compact ? 66.0 : 90.0;
    const slotGap = 12.0, slotMin = 56.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < 5; i++) ...[
          // coluna da lacuna i: espaco do digito + lacuna embaixo
          Column(children: [SizedBox(height: digitH + slotGap), _Slot(index: i)]),
          if (i < 4)
            Column(children: [
              SizedBox(
                width: digitW,
                height: digitH,
                child: Center(child: Text(digits[i], style: arcadeStyle(context, size: compact ? 42 : 60))),
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

/// Simbolo colocado numa lacuna. Ao acertar (flying) ele desce e some, "voltando" a bandeja.
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

// ------------------------------------------------------------------ bandeja + botoes

class _Controls extends ConsumerWidget {
  const _Controls({required this.number});
  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final p = context.arcade;
    final game = ref.watch(gameProvider);
    final n = ref.read(gameProvider.notifier);
    final busy = game.flying;

    return ArcadePanel(
      title: l.trayTitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Operadores abaixo do numero, numa unica faixa horizontal.
        Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
          for (final t in game.level.tray) _TokenKey(token: t),
        ]),
        const SizedBox(height: 6),
        Text(l.trayHint, textAlign: TextAlign.center, style: pixelLabel(context, size: 8).copyWith(height: 1.7)),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 4, children: [
          ArcadeButton(icon: Icons.backspace_outlined, tooltip: l.backspace, onPressed: busy ? null : n.backspace),
          ArcadeButton(label: l.clear, onPressed: busy ? null : n.clear),
          ArcadeButton(label: l.skip, color: p.shadow, onPressed: busy ? null : () => n.skip(number)),
          ArcadeButton(
            icon: Icons.lightbulb_outline,
            label: '${l.hint} ${game.hints}/3',
            onPressed: (busy || game.hints >= 3) ? null : () => n.hint(number),
          ),
          ArcadeButton(label: l.check, color: p.title, onPressed: busy ? null : () => n.check(number)),
        ]),
      ]),
    );
  }
}

/// Tecla da bandeja: clique adiciona na lacuna selecionada; arrastar solta em qualquer lacuna.
class _TokenKey extends ConsumerWidget {
  const _TokenKey({required this.token});
  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.arcade;
    final key = ArcadeButton(
      compact: true,
      symbol: true,
      label: tokenLabel(token),
      onPressed: () => ref.read(gameProvider.notifier).addToken(token),
    );
    return Draggable<String>(
      data: token,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.title,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: p.shadow, offset: const Offset(3, 3))],
          ),
          child: Text(tokenLabel(token), style: symbolStyle(p.bg, size: 24)),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: key),
      child: key,
    );
  }
}
