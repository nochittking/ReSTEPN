import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/shoe.dart';
import '../state/app_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final inventory = state.inventory;

    return Scaffold(
      appBar: AppBar(title: const Text(S.inventoryTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text(S.addShoe),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.energyCapNote, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  _CapRow(
                      label:
                          '${S.baseEnergyLabel}(${inventory.shoes.length}足)',
                      value: inventory.baseEnergy),
                  _CapRow(
                      label: S.rarityBonusLabel, value: inventory.rarityBonus),
                  const Divider(),
                  _CapRow(
                    label: S.energyCapLabel,
                    value: inventory.energyCap,
                    emphasized: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (inventory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(S.noShoes, textAlign: TextAlign.center),
            )
          else
            ...inventory.shoes.map(
              (shoe) => Card(
                child: ListTile(
                  leading: Icon(
                    Icons.directions_walk,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(shoe.displayName),
                  subtitle: Text(
                    '適正速度 ${shoe.type.minSpeedKmh.toStringAsFixed(0)}–${shoe.type.maxSpeedKmh.toStringAsFixed(0)} ${S.kmh}'
                    '${shoe.rarity.energyBonus > 0 ? ' / ボーナス +${shoe.rarity.energyBonus.toStringAsFixed(1)}' : ''}',
                  ),
                  trailing: IconButton(
                    tooltip: S.delete,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => state.removeShoe(shoe.id),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final state = context.read<AppState>();
    var type = ShoeType.walker;
    var rarity = Rarity.common;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text(S.addShoe),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ShoeType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: S.shoeType),
                items: ShoeType.values
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                              '${t.label}(${t.minSpeedKmh.toStringAsFixed(0)}–${t.maxSpeedKmh.toStringAsFixed(0)} ${S.kmh})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => type = v ?? type),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Rarity>(
                initialValue: rarity,
                decoration: const InputDecoration(labelText: S.rarity),
                items: Rarity.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                              '${r.label}(+${r.energyBonus.toStringAsFixed(1)})'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => rarity = v ?? rarity),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(S.cancel),
            ),
            FilledButton(
              onPressed: () {
                state.addShoe(type, rarity);
                Navigator.of(dialogContext).pop();
              },
              child: const Text(S.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapRow extends StatelessWidget {
  const _CapRow(
      {required this.label, required this.value, this.emphasized = false});

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700, color: theme.colorScheme.primary)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value.toStringAsFixed(1),
            style: style?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
