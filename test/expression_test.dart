import 'package:arcamath/game/expression.dart';
import 'package:arcamath/game/level.dart';
import 'package:flutter_test/flutter_test.dart';

List<List<String>> g(List<List<String>> x) => x;

void main() {
  test('(5-2)! = 6*1 no nivel avancado', () {
    final gaps = g([['('], ['-'], [')', '!', '='], ['*'], []]);
    final out = checkEquation(tokensFor(5261, gaps), Level.advanced);
    expect(out.correct, isTrue);
  });

  test('raiz de (8+1) = 3**1 e LaTeX', () {
    final gaps = g([['√', '('], ['+'], [')', '='], ['**'], []]);
    final t = tokensFor(8131, gaps);
    expect(checkEquation(t, Level.intermediate).correct, isTrue);
    expect(previewLatex(t), r'\sqrt{\left(8 + 1\right)} = {3}^{1}');
  });

  test('base so vale no facil, divisao fracionaria so no facil', () {
    final gaps = g([['⌊'], ['/'], ['⌋', '='], ['*'], []]);
    final t = tokensFor(5221, gaps);
    expect(checkEquation(t, Level.easy).correct, isTrue);
    expect(checkEquation(t, Level.intermediate).error?.kind, ExprErrorKind.syntax);
    final div = tokensFor(5221, g([[], ['/'], ['='], [], []]));
    expect(checkEquation(div, Level.intermediate).error?.kind, ExprErrorKind.nonIntegerDivision);
  });

  test('exatamente um sinal de igual', () {
    final out = checkEquation(tokensFor(1234, g([[], [], [], [], []])), Level.hard);
    expect(out.error?.kind, ExprErrorKind.needEquals);
  });

  test('digitos adjacentes viram um numero', () {
    // 1 2 | 1 2  ->  12 = 12
    final out = checkEquation(tokensFor(1212, g([[], [], ['='], [], []])), Level.hard);
    expect(out.correct, isTrue);
  });
}
