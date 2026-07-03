import 'package:flutter/material.dart';

import '../l10n/strings_ja.dart';
import '../models/move_session.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.session});

  final MoveSession session;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m分${s.toString().padLeft(2, '0')}秒';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(S.resultTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    '${S.earned} ${session.mode.code}(${session.mode.label})',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.earnedPoints.toStringAsFixed(2),
                    style: theme.textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(session.shoeName, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _ResultRow(
                    label: S.distance,
                    value:
                        '${(session.distanceMeters / 1000).toStringAsFixed(2)} km'),
                _ResultRow(
                    label: S.duration,
                    value: _formatDuration(session.durationSeconds)),
                _ResultRow(
                    label: S.avgSpeed,
                    value:
                        '${session.averageSpeedKmh.toStringAsFixed(1)} ${S.kmh}'),
                _ResultRow(
                    label: S.consumedEnergy,
                    value: session.consumedEnergy.toStringAsFixed(2)),
                _ResultRow(
                    label: S.rejectedSamples,
                    value: session.rejectedSamples.toString()),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(S.backToHome, style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label, style: theme.textTheme.bodyMedium),
      trailing: Text(
        value,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
