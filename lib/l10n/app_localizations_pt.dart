// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Arcamath';

  @override
  String get insertCoin => 'INSIRA A FICHA';

  @override
  String get loginSubtitle => 'Entre com o Google para jogar';

  @override
  String madeBy(String names) {
    return 'Feito por $names';
  }

  @override
  String get language => 'Idioma';

  @override
  String get navGame => 'Jogar';

  @override
  String get navRanking => 'Hall da Fama';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navHelp => 'Ajuda';

  @override
  String get levelEasy => 'Fácil';

  @override
  String get levelIntermediate => 'Intermediário';

  @override
  String get levelAdvanced => 'Avançado';

  @override
  String get levelHard => 'Difícil';

  @override
  String get score => 'Pontos';

  @override
  String solvedCount(int count) {
    return 'Resolvidos: $count';
  }

  @override
  String get latexTitle => 'Prévia em LaTeX';

  @override
  String get trayTitle => 'Símbolos';

  @override
  String get trayHint =>
      'Clique numa lacuna e depois num símbolo, ou arraste os símbolos para uma lacuna. Teclado: digite os símbolos (^ para **, R para √, C para ∛), setas escolhem a lacuna, Backspace apaga, Enter verifica, H dica, S pula.';

  @override
  String get backspace => 'Apagar último símbolo';

  @override
  String get check => 'VERIFICAR';

  @override
  String get skip => 'PULAR';

  @override
  String get clear => 'LIMPAR';

  @override
  String verdictCorrect(int points) {
    return 'Correto! +$points pontos';
  }

  @override
  String verdictWrong(String left, String right) {
    return 'Ainda não: $left ≠ $right';
  }

  @override
  String get errSyntax => 'Essa expressão não é válida.';

  @override
  String get errNeedEquals => 'Use exatamente um sinal de =.';

  @override
  String get errDivZero => 'Divisão por zero.';

  @override
  String get errNonIntDiv => 'Este nível só permite divisões inteiras exatas.';

  @override
  String get errFactorial => 'O fatorial precisa de um inteiro de 0 a 20.';

  @override
  String get errDomain =>
      'Operação inválida, como a raiz de um número negativo.';

  @override
  String get errOverflow => 'O número ficou grande demais.';

  @override
  String get errSave => 'Correto, mas não foi possível salvar seu progresso.';

  @override
  String get allSolved =>
      'Você resolveu todos os números deste nível! Tente outro nível.';

  @override
  String loadError(String error) {
    return 'Não foi possível carregar os dados: $error';
  }

  @override
  String get retry => 'TENTAR DE NOVO';

  @override
  String get rankingTitle => 'Hall da Fama';

  @override
  String get rankingEmpty => 'Ninguém pontuou ainda. Seja o primeiro!';

  @override
  String get you => 'você';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get fontFamily => 'Fonte';

  @override
  String get seedColor => 'Cor do tema';

  @override
  String get customColor => 'Cor personalizada';

  @override
  String get sound => 'Som';

  @override
  String get soundHint => 'Efeitos sonoros (desligado por padrão)';

  @override
  String get account => 'Conta';

  @override
  String get signOut => 'SAIR';

  @override
  String get helpTitle => 'Como jogar';

  @override
  String get helpBody =>
      'Cada rodada mostra um número de 4 dígitos. Mantenha os dígitos na ordem e preencha as lacunas sob os espaços entre eles com símbolos para que os dois lados do sinal = tenham o mesmo valor.\n\nExemplo: 5261 vira (5 − 2)! = 6 × 1.\n\nClique numa lacuna e depois nos símbolos (ou arraste-os). Clique num símbolo colocado para removê-lo. Dígitos sem nada entre eles formam um número maior.\n\nNíveis: o Fácil permite frações, ⌊x⌋ e ⌈x⌉. Todos os outros só permitem divisões inteiras exatas. O Intermediário tira ⌊ ⌋ ⌈ ⌉, o Avançado tira também ∛ e **, e o Difícil tira também √ e !.\n\nDicas (os 3 corações): 1 mostra onde fica o =, 2 mostra quais símbolos são usados, 3 preenche a solução. Usar 1 ou 2 dicas divide os pontos pela metade; revelar a solução vale 0.\n\nTeclado: digite + - * / ( ) | ! = , ^ para **, R para √, C para ∛, setas escolhem a lacuna, Backspace apaga, Esc limpa, Enter verifica, H dica, S pula.\n\nMuito difícil? Aperte PULAR para ganhar outro número.';

  @override
  String get close => 'FECHAR';

  @override
  String get pressStart => 'APERTE START';

  @override
  String get areYouReady => 'VOCÊ ESTÁ PRONTO?';

  @override
  String get highScore => 'RECORDE';

  @override
  String get hint => 'DICA';

  @override
  String hintEquals(int n) {
    return 'Dica 1: o sinal = fica depois do dígito número $n.';
  }

  @override
  String hintSymbols(String symbols) {
    return 'Dica 2: a solução usa $symbols';
  }

  @override
  String get hintReveal =>
      'Dica 3: a solução completa está no tabuleiro. Esta rodada vale 0 pontos.';

  @override
  String get hintNone =>
      'Nenhuma solução encontrada para este número. Aperte PULAR.';
}
