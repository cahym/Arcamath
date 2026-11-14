# Arcamath

Jogo arcade de equações (engenharia reversa do Emplake) em Flutter + Firebase.

## Como montar o projeto
1. `flutter create --platforms=web,android arcamath` e copie estes arquivos por cima (pubspec.yaml, l10n.yaml, lib/, test/, assets/).
2. `flutter pub get` (se alguma versão falhar: `flutter pub upgrade --major-versions`).
3. Firebase (plano Spark): crie o projeto, ative **Authentication** (E-mail/Senha e Google) e **Firestore**; cole `firebase/firestore.rules` nas regras.
4. `dart pub global activate flutterfire_cli && flutterfire configure` (substitui `lib/firebase_options.dart`).
5. Em `lib/core/constants.dart`: coloque os nomes da dupla e o Client ID do Google.
6. `flutter gen-l10n` (gera `lib/l10n/app_localizations*.dart`, que entram na entrega dos .dart).
7. Coloque 3 sons em `assets/sfx/` (ver README.txt) ou ignore: o som é opcional e começa desligado.
8. `flutter test` e `flutter run -d chrome`.
9. Publicar: `flutter build web --release` e suba `build/web` no Netlify/Vercel/GitHub Pages; adicione o domínio em Authentication > Settings > Authorized domains.

## Mapa requisito -> arquivo
| Requisito | Onde |
|---|---|
| 4 níveis de operadores, divisão não inteira só no Fácil | `game/level.dart`, `game/expression.dart` |
| LaTeX abaixo da fórmula | `widgets/latex_preview.dart` (flutter_math_fork), usado em `pages/game_page.dart` |
| Interface única (cabine, lacunas, toque ou arraste) | `pages/game_page.dart` |
| Som opcional (padrão desligado) | `state/providers.dart` (Sfx), `pages/settings_page.dart` |
| Web | `flutter build web` |
| Login e-mail/Google (firebase_ui_auth) + nomes + idioma com bandeiras | `pages/login_page.dart`, `widgets/language_selector.dart` |
| Tudo traduzido (gen-l10n) | `lib/l10n/*.arb`, `l10n.yaml` |
| CurvedNavigationBar + configurações + ajuda | `pages/shell_page.dart`, `pages/settings_page.dart`, `widgets/help_dialog.dart` |
| Voltar à última página (SharedPreferences) | `router.dart` |
| Riverpod | `state/providers.dart`, `game/game_controller.dart` |
| go_router | `router.dart` |
| Animação | símbolos descem e somem ao acertar (`_Chip`), "INSERT COIN" piscante |
| Firestore + FutureBuilder + loader diferente | `data/repository.dart`, `pages/game_page.dart`, `pages/ranking_page.dart`, `ArcadeLoader` |
| Só números não resolvidos | `GameRepository.pickUnsolved` |
| Pular número | `GameNotifier.skip` |
| Responsivo | `LayoutBuilder` em `game_page.dart` (>= 900 px: duas colunas) |

## Decisões a confirmar com o professor
- Dígitos sem símbolo entre eles se juntam (5,2 -> 52).
- O "=" começa na lacuna do meio e pode ser movido (remova e coloque em outra lacuna).
- Pontos por nível: 10 / 20 / 40 / 80; um número resolvido em um nível pode reaparecer em outro.
- Nem todo número tem solução; por isso o botão "Pular".
