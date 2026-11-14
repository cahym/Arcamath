import 'package:arcamath/l10n/app_localizations.dart';

import 'expression.dart';
import 'game_controller.dart';
import 'level.dart';

String levelName(AppLocalizations l, Level lv) => switch (lv) {
      Level.easy => l.levelEasy,
      Level.intermediate => l.levelIntermediate,
      Level.advanced => l.levelAdvanced,
      Level.hard => l.levelHard,
    };

String fmtNum(double v) => (v - v.roundToDouble()).abs() < 1e-9 ? v.round().toString() : v.toStringAsFixed(3);

String verdictText(AppLocalizations l, Verdict v) => switch (v.kind) {
      VerdictKind.correct => l.verdictCorrect(v.points),
      VerdictKind.wrong => l.verdictWrong(fmtNum(v.left!), fmtNum(v.right!)),
      VerdictKind.saveFailed => l.errSave,
      VerdictKind.error => switch (v.error!) {
          ExprErrorKind.syntax => l.errSyntax,
          ExprErrorKind.needEquals => l.errNeedEquals,
          ExprErrorKind.divZero => l.errDivZero,
          ExprErrorKind.nonIntegerDivision => l.errNonIntDiv,
          ExprErrorKind.factorial => l.errFactorial,
          ExprErrorKind.domain => l.errDomain,
          ExprErrorKind.overflow => l.errOverflow,
        },
    };
