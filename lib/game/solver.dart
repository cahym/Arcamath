import 'dart:math' as math;

import 'expression.dart';
import 'level.dart';

/// Solucao de um numero: as 5 lacunas ja preenchidas (inclui o "=").
class Solution {
  const Solution({required this.gaps, required this.leftDigits});
  final List<List<String>> gaps;

  /// Quantos digitos ficam antes do "=" (1, 2 ou 3).
  final int leftDigits;

  /// Simbolos distintos usados (sem o "="), na ordem da bandeja.
  List<String> get symbols {
    final used = {for (final g in gaps) ...g}..remove('=');
    final order = [...kTokenOrder];
    return used.toList()..sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
  }
}

final Map<String, Solution?> _cache = {};

/// Busca (rapida, com cache) uma equacao valida para [number] no [level]. Null se nao achar.
Solution? solveEquation(int number, Level level) {
  final key = '${level.index}:$number';
  if (_cache.containsKey(key)) return _cache[key];
  final digits = number.toString().padLeft(4, '0').split('').map(int.parse).toList();
  final solver = _Solver(digits, level, number);
  Solution? res;
  // 2|2 primeiro: conjuntos pequenos, resolve a maioria dos casos quase instantaneamente.
  for (final m in const [2, 1, 3]) {
    res = solver.find(m);
    if (res != null) break;
  }
  return _cache[key] = res;
}

/// Versao assincrona: cede ao event loop antes de calcular para a UI nao travar.
Future<Solution?> solveEquationAsync(int number, Level level) async {
  await Future<void>.delayed(Duration.zero);
  return solveEquation(number, level);
}

// ------------------------------------------------------------------ interno

// "Niveis" de precedencia de um candidato (decidem onde sao necessarios parenteses).
const _sum = 0, _prod = 1, _neg = 2, _pow = 3, _root = 4, _atom = 5;
const _cap = 1e9;

class _C {
  _C(this.v, this.lv, this.t);
  final double v;
  final int lv;
  final List<String> t;
  int get len => t.length;
}

bool _near(double r) => (r - r.roundToDouble()).abs() < 1e-9 * math.max(1.0, r.abs());
int _x(_C c, int min) => c.lv < min ? 2 : 0;
List<String> _pt(_C c, int min) => c.lv < min ? ['(', ...c.t, ')'] : c.t;

double _fact(int n) {
  var r = 1.0;
  for (var i = 2; i <= n; i++) {
    r *= i;
  }
  return r;
}

double _cbrt(double v) => v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

/// Insere mantendo, para cada valor, a expressao mais curta. Devolve o novo candidato (ou null).
_C? _put(Map<int, _C> m, double v, int lv, int len, List<String> Function() build) {
  if (v.isNaN || v.isInfinite || v.abs() > _cap) return null;
  final k = (v * 1e6).round();
  final old = m[k];
  if (old != null && old.len <= len) return null;
  return m[k] = _C(v, lv, build());
}

class _Solver {
  _Solver(this.d, this.level, this.number);
  final List<int> d;
  final Level level;
  final int number;
  final Map<int, Map<int, _C>> _memo = {};

  /// Todos os valores alcancaveis usando os digitos i..j (em ordem), com a expressao mais curta.
  Map<int, _C> set(int i, int j) => _memo[i * 4 + j] ??= _build(i, j);

  Map<int, _C> _build(int i, int j) {
    final m = <int, _C>{};
    if (i == j || d[i] != 0) {
      var v = 0.0;
      final t = <String>[];
      for (var k = i; k <= j; k++) {
        v = v * 10 + d[k];
        t.add('${d[k]}');
      }
      _put(m, v, _atom, t.length, () => t);
    }
    for (var k = i; k < j; k++) {
      final a = set(i, k).values.toList();
      final b = set(k + 1, j).values.toList();
      for (final x in a) {
        if (x.lv == _neg) continue; // (-a)+b etc. sao redundantes com as outras combinacoes
        for (final y in b) {
          if (y.lv == _neg) continue;
          _binary(m, x, y);
        }
      }
    }
    _closure(m);
    return m;
  }

  void _binary(Map<int, _C> m, _C a, _C b) {
    _put(m, a.v + b.v, _sum, a.len + b.len + 1 + _x(a, _sum) + _x(b, _prod),
        () => [..._pt(a, _sum), '+', ..._pt(b, _prod)]);
    _put(m, a.v - b.v, _sum, a.len + b.len + 1 + _x(a, _sum) + _x(b, _prod),
        () => [..._pt(a, _sum), '-', ..._pt(b, _prod)]);
    final lenP = a.len + b.len + 1 + _x(a, _prod) + _x(b, _neg);
    _put(m, a.v * b.v, _prod, lenP, () => [..._pt(a, _prod), '*', ..._pt(b, _neg)]);
    if (b.v.abs() > 1e-9) {
      final r = a.v / b.v;
      if (level.allowFractions) {
        _put(m, r, _prod, lenP, () => [..._pt(a, _prod), '/', ..._pt(b, _neg)]);
      } else if (_near(r)) {
        _put(m, r.roundToDouble(), _prod, lenP, () => [..._pt(a, _prod), '/', ..._pt(b, _neg)]);
      }
    }
    if ((level == Level.easy || level == Level.intermediate) && _near(b.v) && b.v >= 0 && b.v <= 10) {
      final lenW = a.len + b.len + 1 + _x(a, _root) + _x(b, _neg);
      _put(m, math.pow(a.v, b.v).toDouble(), _pow, lenW, () => [..._pt(a, _root), '**', ..._pt(b, _neg)]);
    }
  }

  void _unary(Map<int, _C> m, _C c, List<_C> fresh) {
    void put(double v, int lv, int len, List<String> Function() b) {
      final n = _put(m, v, lv, len, b);
      if (n != null) fresh.add(n);
    }

    final v = c.v;
    if (v != 0 && c.lv != _neg) {
      put(-v, _neg, c.len + 1 + _x(c, _neg), () => ['-', ..._pt(c, _neg)]);
    }
    if (v < 0) put(-v, _atom, c.len + 2, () => ['|', ...c.t, '|']);
    if (level != Level.hard) {
      if (v > 1) {
        final r = math.sqrt(v).roundToDouble();
        if ((r * r - v).abs() < 1e-9) {
          put(r, _root, c.len + 1 + _x(c, _atom), () => ['√', ..._pt(c, _atom)]);
        }
      }
      if (_near(v) && (v.abs() < 1e-9 || (v >= 3 && v <= 12))) {
        put(_fact(v.round()), _atom, c.len + 1 + _x(c, _atom), () => [..._pt(c, _atom), '!']);
      }
    }
    if ((level == Level.easy || level == Level.intermediate) && v.abs() > 1) {
      final r = _cbrt(v).roundToDouble();
      if ((r * r * r - v).abs() < 1e-9) {
        put(r, _root, c.len + 1 + _x(c, _atom), () => ['∛', ..._pt(c, _atom)]);
      }
    }
    if (level == Level.easy && !_near(v)) {
      put((v + 1e-9).floorToDouble(), _atom, c.len + 2, () => ['⌊', ...c.t, '⌋']);
      put((v - 1e-9).ceilToDouble(), _atom, c.len + 2, () => ['⌈', ...c.t, '⌉']);
    }
  }

  void _closure(Map<int, _C> m) {
    var layer = m.values.toList();
    for (var r = 0; r < 2 && layer.isNotEmpty; r++) {
      final fresh = <_C>[];
      for (final c in layer) {
        _unary(m, c, fresh);
      }
      layer = fresh;
    }
  }

  /// Procura equacao com [m] digitos antes do "=" (meet-in-the-middle: valores iguais dos dois lados).
  Solution? find(int m) {
    final l = set(0, m - 1);
    final r = set(m, 3);
    Solution? best;
    var bestLen = 1 << 30;
    for (final e in l.entries) {
      final o = r[e.key];
      if (o == null) continue;
      final len = e.value.len + o.len;
      if (len >= bestLen) continue;
      final gaps = _toGaps([...e.value.t, '=', ...o.t]);
      if (checkEquation(tokensFor(number, gaps), level).correct) {
        best = Solution(gaps: gaps, leftDigits: m);
        bestLen = len;
      }
    }
    return best;
  }

  List<List<String>> _toGaps(List<String> full) {
    final gaps = <List<String>>[[]];
    for (final t in full) {
      if (t.length == 1 && t.codeUnitAt(0) >= 48 && t.codeUnitAt(0) <= 57) {
        gaps.add([]);
      } else {
        gaps.last.add(t);
      }
    }
    return gaps;
  }
}
