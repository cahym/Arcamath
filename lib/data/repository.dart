import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../game/level.dart';

class AllSolvedException implements Exception {
  const AllSolvedException();
}

class RankEntry {
  const RankEntry({required this.uid, required this.name, required this.score, required this.solved});
  final String uid, name;
  final int score, solved;
}

/// Estrutura no Firestore:
///   users/{uid}                -> displayName, score, solvedCount, updatedAt
///   users/{uid}/solved/{level}_{number} -> number, level, expression, points, solvedAt
class GameRepository {
  GameRepository(this._db, this._auth);
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final _rng = Random();

  User get _user {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Not signed in');
    return u;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc => _db.collection('users').doc(_user.uid);

  Stream<Map<String, dynamic>?> watchUser() => _userDoc.snapshots().map((s) => s.data());

  /// Numeros resolvidos nesta sessao (garante que nao reaparecem mesmo se o Firestore demorar a confirmar).
  final Map<String, Set<int>> _localSolved = {};
  String _key(Level l) => '${_user.uid}_${l.name}';

  Future<Set<int>> solvedNumbers(Level level) async {
    var remote = <int>{};
    try {
      final snap = await _userDoc.collection('solved').where('level', isEqualTo: level.name).get();
      remote = {for (final d in snap.docs) (d.data()['number'] as num).toInt()};
    } catch (e) {
      debugPrint('Arcamath: nao foi possivel ler os resolvidos ($e); usando apenas os da sessao');
    }
    return {...remote, ...?_localSolved[_key(level)]};
  }

  /// Sorteia um numero de 4 digitos que o usuario ainda NAO resolveu neste nivel.
  /// [accept] (opcional) permite recusar candidatos, ex.: numeros sem solucao.
  Future<int> pickUnsolved(Level level, {int? exclude, Future<bool> Function(int)? accept}) async {
    final solved = await solvedNumbers(level);
    for (var i = 0; i < 80; i++) {
      final n = 1000 + _rng.nextInt(9000);
      if (solved.contains(n) || n == exclude) continue;
      if (accept == null || await accept(n)) return n;
    }
    for (var n = 1000; n <= 9999; n++) {
      if (!solved.contains(n) && n != exclude) return n;
    }
    throw const AllSolvedException();
  }

  /// Grava o numero resolvido + pontuacao num unico batch. O Firestore aplica a escrita no cache local
  /// na hora (HUD atualiza); o Future retornado so completa quando o SERVIDOR confirma, entao
  /// o jogo NAO deve ficar esperando por ele.
  Future<void> saveSolved({
    required int number,
    required Level level,
    required String expression,
    required int points,
  }) {
    final u = _user;
    _localSolved.putIfAbsent(_key(level), () => {}).add(number);
    final userRef = _db.collection('users').doc(u.uid);
    final batch = _db.batch();
    batch.set(userRef.collection('solved').doc('${level.name}_$number'), {
      'number': number,
      'level': level.name,
      'expression': expression,
      'points': points,
      'solvedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      userRef,
      {
        'displayName': u.displayName ?? u.email?.split('@').first ?? 'Player',
        'score': FieldValue.increment(points),
        'solvedCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return batch.commit();
  }

  Future<List<RankEntry>> topPlayers({int limit = 20}) async {
    final snap = await _db.collection('users').orderBy('score', descending: true).limit(limit).get();
    return [
      for (final d in snap.docs)
        RankEntry(
          uid: d.id,
          name: (d.data()['displayName'] as String?) ?? '???',
          score: (d.data()['score'] as num?)?.toInt() ?? 0,
          solved: (d.data()['solvedCount'] as num?)?.toInt() ?? 0,
        ),
    ];
  }
}
