import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/club.dart';
import '../models/npc.dart';
import '../services/club_service.dart';
import '../services/ranking_service.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/stepn_button.dart';

/// ランキング(青→紫グラデ背景・表彰台+リスト)。
/// データはローカルの自分の記録+架空プレイヤー(シード固定)。
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

/// 上部セグメント(個人 / クラブ)。
enum _RankTab { personal, club }

class _RankingScreenState extends State<RankingScreen> {
  RankPeriod _period = RankPeriod.week;
  _RankTab _tab = _RankTab.personal;
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
            // 個人 / クラブ の切替
            _Segment<_RankTab>(
              value: _tab,
              options: const [
                (_RankTab.personal, S.segPersonal),
                (_RankTab.club, S.segClub),
              ],
              onChanged: (v) => setState(() => _tab = v),
            ),
            const SizedBox(height: 10),
            if (_tab == _RankTab.personal)
              ..._buildPersonal(state)
            else
              Expanded(child: _ClubView(state: state)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPersonal(AppState state) {
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

    return [
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
    ];
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

/// 汎用セグメント切替(丸ピル・白背景が選択中)。
class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            for (final (option, label) in options)
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(option),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: value == option ? RS.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                      border: value == option
                          ? Border.all(color: RS.ink, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: RS.label(
                            size: 14,
                            color: value == option ? RS.ink : RS.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// クラブ対抗戦タブ。未加入ならクラブ選択、加入済みなら今週の対戦カード。
class _ClubView extends StatelessWidget {
  const _ClubView({required this.state});

  final AppState state;

  /// クラブのテーマカラー(colorIndex で引く)。
  static const _clubColors = [
    RS.orange,
    RS.purpleDeep,
    RS.mintDark,
    RS.blue,
  ];

  static Color colorOf(Club club) =>
      _clubColors[club.colorIndex % _clubColors.length];

  @override
  Widget build(BuildContext context) {
    final mine = state.myClub;
    if (mine == null) return _ClubPicker(state: state);
    return _ClubBattle(state: state, mine: mine);
  }
}

/// 未加入時のクラブ選択(4枚のカード)。
class _ClubPicker extends StatelessWidget {
  const _ClubPicker({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 130),
      children: [
        Text(S.clubJoinTitle,
            textAlign: TextAlign.center, style: RS.label(size: 18, color: RS.white)),
        const SizedBox(height: 4),
        Text(S.clubJoinLead,
            textAlign: TextAlign.center,
            style: RS.body(size: 12, color: RS.white)),
        const SizedBox(height: 14),
        for (final club in allClubs) ...[
          StepnCard(
            radius: 22,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _ClubView.colorOf(club),
                        shape: BoxShape.circle,
                        border: Border.all(color: RS.ink, width: 1.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(club.name, style: RS.label(size: 16))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(club.motto, style: RS.body(size: 12, color: RS.grey)),
                const SizedBox(height: 8),
                Text('${S.clubMembers}: ${club.memberNames.join(' / ')}',
                    style: RS.body(size: 11, color: RS.grey)),
                const SizedBox(height: 12),
                StepnButton(
                  label: S.clubJoin,
                  fontSize: 14,
                  color: _ClubView.colorOf(club),
                  onTap: () => state.joinClub(club.id),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Center(
          child: Text(S.clubNote, style: RS.body(size: 11, color: RS.white)),
        ),
      ],
    );
  }
}

/// 加入済み: 今週の対戦カード + 前週結果バナー。
class _ClubBattle extends StatelessWidget {
  const _ClubBattle({required this.state, required this.mine});

  final AppState state;
  final Club mine;

  String _km(double v) => '${v.toStringAsFixed(1)} km';

  @override
  Widget build(BuildContext context) {
    final service = state.club;
    final now = DateTime.now().toUtc();
    final weekStart = service.weekStartFor(now);
    final activeDays = service.activeDaysFor(now);
    final elapsed = service.elapsedDaysFor(now);
    final opponent = service.pickOpponent(service.weekKeyFor(now), mine.id);

    final myTotal =
        service.clubNpcKm(mine, weekStart, activeDays) + state.clubMyKm;
    // 頭数補正(自分側5名 vs 相手4名)は決算と同じ 5/4
    final oppTotal = service.clubNpcKm(opponent, weekStart, activeDays) * 5 / 4;
    final share = myTotal + oppTotal <= 0 ? 0.5 : myTotal / (myTotal + oppTotal);

    final result = state.lastClubResult;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 130),
      children: [
        if (result != null) ...[
          _ResultBanner(result: result, onTap: state.consumeClubResult),
          const SizedBox(height: 12),
        ],
        StepnCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(S.clubThisWeek, style: RS.label(size: 13, color: RS.grey)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ClubSide(
                        club: mine, km: myTotal, kmLabel: _km(myTotal)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(S.clubVs, style: RS.number(size: 18)),
                  ),
                  Expanded(
                    child: _ClubSide(
                        club: opponent,
                        km: oppTotal,
                        kmLabel: _km(oppTotal),
                        alignEnd: true),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 勢力バー(左=自クラブ・右=相手)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    border: Border.all(color: RS.ink, width: 2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (share * 1000).round().clamp(1, 999),
                        child: Container(color: _ClubView.colorOf(mine)),
                      ),
                      Expanded(
                        flex: ((1 - share) * 1000).round().clamp(1, 999),
                        child: Container(color: _ClubView.colorOf(opponent)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${S.clubDayElapsed} $elapsed${S.clubDayUnit}',
                      style: RS.body(size: 12, color: RS.grey)),
                  Text(
                      '${S.clubDayLeft} ${ClubService.daysPerWeek - activeDays}${S.clubDayUnit}',
                      style: RS.body(size: 12, color: RS.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StepnCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(S.clubMyContribution,
                          style: RS.label(size: 14))),
                  Text(_km(state.clubMyKm), style: RS.number(size: 20)),
                ],
              ),
              const Divider(height: 22),
              Text(S.clubMemberKm, style: RS.label(size: 13, color: RS.grey)),
              const SizedBox(height: 8),
              for (final bot in mine.memberBotIndices)
                _MemberRow(
                  name: npcNames[bot],
                  km: _km(service.npcWeekKm(bot, weekStart, activeDays)),
                ),
              _MemberRow(
                  name: state.userName, km: _km(state.clubMyKm), isMe: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(S.clubNote, style: RS.body(size: 11, color: RS.white)),
        ),
      ],
    );
  }
}

class _ClubSide extends StatelessWidget {
  const _ClubSide({
    required this.club,
    required this.km,
    required this.kmLabel,
    this.alignEnd = false,
  });

  final Club club;
  final double km;
  final String kmLabel;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        PillBadge(
          text: club.name,
          color: _ClubView.colorOf(club),
          textColor: RS.white,
          fontSize: 11,
        ),
        const SizedBox(height: 6),
        Text(kmLabel, style: RS.number(size: 22)),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.name, required this.km, this.isMe = false});

  final String name;
  final String km;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(isMe ? Icons.directions_run : Icons.person,
              size: 16, color: isMe ? RS.ink : RS.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                overflow: TextOverflow.ellipsis,
                style: RS.label(size: 13, color: isMe ? RS.ink : RS.grey)),
          ),
          Text(km, style: RS.label(size: 13)),
        ],
      ),
    );
  }
}

/// 前週の決算バナー(タップで消化)。
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result, required this.onTap});

  final ClubWeekResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = result.won ? RS.mintDark : RS.grey;
    return GestureDetector(
      onTap: onTap,
      child: StepnCard(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(result.won ? Icons.emoji_events : Icons.flag,
                    color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      result.won ? S.clubResultWin : S.clubResultLose,
                      style: RS.label(size: 15)),
                ),
                Text(S.clubResultTapToClose,
                    style: RS.body(size: 10, color: RS.grey)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${result.myClubName} ${result.myTotal.toStringAsFixed(1)} km '
              '${S.clubVs} '
              '${result.opponentName} ${result.oppTotal.toStringAsFixed(1)} km',
              style: RS.body(size: 12, color: RS.grey),
            ),
            const SizedBox(height: 6),
            Text(
              '+ ${result.rewardSp.toStringAsFixed(0)} SP'
              '${result.rewardBoxes > 0 ? ' / ${S.clubRewardBox} x${result.rewardBoxes}' : ''}',
              style: RS.number(size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
