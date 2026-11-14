import 'dart:math' as math;

import 'level.dart';

enum ExprErrorKind { syntax, needEquals, divZero, nonIntegerDivision, factorial, domain, overflow }

class ExprException implements Exception {
  const ExprException(this.kind);
  final ExprErrorKind kind;
  @override
  String toString() => 'ExprException($kind)';
}

const _eps = 1e-9;
const _limit = 1e15;

bool _isInt(double v) => (v - v.roundToDouble()).abs() < _eps * math.max(1.0, v.abs());

double _guard(double v) {
  if (v.isNaN) throw const ExprException(ExprErrorKind.domain);
  if (v.isInfinite || v.abs() > _limit) throw const ExprException(ExprErrorKind.overflow);
  return v;
}

bool _isDigits(String s) => s.isNotEmpty && s.codeUnits.every((c) => c >= 48 && c <= 57);

// ---------------------------------------------------------------- AST

sealed class Node {
  const Node();
  double eval(bool fractions);
  String latex();
}

class Num extends Node {
  const Num(this.digits);
  final String digits;
  @override
  double eval(bool f) => double.parse(digits);
  @override
  String latex() => digits;
}

class Neg extends Node {
  const Neg(this.a);
  final Node a;
  @override
  double eval(bool f) => -a.eval(f);
  @override
  String latex() => '-${a.latex()}';
}

class Bin extends Node {
  const Bin(this.op, this.a, this.b);
  final String op;
  final Node a, b;

  @override
  double eval(bool f) {
    final x = a.eval(f), y = b.eval(f);
    switch (op) {
      case '+':
        return _guard(x + y);
      case '-':
        return _guard(x - y);
      case '*':
        return _guard(x * y);
      default:
        if (y.abs() < _eps) throw const ExprException(ExprErrorKind.divZero);
        final r = x / y;
        if (!f && !_isInt(r)) throw const ExprException(ExprErrorKind.nonIntegerDivision);
        return _guard(f ? r : r.roundToDouble());
    }
  }

  @override
  String latex() {
    final sym = switch (op) { '*' => r'\times', '/' => r'\div', _ => op };
    return '${a.latex()} $sym ${b.latex()}';
  }
}

class Pow extends Node {
  const Pow(this.a, this.b);
  final Node a, b;
  @override
  double eval(bool f) {
    final x = a.eval(f), y = b.eval(f);
    if (x == 0 && y < 0) throw const ExprException(ExprErrorKind.domain);
    return _guard(math.pow(x, y).toDouble());
  }

  @override
  String latex() => '{${a.latex()}}^{${b.latex()}}';
}

class Fact extends Node {
  const Fact(this.a);
  final Node a;
  @override
  double eval(bool f) {
    final v = a.eval(f);
    if (!_isInt(v) || v < -_eps || v > 20) throw const ExprException(ExprErrorKind.factorial);
    var r = 1.0;
    for (var i = 2; i <= v.round(); i++) {
      r *= i;
    }
    return r;
  }

  @override
  String latex() => '{${a.latex()}}!';
}

class Root extends Node {
  const Root(this.degree, this.a);
  final int degree;
  final Node a;
  @override
  double eval(bool f) {
    final v = a.eval(f);
    double r;
    if (degree == 2) {
      if (v < 0) throw const ExprException(ExprErrorKind.domain);
      r = math.sqrt(v);
    } else {
      r = v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();
    }
    final snapped = r.roundToDouble();
    if ((math.pow(snapped, degree) - v).abs() < _eps) r = snapped;
    return r;
  }

  @override
  String latex() => degree == 2 ? r'\sqrt{' '${a.latex()}}' : r'\sqrt[3]{' '${a.latex()}}';
}

/// Parenteses, modulo |x|, base ⌊x⌋ e teto ⌈x⌉.
class Wrapped extends Node {
  const Wrapped(this.kind, this.a);
  final String kind;
  final Node a;
  @override
  double eval(bool f) {
    final v = a.eval(f);
    switch (kind) {
      case '|':
        return v.abs();
      case '⌊':
        return (v + _eps).floorToDouble();
      case '⌈':
        return (v - _eps).ceilToDouble();
      default:
        return v;
    }
  }

  @override
  String latex() {
    final i = a.latex();
    return switch (kind) {
      '|' => r'\left|' + i + r'\right|',
      '⌊' => r'\left\lfloor ' + i + r'\right\rfloor ',
      '⌈' => r'\left\lceil ' + i + r'\right\rceil ',
      _ => r'\left(' + i + r'\right)',
    };
  }
}

// ---------------------------------------------------------------- parser

/// Gramatica (precedencia crescente):
///   expr    := term (('+'|'-') term)*
///   term    := unary (('*'|'/') unary)*
///   unary   := '-' unary | power
///   power   := postfix ('**' unary)?          (associativa a direita)
///   postfix := primary '!'*
///   primary := NUM | '(' expr ')' | '|' expr '|' | '⌊' expr '⌋' | '⌈' expr '⌉'
///            | '√' postfix | '∛' postfix
class _Parser {
  _Parser(this.t);
  final List<String> t;
  int i = 0;

  String? get peek => i < t.length ? t[i] : null;

  Node parse() {
    final n = _expr();
    if (peek != null) throw const ExprException(ExprErrorKind.syntax);
    return n;
  }

  void _expect(String s) {
    if (peek != s) throw const ExprException(ExprErrorKind.syntax);
    i++;
  }

  Node _expr() {
    var n = _term();
    while (peek == '+' || peek == '-') {
      final op = t[i++];
      n = Bin(op, n, _term());
    }
    return n;
  }

  Node _term() {
    var n = _unary();
    while (peek == '*' || peek == '/') {
      final op = t[i++];
      n = Bin(op, n, _unary());
    }
    return n;
  }

  Node _unary() {
    if (peek == '-') {
      i++;
      return Neg(_unary());
    }
    return _power();
  }

  Node _power() {
    final b = _postfix();
    if (peek == '**') {
      i++;
      return Pow(b, _unary());
    }
    return b;
  }

  Node _postfix() {
    var n = _primary();
    while (peek == '!') {
      i++;
      n = Fact(n);
    }
    return n;
  }

  Node _primary() {
    final tok = peek;
    if (tok == null) throw const ExprException(ExprErrorKind.syntax);
    i++;
    switch (tok) {
      case '(':
        final e = _expr();
        _expect(')');
        return Wrapped('(', e);
      case '|':
        final e = _expr();
        _expect('|');
        return Wrapped('|', e);
      case '⌊':
        final e = _expr();
        _expect('⌋');
        return Wrapped('⌊', e);
      case '⌈':
        final e = _expr();
        _expect('⌉');
        return Wrapped('⌈', e);
      case '√':
        return Root(2, _postfix());
      case '∛':
        return Root(3, _postfix());
      default:
        if (_isDigits(tok)) return Num(tok);
        throw const ExprException(ExprErrorKind.syntax);
    }
  }
}

// ---------------------------------------------------------------- API

/// Digitos adjacentes (sem simbolo entre eles) formam um numero maior: 5,2 -> 52.
List<String> mergeDigits(List<String> tokens) {
  final out = <String>[];
  for (final t in tokens) {
    if (_isDigits(t) && out.isNotEmpty && _isDigits(out.last)) {
      out[out.length - 1] = out.last + t;
    } else {
      out.add(t);
    }
  }
  return out;
}

/// Monta a sequencia completa: lacuna0 d1 lacuna1 d2 lacuna2 d3 lacuna3 d4 lacuna4.
List<String> tokensFor(int number, List<List<String>> gaps) {
  final d = number.toString().padLeft(4, '0').split('');
  return [
    for (var i = 0; i < 4; i++) ...[...gaps[i], d[i]],
    ...gaps[4],
  ];
}

class Equation {
  const Equation(this.left, this.right);
  final Node left, right;

  String latex() => '${left.latex()} = ${right.latex()}';

  static Equation parse(List<String> tokens) {
    final merged = mergeDigits(tokens);
    if (merged.where((t) => t == '=').length != 1) {
      throw const ExprException(ExprErrorKind.needEquals);
    }
    final k = merged.indexOf('=');
    return Equation(
      _Parser(merged.sublist(0, k)).parse(),
      _Parser(merged.sublist(k + 1)).parse(),
    );
  }
}

class CheckOutcome {
  const CheckOutcome({this.correct = false, this.left, this.right, this.error});
  final bool correct;
  final double? left, right;
  final ExprException? error;
}

CheckOutcome checkEquation(List<String> tokens, Level level) {
  try {
    for (final t in tokens) {
      if (!_isDigits(t) && t != '=' && !level.allowed.contains(t)) {
        throw const ExprException(ExprErrorKind.syntax);
      }
    }
    final eq = Equation.parse(tokens);
    final l = eq.left.eval(level.allowFractions);
    final r = eq.right.eval(level.allowFractions);
    final ok = (l - r).abs() <= _eps * math.max(1.0, math.max(l.abs(), r.abs()));
    return CheckOutcome(correct: ok, left: l, right: r);
  } on ExprException catch (e) {
    return CheckOutcome(error: e);
  }
}

/// LaTeX da equacao. Se ainda estiver incompleta/invalida, cai num mapeamento simbolo a simbolo.
String previewLatex(List<String> tokens) {
  try {
    return Equation.parse(tokens).latex();
  } on ExprException {
    return mergeDigits(tokens).map(_rawLatex).join(' ');
  }
}

String _rawLatex(String s) => switch (s) {
      '*' => r'\times',
      '/' => r'\div',
      '**' => r'\ast\ast',
      '√' => r'\surd',
      '∛' => r'\sqrt[3]{\phantom{0}}',
      '⌊' => r'\lfloor',
      '⌋' => r'\rfloor',
      '⌈' => r'\lceil',
      '⌉' => r'\rceil',
      '|' => r'\vert',
      _ => s,
    };
