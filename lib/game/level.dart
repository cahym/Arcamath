/// Niveis de dificuldade e operadores permitidos em cada um.
enum Level { easy, intermediate, advanced, hard }

const _base = {'+', '-', '*', '/', '(', ')', '|'};

/// Ordem de exibicao dos simbolos na bandeja.
const kTokenOrder = ['(', ')', '|', '+', '-', '*', '/', '**', '√', '∛', '!', '⌊', '⌋', '⌈', '⌉'];

extension LevelX on Level {
  /// Simbolos permitidos (sem o "=", que existe em todos os niveis).
  Set<String> get allowed => switch (this) {
        Level.easy => {..._base, '√', '∛', '!', '**', '⌊', '⌋', '⌈', '⌉'},
        Level.intermediate => {..._base, '√', '∛', '!', '**'},
        Level.advanced => {..._base, '√', '!'},
        Level.hard => _base,
      };

  /// Simbolos mostrados na bandeja, incluindo o "=".
  List<String> get tray => [...kTokenOrder.where(allowed.contains), '='];

  /// So o nivel facil aceita divisao nao inteira (5/2).
  bool get allowFractions => this == Level.easy;

  int get points => switch (this) {
        Level.easy => 10,
        Level.intermediate => 20,
        Level.advanced => 40,
        Level.hard => 80,
      };
}

/// Rotulo visual de cada simbolo.
String tokenLabel(String t) => switch (t) {
      '*' => '×',
      '/' => '÷',
      '-' => '−',
      _ => t,
    };
