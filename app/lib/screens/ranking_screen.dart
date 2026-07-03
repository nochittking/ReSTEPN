import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../services/ranking_service.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';

/// ランキング(青→紫グラデ背景・表彰台+リスト)。
/// データはローカルの自分の記録+架空プレイヤー(シード固定)。
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  RankPeriod _period = RankPeriod.week;
  final _service = RankingService();

  static const _avatarIcons = [
    Icons.pets,
    Icons.face,
    Icons.cruelty_free,
    Icons.emoji_nature,
    Icons.rocket_launch,
    Icons.catching_pokemon,
    Icons.sports_esports,
    Icons.cookie,
  ];

  IconData _avatar(int seed) => _avatarIcons[seed % _avatarIcons.length];

  String _fmtPts(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final left = s.length - 1 - i;
      if (left > 0 && left % 3 == 0) buf.write(',');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = _service.build(
      state.sessions,
      _period,
      myName: state.userName,
    );
    final top3 = entries.take(3).toList();
    final me = entries.firstWhere((e) => e.isMe);
    // 自分は最上段に固定表示するため、リスト本体からは除外する
    final rest =
        entries.skip(3).where((e) => !e.isMe).take(12).toList();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5FA8E9), Color(0xFF9F7BEA), Color(0xFFEFE9F7)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 期間切替
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    for (final (period, label) in [
                      (RankPeriod.week, S.week),
                      (RankPeriod.month, S.month),
                      (RankPeriod.allTime, S.allTime),
                    ].map((e) => e))
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _period = period),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _period == period
                                  ? RS.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: _period == period
                                  ? Border.all(color: RS.ink, width: 2)
                                  : null,
                            ),
                            child: Center(
                                child: Text(label,
                                    style: RS.label(
                                        size: 14,
                                        color: _period == period
                                            ? RS.ink
                                            : RS.white))),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 表彰台トップ3(2位・1位・3位の順で表示)
            SizedBox(
              height: 190,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (top3.length > 1)
                    _PodiumCard(
                        entry: top3[1],
                        height: 160,
                        avatar: _avatar(top3[1].avatarSeed),
                        fmt: _fmtPts),
                  if (top3.isNotEmpty)
                    _PodiumCard(
                        entry: top3[0],
                        height: 190,
                        avatar: _avatar(top3[0].avatarSeed),
                        crowned: true,
                        fmt: _fmtPts),
                  if (top3.length > 2)
                    _PodiumCard(
                        entry: top3[2],
                        height: 150,
                        avatar: _avatar(top3[2].avatarSeed),
                        fmt: _fmtPts),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // リスト
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFCFE8F2).withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28)),
                  border: Border.all(color: RS.white, width: 2),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 130),
                  children: [
                    _RankRow(
                        entry: me, avatar: _avatar(me.avatarSeed), fmt: _fmtPts),
                    const Divider(),
                    for (final e in rest) ...[
                      _RankRow(
                          entry: e, avatar: _avatar(e.avatarSeed), fmt: _fmtPts),
                      if (e != rest.last) const Divider(),
                    ],
                    const SizedBox(height: 10),
                    Center(
                      child: Text(S.rankingNote,
                          style: RS.body(size: 11, color: RS.grey)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.height,
    required this.avatar,
    required this.fmt,
    this.crowned = false,
  });

  final RankEntry entry;
  final double height;
  final IconData avatar;
  final bool crowned;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: crowned ? 0.95 : 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: crowned ? RS.yellow : Colors.white,
          width: 2.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (crowned)
            const Icon(Icons.emoji_events, color: Color(0xFFDBA939), size: 20),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: RS.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: crowned ? RS.yellow : RS.grey, width: 2.5),
                ),
                child: Icon(avatar, size: 28, color: RS.ink),
              ),
              Positioned(
                bottom: -6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: crowned ? RS.yellow : const Color(0xFFC9A26B),
                      shape: BoxShape.circle,
                      border: Border.all(color: RS.white, width: 1.5),
                    ),
                    child: Center(
                        child: Text('${entry.rank}',
                            style: RS.label(size: 11))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.name,
              overflow: TextOverflow.ellipsis, style: RS.label(size: 12)),
          const SizedBox(height: 4),
          Text('${fmt(entry.points)} ${S.pts}', style: RS.label(size: 12.5)),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow(
      {required this.entry, required this.avatar, required this.fmt});

  final RankEntry entry;
  final IconData avatar;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text('${entry.rank}', style: RS.number(size: 20)),
                if (entry.isMe)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(
                      color: RS.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: RS.ink, width: 1.4),
                    ),
                    child: Text(S.me, style: RS.label(size: 9)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: RS.white,
              shape: BoxShape.circle,
              border: Border.all(color: RS.ink, width: 2),
            ),
            child: Icon(avatar, size: 24, color: RS.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.name,
                overflow: TextOverflow.ellipsis, style: RS.label(size: 15)),
          ),
          Text('${fmt(entry.points)} ${S.pts}', style: RS.label(size: 15)),
        ],
      ),
    );
  }
}
