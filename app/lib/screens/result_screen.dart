import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/gem.dart';
import '../models/move_session.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/gem_art.dart';
import '../widgets/graffiti_background.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';

/// リザルト画面(シェアカード風レイアウト)。
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.session});

  final MoveSession session;

  String _fmtTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} '
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shoe = state.selectedShoe;

    return Scaffold(
      backgroundColor: RS.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 上部ラベンダーカード
          Container(
            decoration: const BoxDecoration(
              color: RS.lavender,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ユーザー行+SP/分
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: RS.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: RS.ink, width: 2),
                        ),
                        child: const Icon(Icons.directions_run, size: 30),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.userName, style: RS.label(size: 16)),
                          Text(_fmtDate(session.startedAt),
                              style: RS.label(
                                  size: 12, color: RS.grey)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(session.pointsPerMinute.toStringAsFixed(1),
                              style: RS.number(size: 44)),
                          Text('${session.mode.code}${S.perMin}',
                              style:
                                  RS.label(size: 13, color: RS.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // シューズカード(4隅ソケット)
                      if (shoe != null)
                        Expanded(
                          flex: 5,
                          child: StepnCard(
                            radius: 24,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                PillBadge(
                                  text:
                                      '${shoe.type.label} Lv${shoe.level}',
                                  color: RS.purpleDeep,
                                  textColor: RS.white,
                                  fontSize: 12,
                                ),
                                const SizedBox(height: 6),
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: 150,
                                      child: Center(
                                        child: Container(
                                          width: 120,
                                          height: 120,
                                          decoration: BoxDecoration(
                                            color: RS.lavender
                                                .withValues(alpha: 0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                              child: SneakerArt(
                                                  shoe: shoe, size: 130)),
                                        ),
                                      ),
                                    ),
                                    for (var i = 0; i < 4; i++)
                                      Positioned(
                                        left: i.isEven ? 0 : null,
                                        right: i.isOdd ? 0 : null,
                                        top: i < 2 ? 0 : null,
                                        bottom: i >= 2 ? 0 : null,
                                        child: GemSocket(
                                          type: GemType.values[i],
                                          gem: state.equippedGemOf(
                                              shoe.id, GemType.values[i]),
                                          size: 36,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                PillBadge(
                                  text: shoe.serialLabel,
                                  color: RS.white,
                                  textColor: RS.purpleDeep,
                                  borderColor: RS.purpleDeep,
                                  fontSize: 11,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(width: 14),

                      // 右列: 判定・獲得・ボックス・エナジー
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  session.rejectedSamples == 0
                                      ? Icons.verified_user
                                      : Icons.gpp_maybe,
                                  color: session.rejectedSamples == 0
                                      ? const Color(0xFF2FBF6B)
                                      : RS.orange,
                                  size: 22,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  session.rejectedSamples == 0
                                      ? S.normalMeasure
                                      : S.suspicious,
                                  style: RS.label(size: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ResultLine(
                              icon: Icons.directions_walk,
                              text:
                                  '+ ${session.earnedPoints.toStringAsFixed(2)}',
                              size: 22,
                            ),
                            const SizedBox(height: 14),
                            _ResultLine(
                              icon: Icons.inventory_2,
                              text: 'x ${session.boxesObtained}',
                              size: 18,
                              note: session.boxesObtained == 0 &&
                                      state.boxes.length >= 4
                                  ? S.slotsFull
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            _ResultLine(
                              icon: Icons.bolt,
                              iconColor: RS.blue,
                              text:
                                  '- ${session.consumedEnergy.toStringAsFixed(1)}',
                              size: 20,
                            ),
                            const SizedBox(height: 14),
                            _ResultLine(
                              icon: Icons.build,
                              iconColor: RS.grey,
                              text:
                                  '- ${session.consumedDurability.toStringAsFixed(1)}',
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 中段: Km / Time / Steps
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BigStat(
                    value:
                        (session.distanceMeters / 1000).toStringAsFixed(2),
                    label: S.km),
                _BigStat(
                    value: _fmtTime(session.durationSeconds), label: S.time),
                _BigStat(
                    value: '${session.estimatedSteps}', label: S.steps),
              ],
            ),
          ),

          // 装飾ルートイラスト
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AspectRatio(
              aspectRatio: 1.55,
              child: const RouteArt(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            child: StepnButton(
              label: S.backToHome,
              fontSize: 18,
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({
    required this.icon,
    required this.text,
    required this.size,
    this.iconColor = RS.ink,
    this.note,
  });

  final IconData icon;
  final String text;
  final double size;
  final Color iconColor;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: iconColor, width: 2),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Text(text, style: RS.number(size: size)),
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child:
                Text(note!, style: RS.label(size: 11, color: RS.red)),
          ),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: RS.number(size: 30)),
        const SizedBox(height: 2),
        Text(label, style: RS.label(size: 13, color: RS.grey)),
      ],
    );
  }
}
