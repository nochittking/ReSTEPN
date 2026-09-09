import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/shoe.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/machine_art.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';

/// エンハンス: 同レアリティ5足を合成し、確定で上位レアリティへ進化させる。
/// 失敗は無く、3%の大成功なら2段階アップする。
class EnhanceScreen extends StatefulWidget {
  const EnhanceScreen({super.key});

  @override
  State<EnhanceScreen> createState() => _EnhanceScreenState();
}

class _EnhanceScreenState extends State<EnhanceScreen> {
  Rarity _rarity = Rarity.common;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final materials = state.inventory.shoes
        .where((s) => _selectedIds.contains(s.id))
        .toList();
    final candidates = state.inventory.shoes
        .where((s) => s.rarity == _rarity)
        .toList();
    final cost = state.mint.enhanceCost(_rarity);
    final ready = materials.length == 5;
    final canPay =
        state.spBalance >= cost.sp && state.gpBalance >= cost.gp;

    return Scaffold(
      backgroundColor: RS.cream,
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
                            Text(S.enhanceTitle, style: RS.label(size: 22))),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // 五角形+5スロット
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: LayoutBuilder(builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final h = constraints.maxHeight;
                      final c = Offset(w / 2, h / 2);
                      final r = min(w, h) * 0.40;
                      const slotSize = 86.0;
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: PentagonBase(
                              glowColor: ready && canPay
                                  ? const Color(0xFF62E58A)
                                  : RS.blue,
                            ),
                          ),
                          for (var i = 0; i < 5; i++)
                            Positioned(
                              left: c.dx +
                                  cos(-pi / 2 + 2 * pi * i / 5) * r -
                                  slotSize / 2,
                              top: c.dy +
                                  sin(-pi / 2 + 2 * pi * i / 5) * r -
                                  slotSize / 2,
                              child: _MaterialSlot(
                                shoe: i < materials.length
                                    ? materials[i]
                                    : null,
                                size: slotSize,
                                onRemove: (shoe) => setState(
                                    () => _selectedIds.remove(shoe.id)),
                              ),
                            ),
                          // 中央のコスト表示
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(cost.sp.toStringAsFixed(0),
                                    style: RS.number(
                                        size: 24, color: RS.white)),
                                Text('SP',
                                    style: RS.label(
                                        size: 10, color: RS.grey)),
                                Text(cost.gp.toStringAsFixed(0),
                                    style: RS.number(
                                        size: 18,
                                        color: const Color(0xFFE8CD6C))),
                                Text('GP',
                                    style: RS.label(
                                        size: 10, color: RS.grey)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${S.greatChance}: ${(state.mint.enhanceGreatChance(_rarity) * 100).toStringAsFixed(0)}%',
                      style: RS.label(size: 15, color: RS.orange),
                    ),
                  ),
                  Center(
                    child: Text(S.enhanceNote,
                        textAlign: TextAlign.center,
                        style: RS.body(size: 11.5, color: RS.grey)),
                  ),
                  const SizedBox(height: 14),

                  // レアリティタブ
                  Row(
                    children: [
                      for (final rarity in Rarity.values
                          .where((r) => r != Rarity.legendary)) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _rarity = rarity;
                              _selectedIds.clear();
                            }),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _rarity == rarity
                                    ? RS.white
                                    : RS
                                        .rarityColor(rarity)
                                        .withValues(alpha: 0.25),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                border: _rarity == rarity
                                    ? Border.all(
                                        color: RS.ink, width: 1.8)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  rarity.label,
                                  style: RS.label(
                                      size: 11.5,
                                      color: _rarity == rarity
                                          ? RS.ink
                                          : RS.rarityColor(rarity)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // 候補リスト
                  Container(
                    height: 190,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: RS.white,
                      border: Border.all(color: RS.ink, width: 2),
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                          top: Radius.circular(4)),
                    ),
                    child: candidates.isEmpty
                        ? Center(
                            child: Text(S.notEnoughShoes,
                                style:
                                    RS.body(size: 12, color: RS.grey)))
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: candidates.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, i) {
                              final shoe = candidates[i];
                              final selected =
                                  _selectedIds.contains(shoe.id);
                              return _CandidateCard(
                                shoe: shoe,
                                selected: selected,
                                onTap: () => setState(() {
                                  if (selected) {
                                    _selectedIds.remove(shoe.id);
                                  } else if (_selectedIds.length < 5) {
                                    _selectedIds.add(shoe.id);
                                  }
                                }),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),

                  StepnButton(
                    label: S.enhanceButton,
                    fontSize: 18,
                    onTap: ready && canPay
                        ? () => _confirmEnhance(state, materials, cost)
                        : null,
                  ),
                  if (ready && !canPay)
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

  Future<void> _confirmEnhance(AppState state, List<Shoe> materials,
      ({double sp, double gp}) cost) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('確認', style: RS.label(size: 20)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(S.tokenConsumption,
                      style: RS.label(size: 13, color: RS.grey)),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${cost.sp.toStringAsFixed(0)} SP',
                          style: RS.label(size: 16)),
                      Text('${cost.gp.toStringAsFixed(0)} GP',
                          style: RS.label(size: 16)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('素材5足は消費されます(装着ジェムは自動で外れます)',
                  style: RS.body(size: 11.5, color: RS.grey)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StepnButton(
                      label: S.cancel,
                      color: RS.white,
                      height: 48,
                      fontSize: 14,
                      onTap: () =>
                          Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StepnButton(
                      label: S.confirm,
                      height: 48,
                      fontSize: 14,
                      onTap: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await state.enhanceShoes(materials);
    if (result == null || !mounted) return;
    setState(() => _selectedIds.clear());

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(result.great ? S.enhanceGreat : S.enhanceSuccess,
                  textAlign: TextAlign.center, style: RS.label(size: 17)),
              const SizedBox(height: 16),
              SneakerArt(shoe: result.shoe, size: 150),
              const SizedBox(height: 8),
              PillBadge(
                text: result.shoe.displayName,
                color: RS.rarityColor(result.shoe.rarity),
                textColor: RS.white,
                fontSize: 13,
              ),
              const SizedBox(height: 20),
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
}

class _MaterialSlot extends StatelessWidget {
  const _MaterialSlot({
    required this.shoe,
    required this.size,
    required this.onRemove,
  });

  final Shoe? shoe;
  final double size;
  final void Function(Shoe) onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: shoe != null
                  ? const Color(0xFFFCF8E8)
                  : RS.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: shoe != null ? RS.ink : const Color(0xFF6FCF97),
                width: 3,
              ),
            ),
            child: Center(
              child: shoe != null
                  ? SneakerArt(shoe: shoe!, size: size * 0.72)
                  : Icon(Icons.add,
                      size: size * 0.4, color: const Color(0xFF6FCF97)),
            ),
          ),
          if (shoe != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: () => onRemove(shoe!),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4A4A4E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 15, color: RS.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.shoe,
    required this.selected,
    required this.onTap,
  });

  final Shoe shoe;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '素材 ${shoe.displayName}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 128,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFE9E8E1)
                : RS.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected ? RS.mintDark : const Color(0xFFDDDCD4),
                width: 2),
          ),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: RS.typeColor(shoe.type),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(shoe.type.label,
                    style: RS.label(size: 10, color: RS.white)),
              ),
              Expanded(child: Center(child: SneakerArt(shoe: shoe, size: 84))),
              Text('${S.mintLabel}: ${shoe.mintCount}  Lv ${shoe.level}',
                  style: RS.label(size: 10)),
              const SizedBox(height: 4),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? RS.mintDark : const Color(0xFFCFCEC6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
