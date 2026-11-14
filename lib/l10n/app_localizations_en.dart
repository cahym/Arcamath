// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Arcamath';

  @override
  String get insertCoin => 'INSERT COIN';

  @override
  String get loginSubtitle => 'Sign in with Google to play';

  @override
  String madeBy(String names) {
    return 'Made by $names';
  }

  @override
  String get language => 'Language';

  @override
  String get navGame => 'Play';

  @override
  String get navRanking => 'Hall of Fame';

  @override
  String get navSettings => 'Settings';

  @override
  String get navHelp => 'Help';

  @override
  String get levelEasy => 'Easy';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelHard => 'Hard';

  @override
  String get score => 'Score';

  @override
  String solvedCount(int count) {
    return 'Solved: $count';
  }

  @override
  String get latexTitle => 'LaTeX preview';

  @override
  String get trayTitle => 'Symbols';

  @override
  String get trayHint =>
      'Click a slot, then a symbol, or drag symbols into a slot. Keyboard: type the symbols (^ for **, R for √, C for ∛), arrows pick the slot, Backspace deletes, Enter checks, H hint, S skip.';

  @override
  String get backspace => 'Delete last symbol';

  @override
  String get check => 'CHECK';

  @override
  String get skip => 'SKIP';

  @override
  String get clear => 'CLEAR';

  @override
  String verdictCorrect(int points) {
    return 'Correct! +$points points';
  }

  @override
  String verdictWrong(String left, String right) {
    return 'Not yet: $left ≠ $right';
  }

  @override
  String get errSyntax => 'That expression is not valid.';

  @override
  String get errNeedEquals => 'Use exactly one = sign.';

  @override
  String get errDivZero => 'Division by zero.';

  @override
  String get errNonIntDiv => 'This level only allows exact integer divisions.';

  @override
  String get errFactorial => 'Factorial needs a whole number from 0 to 20.';

  @override
  String get errDomain =>
      'Invalid operation, such as the root of a negative number.';

  @override
  String get errOverflow => 'The number got too big.';

  @override
  String get errSave => 'Correct, but saving your progress failed.';

  @override
  String get allSolved =>
      'You solved every number at this level! Try another level.';

  @override
  String loadError(String error) {
    return 'Could not load data: $error';
  }

  @override
  String get retry => 'TRY AGAIN';

  @override
  String get rankingTitle => 'Hall of Fame';

  @override
  String get rankingEmpty => 'Nobody has scored yet. Be the first!';

  @override
  String get you => 'you';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontFamily => 'Font';

  @override
  String get seedColor => 'Theme color';

  @override
  String get customColor => 'Custom color';

  @override
  String get sound => 'Sound';

  @override
  String get soundHint => 'Sound effects (off by default)';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'SIGN OUT';

  @override
  String get helpTitle => 'How to play';

  @override
  String get helpBody =>
      'Each round shows a 4-digit number. Keep the digits in order and fill the slots under the spaces between them with symbols so that both sides of the = sign have the same value.\n\nExample: 5261 becomes (5 − 2)! = 6 × 1.\n\nClick a slot, then click symbols (or drag them in). Click a placed symbol to remove it. Digits with nothing between them join into a bigger number.\n\nLevels: Easy allows fractions, ⌊x⌋ and ⌈x⌉. All other levels only allow exact integer divisions. Intermediate drops ⌊ ⌋ ⌈ ⌉, Advanced also drops ∛ and **, and Hard also drops √ and !.\n\nHints (the 3 hearts): 1 shows where the = goes, 2 shows which symbols are used, 3 fills in the solution. Using 1 or 2 hints halves the points; revealing the solution gives 0.\n\nKeyboard: type + - * / ( ) | ! = , ^ for **, R for √, C for ∛, arrows pick a slot, Backspace deletes, Esc clears, Enter checks, H hint, S skip.\n\nToo hard? Press SKIP to get another number.';

  @override
  String get close => 'CLOSE';

  @override
  String get pressStart => 'PRESS START';

  @override
  String get areYouReady => 'ARE YOU READY?';

  @override
  String get highScore => 'HIGH SCORE';

  @override
  String get hint => 'HINT';

  @override
  String hintEquals(int n) {
    return 'Hint 1: the = sign goes after digit number $n.';
  }

  @override
  String hintSymbols(String symbols) {
    return 'Hint 2: the solution uses $symbols';
  }

  @override
  String get hintReveal =>
      'Hint 3: the full solution is on the board. This round is worth 0 points.';

  @override
  String get hintNone => 'No solution found for this number. Press SKIP.';
}
