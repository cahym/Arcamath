import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Arcamath'**
  String get appTitle;

  /// No description provided for @insertCoin.
  ///
  /// In en, this message translates to:
  /// **'INSERT COIN'**
  String get insertCoin;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to play'**
  String get loginSubtitle;

  /// No description provided for @madeBy.
  ///
  /// In en, this message translates to:
  /// **'Made by {names}'**
  String madeBy(String names);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @navGame.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navGame;

  /// No description provided for @navRanking.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame'**
  String get navRanking;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get navHelp;

  /// No description provided for @levelEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get levelEasy;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @levelHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get levelHard;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @solvedCount.
  ///
  /// In en, this message translates to:
  /// **'Solved: {count}'**
  String solvedCount(int count);

  /// No description provided for @latexTitle.
  ///
  /// In en, this message translates to:
  /// **'LaTeX preview'**
  String get latexTitle;

  /// No description provided for @trayTitle.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get trayTitle;

  /// No description provided for @trayHint.
  ///
  /// In en, this message translates to:
  /// **'Click a slot, then a symbol, or drag symbols into a slot. Keyboard: type the symbols (^ for **, R for √, C for ∛), arrows pick the slot, Backspace deletes, Enter checks, H hint, S skip.'**
  String get trayHint;

  /// No description provided for @backspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last symbol'**
  String get backspace;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'CHECK'**
  String get check;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get skip;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clear;

  /// No description provided for @verdictCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct! +{points} points'**
  String verdictCorrect(int points);

  /// No description provided for @verdictWrong.
  ///
  /// In en, this message translates to:
  /// **'Not yet: {left} ≠ {right}'**
  String verdictWrong(String left, String right);

  /// No description provided for @errSyntax.
  ///
  /// In en, this message translates to:
  /// **'That expression is not valid.'**
  String get errSyntax;

  /// No description provided for @errNeedEquals.
  ///
  /// In en, this message translates to:
  /// **'Use exactly one = sign.'**
  String get errNeedEquals;

  /// No description provided for @errDivZero.
  ///
  /// In en, this message translates to:
  /// **'Division by zero.'**
  String get errDivZero;

  /// No description provided for @errNonIntDiv.
  ///
  /// In en, this message translates to:
  /// **'This level only allows exact integer divisions.'**
  String get errNonIntDiv;

  /// No description provided for @errFactorial.
  ///
  /// In en, this message translates to:
  /// **'Factorial needs a whole number from 0 to 20.'**
  String get errFactorial;

  /// No description provided for @errDomain.
  ///
  /// In en, this message translates to:
  /// **'Invalid operation, such as the root of a negative number.'**
  String get errDomain;

  /// No description provided for @errOverflow.
  ///
  /// In en, this message translates to:
  /// **'The number got too big.'**
  String get errOverflow;

  /// No description provided for @errSave.
  ///
  /// In en, this message translates to:
  /// **'Correct, but saving your progress failed.'**
  String get errSave;

  /// No description provided for @allSolved.
  ///
  /// In en, this message translates to:
  /// **'You solved every number at this level! Try another level.'**
  String get allSolved;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load data: {error}'**
  String loadError(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get retry;

  /// No description provided for @rankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame'**
  String get rankingTitle;

  /// No description provided for @rankingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody has scored yet. Be the first!'**
  String get rankingEmpty;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get you;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSize;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get fontFamily;

  /// No description provided for @seedColor.
  ///
  /// In en, this message translates to:
  /// **'Theme color'**
  String get seedColor;

  /// No description provided for @customColor.
  ///
  /// In en, this message translates to:
  /// **'Custom color'**
  String get customColor;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @soundHint.
  ///
  /// In en, this message translates to:
  /// **'Sound effects (off by default)'**
  String get soundHint;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'SIGN OUT'**
  String get signOut;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to play'**
  String get helpTitle;

  /// No description provided for @helpBody.
  ///
  /// In en, this message translates to:
  /// **'Each round shows a 4-digit number. Keep the digits in order and fill the slots under the spaces between them with symbols so that both sides of the = sign have the same value.\n\nExample: 5261 becomes (5 − 2)! = 6 × 1.\n\nClick a slot, then click symbols (or drag them in). Click a placed symbol to remove it. Digits with nothing between them join into a bigger number.\n\nLevels: Easy allows fractions, ⌊x⌋ and ⌈x⌉. All other levels only allow exact integer divisions. Intermediate drops ⌊ ⌋ ⌈ ⌉, Advanced also drops ∛ and **, and Hard also drops √ and !.\n\nHints (the 3 hearts): 1 shows where the = goes, 2 shows which symbols are used, 3 fills in the solution. Using 1 or 2 hints halves the points; revealing the solution gives 0.\n\nKeyboard: type + - * / ( ) | ! = , ^ for **, R for √, C for ∛, arrows pick a slot, Backspace deletes, Esc clears, Enter checks, H hint, S skip.\n\nToo hard? Press SKIP to get another number.'**
  String get helpBody;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get close;

  /// No description provided for @pressStart.
  ///
  /// In en, this message translates to:
  /// **'PRESS START'**
  String get pressStart;

  /// No description provided for @areYouReady.
  ///
  /// In en, this message translates to:
  /// **'ARE YOU READY?'**
  String get areYouReady;

  /// No description provided for @highScore.
  ///
  /// In en, this message translates to:
  /// **'HIGH SCORE'**
  String get highScore;

  /// No description provided for @hint.
  ///
  /// In en, this message translates to:
  /// **'HINT'**
  String get hint;

  /// No description provided for @hintEquals.
  ///
  /// In en, this message translates to:
  /// **'Hint 1: the = sign goes after digit number {n}.'**
  String hintEquals(int n);

  /// No description provided for @hintSymbols.
  ///
  /// In en, this message translates to:
  /// **'Hint 2: the solution uses {symbols}'**
  String hintSymbols(String symbols);

  /// No description provided for @hintReveal.
  ///
  /// In en, this message translates to:
  /// **'Hint 3: the full solution is on the board. This round is worth 0 points.'**
  String get hintReveal;

  /// No description provided for @hintNone.
  ///
  /// In en, this message translates to:
  /// **'No solution found for this number. Press SKIP.'**
  String get hintNone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
