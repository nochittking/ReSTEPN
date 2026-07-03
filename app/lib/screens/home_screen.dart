import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/move_session.dart';
import '../state/app_state.dart';
import 'history_screen.dart';
import 'inventory_screen.dart';
import 'move_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);

    if (!state.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final cap = state.inventory.energyCap;
    final energy = state.energyManager.energy;

    return Scaffold(
      appBar: AppBar(
        title: const Text(S.appTitle),
        actions: [
          IconButton(
            tooltip: S.inventory,
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const InventoryScreen()),
            ),
          ),
          IconButton(
            tooltip: S.history,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ポイント残高
          Row(
            children: [
              _BalanceChip(
                  code: EarnMode.sp.code,
                  label: EarnMode.sp.label,
                  value: state.spBalance),
              const SizedBox(width: 12),
              _BalanceChip(
                  code: EarnMode.gp.code,
                  label: EarnMode.gp.label,
                  value: state.gpBalance),
            ],
          ),
          const SizedBox(height: 16),

          // エナジーゲージ
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(S.energy, style: theme.textTheme.titleMedium),
                      Text(
                        '${energy.toStringAsFixed(1)} / ${cap.toStringAsFixed(1)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: cap == 0 ? 0 : (energy / cap).clamp(0.0, 1.0),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // シューズ選択
          Text(S.selectShoe, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (state.inventory.isEmpty)
            Text(S.noShoes, style: theme.textTheme.bodyMedium)
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.inventory.shoes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final shoe = state.inventory.shoes[index];
                  final selected = shoe.id == state.selectedShoeId;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => state.selectShoe(shoe.id),
                    label: SizedBox(
                      width: 140,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shoe.displayName,
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${shoe.type.minSpeedKmh.toStringAsFixed(0)}–${shoe.type.maxSpeedKmh.toStringAsFixed(0)} ${S.kmh}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    labelPadding: const EdgeInsets.all(8),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // 報酬モード選択(SP/GPどちらか一方)
          Text(S.selectMode, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<EarnMode>(
            segments: EarnMode.values
                .map((m) => ButtonSegment(
                      value: m,
                      label: Text('${m.code}(${m.label})'),
                    ))
                .toList(),
            selected: {state.selectedMode},
            onSelectionChanged: (set) => state.selectMode(set.first),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text(S.simulationMode),
            value: state.simulationMode,
            onChanged: state.setSimulationMode,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          if (state.energyManager.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                S.noEnergy,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),

          FilledButton.icon(
            onPressed: state.canStart
                ? () {
                    state.startMove();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MoveScreen()),
                    );
                  }
                : null,
            icon: const Icon(Icons.play_arrow),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(S.startMove, style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip(
      {required this.code, required this.label, required this.value});

  final String code;
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$code($label)', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value.toStringAsFixed(2),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
