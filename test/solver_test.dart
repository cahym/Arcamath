import 'package:arcamath/game/expression.dart';
import 'package:arcamath/game/level.dart';
import 'package:arcamath/game/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acha solucao para 5261 no nivel avancado', () {
    final s = solveEquation(5261, Level.advanced);
    expect(s, isNotNull);
    expect(checkEquation(tokensFor(5261, s!.gaps), Level.advanced).correct, isTrue);
  });

  test('toda solucao encontrada passa na verificacao do jogo', () {
    for (final n in [1234, 2468, 9081, 4096, 7312, 1000, 3333, 8131]) {
      for (final lv in Level.values) {
        final s = solveEquation(n, lv);
        if (s != null) {
          expect(checkEquation(tokensFor(n, s.gaps), lv).correct, isTrue, reason: '$n $lv');
          expect(s.gaps.length, 5);
        }
      }
    }
  });

  test('desempenho: 200 numeros no nivel dificil em tempo razoavel', () {
    final sw = Stopwatch()..start();
    for (var n = 1000; n < 1200; n++) {
      solveEquation(n, Level.hard);
    }
    // ajuste o limite se o seu computador for lento
    expect(sw.elapsedMilliseconds, lessThan(20000));
  });
}
