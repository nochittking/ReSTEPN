import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../state/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mi = local.minute.toString().padLeft(2, '0');
    return '${local.year}/$mm/$dd $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final sessions = state.sessions;

    return Scaffold(
      appBar: AppBar(title: const Text(S.historyTitle)),
      body: sessions.isEmpty
          ? const Center(child: Text(S.noHistory))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final s = sessions[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        s.mode.code,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      '+${s.earnedPoints.toStringAsFixed(2)} ${s.mode.code} — ${(s.distanceMeters / 1000).toStringAsFixed(2)} km',
                    ),
                    subtitle: Text(
                      '${_formatDate(s.startedAt)} / ${s.shoeName} / '
                      '${S.avgSpeed} ${s.averageSpeedKmh.toStringAsFixed(1)} ${S.kmh}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}
