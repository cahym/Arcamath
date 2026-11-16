import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../data/repository.dart';

/// Sobrescrito no main() com a instancia ja carregada.
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

// ------------------------------------------------------------ configuracoes

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.fontScale,
    required this.fontFamily,
    required this.seed,
    required this.soundOn,
    required this.musicOn,
    required this.locale,
  });
  final ThemeMode themeMode;
  final double fontScale;
  final String fontFamily;
  final Color seed;
  final bool soundOn;
  final bool musicOn;
  final Locale? locale;

  SettingsState copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    String? fontFamily,
    Color? seed,
    bool? soundOn,
    bool? musicOn,
    Locale? locale,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
        fontFamily: fontFamily ?? this.fontFamily,
        seed: seed ?? this.seed,
        soundOn: soundOn ?? this.soundOn,
        musicOn: musicOn ?? this.musicOn,
        locale: locale ?? this.locale,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  late SharedPreferences _p;

  @override
  SettingsState build() {
    _p = ref.watch(sharedPrefsProvider);
    final lc = _p.getString('locale');
    return SettingsState(
      // Inicialmente segue o tema do dispositivo (ThemeMode.system).
      themeMode: ThemeMode.values[(_p.getInt('themeMode') ?? 0).clamp(0, 2)],
      fontScale: _p.getDouble('fontScale') ?? 1.0,
      fontFamily: _p.getString('fontFamily') ?? kFontFamilies.first,
      seed: Color(_p.getInt('seed') ?? kSeedPresets.first.toARGB32()),
      soundOn: _p.getBool('sound') ?? false, // efeitos sonoros SEMPRE comecam desligados
      musicOn: _p.getBool('music') ?? false, // musica de fundo SEMPRE comeca desligada
      locale: lc == null ? null : Locale(lc),
    );
  }

  void setThemeMode(ThemeMode m) {
    state = state.copyWith(themeMode: m);
    _p.setInt('themeMode', m.index);
  }

  void setFontScale(double v) {
    state = state.copyWith(fontScale: v);
    _p.setDouble('fontScale', v);
  }

  void setFontFamily(String f) {
    state = state.copyWith(fontFamily: f);
    _p.setString('fontFamily', f);
  }

  void setSeed(Color c) {
    state = state.copyWith(seed: c);
    _p.setInt('seed', c.toARGB32());
  }

  void setSound(bool on) {
    state = state.copyWith(soundOn: on);
    _p.setBool('sound', on);
    if (on) ref.read(sfxProvider).play('coin.wav'); // confirma que o som esta ligado
  }

  void setMusic(bool on) {
    state = state.copyWith(musicOn: on);
    _p.setBool('music', on);
  }

  void setLocale(Locale l) {
    state = state.copyWith(locale: l);
    _p.setString('locale', l.languageCode);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

// ------------------------------------------------------------ som (opcional)

class Sfx {
  Sfx(this._enabled);
  final bool Function() _enabled;

  /// Toca um efeito (so se o som estiver ligado). Um player novo por efeito permite sons sobrepostos.
  Future<void> play(String file) async {
    if (!_enabled()) return;
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.first.then((_) => player.dispose()).catchError((_) {});
      await player.play(AssetSource('sfx/$file'), volume: .8);
    } catch (_) {/* audio bloqueado ou arquivo ausente: ignora */}
  }
}

final sfxProvider = Provider<Sfx>((ref) => Sfx(() => ref.read(settingsProvider).soundOn));

// ------------------------------------------------------------ musica de fundo (opcional)

/// Musica de fundo em loop. Tem a sua propria chave nas configuracoes, separada dos efeitos
/// sonoros (Sfx), e comeca desligada. Pausa quando o app vai para segundo plano.
class MusicPlayer with WidgetsBindingObserver {
  MusicPlayer(this._wanted) {
    WidgetsBinding.instance.addObserver(this);
  }
  final bool Function() _wanted;
  AudioPlayer? _player;
  bool _started = false;

  Future<void> setPlaying(bool on) async {
    try {
      if (!on) {
        await _player?.pause();
        return;
      }
      var p = _player;
      if (p == null) {
        p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setVolume(.35);
        _player = p;
      }
      if (_started) {
        await p.resume();
      } else {
        await p.play(AssetSource('music/theme.wav'));
        _started = true;
      }
    } catch (_) {/* audio bloqueado (ex.: autoplay do navegador) ou arquivo ausente: ignora */}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _player?.pause();
    } else if (state == AppLifecycleState.resumed && _wanted()) {
      setPlaying(true);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _player?.dispose();
  }
}

/// Mantem a musica em sincronia com a configuracao (observado pelo ArcamathApp).
final musicProvider = Provider<MusicPlayer>((ref) {
  final m = MusicPlayer(() => ref.read(settingsProvider).musicOn);
  ref.listen<bool>(settingsProvider.select((s) => s.musicOn), (_, on) => m.setPlaying(on));
  ref.onDispose(m.dispose);
  if (ref.read(settingsProvider).musicOn) m.setPlaying(true);
  return m;
});

// ------------------------------------------------------------ Firebase

final authUserProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

final repositoryProvider = Provider<GameRepository>(
  (ref) => GameRepository(FirebaseFirestore.instance, FirebaseAuth.instance),
);

/// Documento do usuario em tempo real (pontuacao e quantidade de resolvidos).
final userDocProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((ref) {
  final user = ref.watch(authUserProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(repositoryProvider).watchUser();
});
