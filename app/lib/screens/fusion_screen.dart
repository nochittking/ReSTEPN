import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/shoe.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';

/// フュージョン: ベース靴 + 生贄1足(同レア)で、生贄が上回る属性を
/// 「現在値〜生贄値」の範囲でランダム底上げする。生贄は消費される。
class FusionScreen extends StatefulWidget {
  const FusionScreen({super.key, required this.baseId});

  final String baseId;

  @override
  State<FusionScreen> createState() => _FusionScreenState();
}

class _FusionScreenState extends State<FusionScreen> {
  String? sacrificeId;

  static const _attrColors = [
    RS.attrEfficiency,
    RS.attrLuck,
    RS.attrComfort,
    RS.attrResilience,
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final base = state.inventory.byId(widget.baseId);
    if (base == null) return const Scaffold(body: SizedBox());
    final sacrifice = state.inventory.byId(sacrificeId);

    final cost = state.mint.fusionCost(base.rarity);
    final canPay = state.spBalance >= cost;
    final preview =
        sacrifice != null ? state.mint.fusionPreview(base, sacrifice) : null;
    final anyGain = preview?.values.any((v) => v.max != null) ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Semantics(
                    label: '戻る',
                    button: true,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: RS.mint,
                          shape: BoxShape.circle,
                          border: Border.all(color: RS.ink, width: 2),
                        ),
                        child:
                            const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                        child:
                            Text(S.fusionTitle, style: RS.label(size: 22))),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // ベース(上)
                  Text(S.fusionBase, style: RS.label(size: 13, color: RS.purpleDeep)),
                  const SizedBox(height: 4),
                  StepnCard(
                    radius: 24,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SneakerArt(shoe: base, size: 96),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PillBadge(
                                text: base.rarity.label,
                                color: RS.rarityColor(base.rarity),
                                textColor: RS.white,
                                fontSize: 12,
                              ),
                              const SizedBox(height: 4),
                              Text('${base.type.label}  Lv${base.level}',
                                  style: RS.label(size: 13)),
                              Text(base.serialLabel,
                                  style: RS.label(size: 11, color: RS.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                      child: Icon(Icons.add, color: RS.grey, size: 22)),
                  const SizedBox(height: 10),

                  // 生贄(下)
                  StepnCard(
                    radius: 24,
                    padding: const EdgeInsets.all(12),
                    onTap: () => _pickSacrifice(state, base),
                    child: sacrifice == null
                        ? SizedBox(
                            height: 96,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_circle_outline,
                                      size: 34, color: RS.grey),
                                  const SizedBox(height: 4),
                                  Text(S.fusionSacrifice,
                                      style: RS.label(
                                          size: 13, color: RS.grey)),
                                ],
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              SneakerArt(shoe: sacrifice, size: 96),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('${sacrifice.type.label}  Lv${sacrifice.level}',
                                        style: RS.label(size: 13)),
                                    Text(sacrifice.serialLabel,
                                        style: RS.label(
                                            size: 11, color: RS.grey)),
                                    const SizedBox(height: 2),
                                    Text('タップで変更',
                                        style: RS.body(
                                            size: 11, color: RS.grey)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ベース属性の表(current > 範囲)
                  StepnCard(
                    radius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(S.baseAttributes, style: RS.label(size: 16)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final attr in ShoeAttr.values) ...[
                          _AttrRow(
                            attr: attr,
                            color: _attrColors[attr.index],
                            current: base.baseAttr(attr),
                            max: preview?[attr]?.max,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(S.fusionNote,
                      style: RS.body(size: 12, color: RS.grey)),
                  const SizedBox(height: 16),

                  _CostRow(cost: cost),
                  const SizedBox(height: 14),
                  StepnButton(
                    label: S.fusionButton,
                    fontSize: 18,
                    onTap: sacrifice != null && canPay && anyGain
                        ? () => _doFusion(state, base, sacrifice)
                        : null,
                  ),
                  if (sacrifice != null && !anyGain)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                          child: Text(S.fusionNoGain,
                              style: RS.body(size: 12, color: RS.red))),
                    ),
                  if (sacrifice != null && !canPay)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                          child: Text(S.notEnoughSp,
                              style: RS.body(size: 12, color: RS.red))),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _doFusion(AppState state, Shoe base, Shoe sacrifice) async {
    final gains = await state.fuseShoes(base, sacrifice);
    if (gains == null || !mounted) return;
    setState(() => sacrificeId = null);
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(gains.isEmpty ? S.fusionNoGain : S.fusionDone,
                  textAlign: TextAlign.center, style: RS.label(size: 17)),
              const SizedBox(height: 14),
              SneakerArt(shoe: base, size: 130),
              const SizedBox(height: 12),
              for (final e in gains.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${e.key.label}  ',
                          style: RS.label(size: 14)),
                      Text('+${e.value.toStringAsFixed(1)}',
                          style: RS.label(
                              size: 15, color: _attrColors[e.key.index])),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              StepnButton(
                label: 'OK',
                height: 46,
                fontSize: 15,
                width: 150,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickSacrifice(AppState state, Shoe base) {
    final candidates = state.inventory.shoes
        .where((s) => s.id != base.id && s.rarity == base.rarity)
        .toList();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: RS.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.fusionMatching, style: RS.label(size: 18)),
            const SizedBox(height: 16),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(S.notEnoughShoes.replaceAll('5足', '1足'),
                    style: RS.body(size: 13)),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final shoe = candidates[i];
                    return Semantics(
                      label: '生贄 ${shoe.displayName}',
                      button: true,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => sacrificeId = shoe.id);
                          Navigator.of(sheetContext).pop();
                        },
                        child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: RS.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFDDDCD4), width: 2),
                          ),
                          child: Column(
                            children: [
                              SneakerArt(shoe: shoe, size: 84),
                              Text('Lv${shoe.level}',
                                  style: RS.label(size: 11)),
                              Text(shoe.serialLabel,
                                  style:
                                      RS.body(size: 9, color: RS.grey)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _AttrRow extends StatelessWidget {
  const _AttrRow({
    required this.attr,
    required this.color,
    required this.current,
    required this.max,
  });

  final ShoeAttr attr;
  final Color color;
  final double current;
  final double? max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AttrIcon(color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(width: 52, child: Text(attr.label, style: RS.label(size: 13))),
        Text(current.toStringAsFixed(1), style: RS.label(size: 14)),
        const SizedBox(width: 8),
        Text('>', style: RS.label(size: 13, color: RS.grey)),
        const Spacer(),
        if (max != null)
          Text('${current.toStringAsFixed(1)}〜${max!.toStringAsFixed(1)}',
              style: RS.label(size: 15, color: RS.mintDark))
        else
          Text(current.toStringAsFixed(1),
              style: RS.label(size: 14, color: RS.grey)),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.cost});

  final double cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDDCD4)),
      ),
      child: Row(
        children: [
          Text(S.cost, style: RS.label(size: 13, color: RS.grey)),
          const Spacer(),
          Text('${cost.toStringAsFixed(0)} SP', style: RS.label(size: 16)),
        ],
      ),
    );
  }
}
