import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/game_config.dart';
import '../l10n/strings_ja.dart';
import '../models/move_session.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/speed_gauge.dart';
import 'result_screen.dart';

/// ムーブ中のダーク画面。
class MoveScreen extends StatelessWidget {
  const MoveScreen({super.key});

  String _fmtElapsed(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final engine = state.engine;

    if (engine == null) {
      return const Scaffold(
        backgroundColor: RS.charcoal,
        body: Center(child: CircularProgressIndicator(color: RS.mint)),
      );
    }

    final shoe = engine.shoe;
    final energyEmpty = state.energyManager.isEmpty;
    final isSp = engine.mode == EarnMode.sp;
    final dailyCapped = isSp && state.dailyRemainingSp <= 0;
    final statusLabel = state.isPaused
        ? S.paused
        : energyEmpty
            ? S.energyEmpty
            : dailyCapped
                ? S.dailyCapReached
                : engine.inRange
                    ? S.walking
                    : S.outOfRange;
    final statusColor = state.isPaused || energyEmpty || dailyCapped
        ? RS.orange
        : engine.inRange
            ? const Color(0xFF62E58A)
            : RS.red;

    return Scaffold(
      backgroundColor: RS.charcoal,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  // ステータス行
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: RS.charcoalCard,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: RS.white, size: 16),
                      ),
                      const Spacer(),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(statusLabel,
                          style: RS.label(size: 16, color: RS.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: RS.charcoalCard,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Text('GPS',
                                style:
                                    RS.label(size: 11, color: RS.white)),
                            const SizedBox(width: 4),
                            Icon(Icons.signal_cellular_alt,
                                size: 13,
                                color: state.simulationMode ||
                                        state.gpsReceived
                                    ? const Color(0xFF62E58A)
                                    : RS.grey),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 上部2本バー(デイリーSP / エナジー)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: RS.charcoalCard,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TopBarGauge(
                            icon: Icons.directions_walk,
                            iconColor: RS.grey,
                            label: isSp
                                ? '${state.dailyEarnedSp.toStringAsFixed(2)}/${state.dailySpCap.toStringAsFixed(2)}'
                                : '${engine.earnedPoints.toStringAsFixed(2)} GP',
                            delta:
                                '+${engine.earnedPoints.toStringAsFixed(2)}',
                            deltaColor: RS.orange,
                            progress: isSp
                                ? state.dailyEarnedSp / state.dailySpCap
                                : 1.0,
                            fillColor: RS.orange,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TopBarGauge(
                            icon: Icons.bolt,
                            iconColor: RS.blue,
                            label:
                                '${state.energyManager.energy.toStringAsFixed(1)}/${state.inventory.energyCap.toStringAsFixed(1)}',
                            delta:
                                '-${state.consumedEnergyThisMove.toStringAsFixed(1)}',
                            deltaColor: RS.blue,
                            progress: state.inventory.energyCap == 0
                                ? 0
                                : state.energyManager.energy /
                                    state.inventory.energyCap,
                            fillColor: RS.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 時間 / 速度+ゲージ / 歩数
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(_fmtElapsed(state.elapsedSeconds),
                            style: RS.number(size: 26, color: RS.white)),
                        const SizedBox(height: 4),
                        const Icon(Icons.schedule,
                            color: RS.grey, size: 16),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                            '${engine.currentSpeedKmh.toStringAsFixed(1)} ${S.kmh}',
                            style: RS.number(size: 26, color: RS.white)),
                        const SizedBox(height: 6),
                        SpeedGauge(
                          speedKmh: engine.currentSpeedKmh,
                          minRange: shoe.type.minSpeedKmh,
                          maxRange: shoe.type.maxSpeedKmh,
                          size: 110,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${shoe.type.minSpeedKmh.toStringAsFixed(1)}-${shoe.type.maxSpeedKmh.toStringAsFixed(1)} ${S.kmh}',
                          style: RS.label(
                              size: 12,
                              color: engine.inRange
                                  ? RS.mint
                                  : RS.red),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${engine.distanceMeters ~/ GameConfig.metersPerStep}',
                            style: RS.number(size: 26, color: RS.white)),
                        const SizedBox(height: 4),
                        const Icon(Icons.directions_walk,
                            color: RS.grey, size: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 巨大距離表示
                Text((engine.distanceMeters / 1000).toStringAsFixed(2),
                    style: RS.number(size: 84, color: RS.white)),
                Text(S.kilometers,
                    style: RS.label(size: 16, color: RS.grey)),
                const SizedBox(height: 28),

                // 獲得ポイント
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: RS.grey, width: 2.5),
                      ),
                      child: const Icon(Icons.directions_walk,
                          color: RS.grey, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text('+${engine.earnedPoints.toStringAsFixed(2)}',
                        style: RS.number(size: 34, color: RS.orange)),
                  ],
                ),

                if (state.locationError != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(state.locationError!,
                        style: RS.body(size: 12, color: RS.red)),
                  ),
                if (!state.simulationMode && !state.gpsReceived)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(S.gpsWaiting,
                        style: RS.body(size: 12, color: RS.grey)),
                  ),
              ],
            ),
          ),

          // 下部ラベンダー山形パネル
          _BottomPanel(state: state),
        ],
      ),
    );
  }
}

class _TopBarGauge extends StatelessWidget {
  const _TopBarGauge({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.delta,
    required this.deltaColor,
    required this.progress,
    required this.fillColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String delta;
  final Color deltaColor;
  final double progress;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: RS.label(size: 11.5, color: RS.white)),
            ),
            Text(delta, style: RS.label(size: 11, color: deltaColor)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: const Color(0xFF55555A),
            valueColor: AlwaysStoppedAnimation(fillColor),
          ),
        ),
      ],
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _ChevronClipper(),
      child: Container(
        color: const Color(0xFFE5D5F5),
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
        child: Column(
          children: [
            if (state.simulationMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${S.simSpeed} ${state.simSpeedKmh.toStringAsFixed(1)} ${S.kmh}',
                      style: RS.label(size: 12),
                    ),
                    Expanded(
                      child: Slider(
                        value: state.simSpeedKmh,
                        min: 0,
                        max: 25,
                        divisions: 50,
                        activeColor: RS.purpleDeep,
                        label: state.simSpeedKmh.toStringAsFixed(1),
                        onChanged: state.setSimSpeed,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleButton(
                  icon: Icons.map_outlined,
                  size: 52,
                  color: RS.white,
                  onTap: null,
                ),
                // 一時停止/再開
                _CircleButton(
                  icon: state.isPaused ? Icons.play_arrow : Icons.pause,
                  size: 78,
                  color: RS.white,
                  onTap: state.togglePause,
                  semanticLabel: '一時停止',
                ),
                // ストップ
                _CircleButton(
                  icon: Icons.stop,
                  size: 52,
                  color: RS.red,
                  iconColor: RS.white,
                  semanticLabel: 'ストップ',
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final session = await state.stopMove();
                    if (session != null) {
                      navigator.pushReplacement(
                        MaterialPageRoute<void>(
                            builder: (_) =>
                                ResultScreen(session: session)),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
    this.iconColor = RS.ink,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: RS.ink, width: 2.5),
          ),
          child: Icon(icon, size: size * 0.42, color: iconColor),
        ),
      ),
    );
  }
}

/// 山形(上向きの頂点)のクリッパー
class _ChevronClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 44)
    ..lineTo(size.width / 2, 0)
    ..lineTo(size.width, 44)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
