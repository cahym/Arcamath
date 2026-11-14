import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../state/providers.dart';
import 'expression.dart';
import 'level.dart';
import 'solver.dart';

enum VerdictKind { correct, wrong, error, saveFailed }

class Verdict {
  const Verdict(this.kind, {this.points = 0, this.left, this.right, this.error});
  final VerdictKind kind;
  final int points;
  final double? left, right;
  final ExprErrorKind? error;
}

/// Dicas gastas -> pontos: 0 dicas = cheio, 1-2 = metade, 3 (solucao revelada) = zero.
int pointsFor(Level l, int hints) => hints <= 0 ? l.points : (hints >= 3 ? 0 : (l.points / 2).round());

List<List<String>> freshGaps() => List.generate(5, (i) => i == 2 ? ['='] : <String>[]);

class GameState {
  const GameState({
    required this.level,
    required this.round,
    required this.gaps,
    this.selected = 2,
    this.flying = false,
    this.verdict,
    this.hints = 0,
    this.solution,
  });

  final Level level;

  /// Sorteio assincrono do numero (consultado pelo FutureBuilder da tela).
  final Future<int> round;

  /// 5 lacunas: antes do 1o digito, entre cada par de digitos e depois do 4o.
  final List<List<String>> gaps;
  final int selected;

  /// true durante a animacao dos simbolos "voltando" para a bandeja.
  final bool flying;
  final Verdict? verdict;

  /// Dicas usadas nesta rodada (0 a 3) e a solucao encontrada pelo solucionador.
  final int hints;
  final Solution? solution;

  GameState copyWith({
    Level? level,
    Future<int>? round,
    List<List<String>>? gaps,
    int? selected,
    bool? flying,
    Verdict? verdict,
    bool clearVerdict = false,
    int? hints,
    Solution? solution,
  }) =>
      GameState(
        level: level ?? this.level,
        round: round ?? this.round,
        gaps: gaps ?? this.gaps,
        selected: selected ?? this.selected,
        flying: flying ?? this.flying,
        verdict: clearVerdict ? null : (verdict ?? this.verdict),
        hints: hints ?? this.hints,
        solution: solution ?? this.solution,
      );
}

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    final level = Level.values[(prefs.getInt(kLevelKey) ?? 0).clamp(0, Level.values.length - 1)];
    return GameState(level: level, round: _draw(level), gaps: freshGaps());
  }

  /// Sorteia um numero nao resolvido E com solucao (o solucionador e rapido e cede ao event loop).
  Future<int> _draw(Level l, {int? exclude}) => ref.read(repositoryProvider).pickUnsolved(
        l,
        exclude: exclude,
        accept: (n) async {
          await Future<void>.delayed(Duration.zero);
          return solveEquation(n, l) != null;
        },
      );

  List<List<String>> _copy() => [for (final g in state.gaps) [...g]];

  void setLevel(Level l) {
    if (l == state.level) return;
    ref.read(sharedPrefsProvider).setInt(kLevelKey, l.index);
    state = GameState(level: l, round: _draw(l), gaps: freshGaps());
  }

  void retry() => state = GameState(level: state.level, round: _draw(state.level), gaps: freshGaps());

  void select(int i) => state = state.copyWith(selected: i);

  void moveSelection(int delta) => state = state.copyWith(selected: (state.selected + delta).clamp(0, 4));

  /// Dica progressiva: 1 = posicao do "=", 2 = simbolos usados, 3 = revela a solucao (0 pontos).
  Future<void> hint(int number) async {
    if (state.flying || state.hints >= 3) return;
    final round = state.round;
    final sol = state.solution ?? await solveEquationAsync(number, state.level);
    if (!identical(round, state.round)) return; // pulou/trocou de rodada enquanto calculava
    final h = state.hints + 1;
    state = state.copyWith(
      hints: h,
      solution: sol,
      clearVerdict: true,
      gaps: (h == 3 && sol != null) ? [for (final g in sol.gaps) [...g]] : null,
    );
    ref.read(sfxProvider).play('tap.wav');
  }

  void addToken(String t, {int? gap}) {
    if (state.flying) return;
    final g = gap ?? state.selected;
    final gaps = _copy()..[g].add(t);
    state = state.copyWith(gaps: gaps, selected: g, clearVerdict: true);
    ref.read(sfxProvider).play('tap.wav');
  }

  void removeAt(int gap, int index) {
    if (state.flying) return;
    final gaps = _copy()..[gap].removeAt(index);
    state = state.copyWith(gaps: gaps, selected: gap, clearVerdict: true);
  }

  void backspace() {
    if (state.flying) return;
    final gaps = _copy();
    final g = gaps[state.selected];
    if (g.isEmpty) return;
    g.removeLast();
    state = state.copyWith(gaps: gaps, clearVerdict: true);
  }

  void clear() {
    if (state.flying) return;
    state = state.copyWith(gaps: freshGaps(), selected: 2, clearVerdict: true);
  }

  /// "Pular": descarta o numero atual (sem pontuar) e sorteia outro.
  void skip(int number) {
    if (state.flying) return;
    state = GameState(level: state.level, round: _draw(state.level, exclude: number), gaps: freshGaps());
  }

  Future<void> check(int number) async {
    if (state.flying) return;
    final level = state.level;
    final tokens = tokensFor(number, state.gaps);
    final out = checkEquation(tokens, level);
    final sfx = ref.read(sfxProvider);

    if (out.error != null) {
      state = state.copyWith(verdict: Verdict(VerdictKind.error, error: out.error!.kind));
      sfx.play('fail.wav');
      return;
    }
    if (!out.correct) {
      state = state.copyWith(verdict: Verdict(VerdictKind.wrong, left: out.left, right: out.right));
      sfx.play('fail.wav');
      return;
    }

    // Acertou: dispara a animacao (simbolos voltam para a bandeja) e grava no Firestore.
    final pts = pointsFor(level, state.hints);
    state = state.copyWith(flying: true, verdict: Verdict(VerdictKind.correct, points: pts));
    sfx.play('win.wav');
    try {
      await ref.read(repositoryProvider).saveSolved(
            number: number,
            level: level,
            expression: mergeDigits(tokens).join(' '),
            points: pts,
          );
    } catch (_) {
      state = state.copyWith(verdict: const Verdict(VerdictKind.saveFailed));
    }
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = GameState(level: level, round: _draw(level), gaps: freshGaps(), verdict: state.verdict);
  }
}

final gameProvider = NotifierProvider<GameNotifier, GameState>(GameNotifier.new);
