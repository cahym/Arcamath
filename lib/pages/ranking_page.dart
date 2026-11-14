import 'package:arcamath/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repository.dart';
import '../state/providers.dart';
import '../widgets/arcade.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});
  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  late Future<List<RankEntry>> _future = ref.read(repositoryProvider).topPlayers();

  void _refresh() => setState(() => _future = ref.read(repositoryProvider).topPlayers());

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final me = FirebaseAuth.instance.currentUser?.uid;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ArcadePanel(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: Text(l.rankingTitle.toUpperCase(), style: arcadeStyle(context, size: 16))),
                  IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
                ]),
                const SizedBox(height: 16),
                FutureBuilder<List<RankEntry>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Padding(padding: EdgeInsets.all(32), child: ArcadeLoader());
                    }
                    if (snap.hasError) return Text(l.loadError(snap.error.toString()));
                    final rows = snap.data!;
                    if (rows.isEmpty) return Text(l.rankingEmpty, textAlign: TextAlign.center);
                    return Column(children: [
                      for (var i = 0; i < rows.length; i++)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: ShapeDecoration(
                            color: rows[i].uid == me ? cs.secondary.withValues(alpha: .2) : cs.surfaceContainerHigh,
                            shape: BeveledRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: i == 0 ? const Color(0xFFFFD700) : cs.outlineVariant,
                                width: i == 0 ? 3 : 1,
                              ),
                            ),
                          ),
                          child: Row(children: [
                            SizedBox(width: 44, child: Text('${i + 1}', style: arcadeStyle(context, size: 14, glow: 4))),
                            Expanded(
                              child: Text(
                                rows[i].uid == me ? '${rows[i].name} (${l.you})' : rows[i].name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('${rows[i].score}', style: arcadeStyle(context, size: 14, color: cs.secondary, glow: 4)),
                          ]),
                        ),
                    ]);
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
