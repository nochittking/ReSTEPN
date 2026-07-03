import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../state/app_state.dart';
import 'result_screen.dart';

class MoveScreen extends StatelessWidget {
  const MoveScreen({super.key});

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final engine = state.engine;

    if (engine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final energyEmpty = state.energyManager.isEmpty;
    final inRange = engine.inRange;
    final statusColor = energyEmpty
        ? theme.colorScheme.error
        : inRange
            ? theme.colorScheme.primary
            : theme.colorScheme.tertiary;
    final statusText =
        energyEmpty ? S.energyEmpty : (inRange ? S.inRange : S.outOfRange);

    return Scaffold(
      appBar: AppBar(
        title: Text('${engine.mode.code}モード — ${engine.shoe.displayName}'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (state.locationError != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(state.locationError!,
                      style:
                          TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ),
            if (!state.simulationMode && !state.gpsReceived)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(S.gpsWaiting, style: theme.textTheme.bodyMedium),
              ),

            // 速度とレンジ判定
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(S.currentSpeed, style: theme.textTheme.titleMedium),
                    Text(
                      engine.currentSpeedKmh.toStringAsFixed(1),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(S.kmh, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Chip(
                      label: Text(statusText),
                      backgroundColor: statusColor.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: statusColor),
                      side: BorderSide(color: statusColor),
                    ),
                  ],
                ),
              ),
            ),

            // 統計
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Stat(
                        label: S.elapsed,
                        value: _formatElapsed(state.elapsedSeconds)),
                    _Stat(
                        label: S.distance,
                        value:
                            '${(engine.distanceMeters / 1000).toStringAsFixed(2)} km'),
                    _Stat(
                        label: '${S.earned} ${engine.mode.code}',
                        value: engine.earnedPoints.toStringAsFixed(2)),
                    _Stat(
                        label: S.energy,
                        value: state.energyManager.energy.toStringAsFixed(2)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // シミュレーション速度スライダー(シミュレーションモード時のみ)
            if (state.simulationMode)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${S.simSpeed}: ${state.simSpeedKmh.toStringAsFixed(1)} ${S.kmh}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Slider(
                        value: state.simSpeedKmh,
                        min: 0,
                        max: 25,
                        divisions: 50,
                        label: state.simSpeedKmh.toStringAsFixed(1),
                        onChanged: state.setSimSpeed,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final session = await state.stopMove();
                if (session != null) {
                  navigator.pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => ResultScreen(session: session)),
                  );
                }
              },
              icon: const Icon(Icons.stop),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(S.stopMove, style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
