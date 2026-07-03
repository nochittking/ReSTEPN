import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/stepn_button.dart';

/// ムーブ履歴(ホーム上部のアバターから遷移)。
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatDate(DateTime dt) {
    final l = dt.toLocal();
    final mm = l.month.toString().padLeft(2, '0');
    final dd = l.day.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final mi = l.minute.toString().padLeft(2, '0');
    return '${l.year}/$mm/$dd $hh:$mi';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sessions = state.sessions;

    return Scaffold(
      backgroundColor: RS.cream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: RS.mint,
                        shape: BoxShape.circle,
                        border: Border.all(color: RS.ink, width: 2),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                  const Spacer(),
                  Text(S.historyTitle, style: RS.label(size: 20)),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Text(S.noHistory, style: RS.body(size: 14)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final s = sessions[index];
                        return StepnCard(
                          radius: 20,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shadowOffset: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: s.mode.code == 'SP'
                                      ? RS.mint
                                      : RS.lavender,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: RS.ink, width: 2),
                                ),
                                child: Center(
                                    child: Text(s.mode.code,
                                        style: RS.label(size: 13))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+${s.earnedPoints.toStringAsFixed(2)} ${s.mode.code} — ${(s.distanceMeters / 1000).toStringAsFixed(2)} km',
                                      style: RS.label(size: 14),
                                    ),
                                    Text(
                                      '${_formatDate(s.startedAt)} / ${s.shoeName}\n'
                                      '${S.avgSpeed} ${s.averageSpeedKmh.toStringAsFixed(1)} km/h / ${s.estimatedSteps}歩',
                                      style: RS.body(
                                          size: 11, color: RS.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
