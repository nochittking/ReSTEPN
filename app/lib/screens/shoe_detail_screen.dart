import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/game_config.dart';
import '../l10n/strings_ja.dart';
import '../models/gem.dart';
import '../models/shoe.dart';
import '../models/skin.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/gem_art.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';
import 'enhance_screen.dart';
import 'fusion_screen.dart';
import 'mint_screen.dart';

/// シューズ詳細: 4隅ソケット・属性バー・レベルアップ/リペア。
class ShoeDetailScreen extends StatelessWidget {
  const ShoeDetailScreen({super.key, required this.shoeId});

  final String shoeId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shoe = state.inventory.byId(shoeId);
    if (shoe == null) {
      return const Scaffold(body: SizedBox());
    }
    final gems = state.equippedGems(shoe.id);

    return Scaffold(
      backgroundColor: const Color(0xFFD9F5E7), // ミントグリーンの背景
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: RS.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_walk, size: 18),
                        const SizedBox(width: 4),
                        Text(state.spBalance.toStringAsFixed(2),
                            style: RS.label(size: 15)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                children: [
                  StepnCard(
                    radius: 32,
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        // ソケット付きシューズ表示
                        SizedBox(
                          height: 240,
                          child: Stack(
                            children: [
                              Center(
                                child: Container(
                                  width: 190,
                                  height: 190,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(colors: [
                                      RS.typeColor(shoe.type)
                                          .withValues(alpha: 0.45),
                                      RS.typeColor(shoe.type)
                                          .withValues(alpha: 0.08),
                                    ]),
                                  ),
                                  child: Center(
                                      child: SneakerArt(
                                          shoe: shoe,
                                          size: 190,
                                          skin: state.equippedSkinOf(shoe.id))),
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
                                    size: 52,
                                    onTap: () => _onSocketTap(
                                        context, state, shoe,
                                        GemType.values[i]),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        PillBadge(
                          text: shoe.serialLabel,
                          color: RS.white,
                          textColor: RS.blue,
                          borderColor: RS.blue,
                          fontSize: 13,
                        ),
                        const SizedBox(height: 14),

                        // レアリティ / タイプ / 耐久
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PillBadge(
                              text: shoe.rarity.label,
                              color: RS.rarityColor(shoe.rarity),
                              textColor: RS.white,
                              fontSize: 13,
                            ),
                            Column(
                              children: [
                                Text(shoe.type.rangeLabel,
                                    style: RS.label(size: 11)),
                                const SizedBox(height: 2),
                                PillBadge(
                                  text: shoe.type.label,
                                  color: RS.typeColor(shoe.type),
                                  textColor: RS.white,
                                  fontSize: 13,
                                ),
                              ],
                            ),
                            PillBadge(
                              text:
                                  '${shoe.durability.toStringAsFixed(1)}/100.0',
                              color: RS.mint,
                              fontSize: 13,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // レベルバー
                        _BarLine(
                          label: 'Level ${shoe.level}',
                          progress: shoe.level / GameConfig.maxLevel,
                          fill: RS.mint,
                        ),
                        const SizedBox(height: 8),
                        _BarLine(
                          label:
                              '${S.mintLabel} ${shoe.mintCount}/7',
                          progress: shoe.mintCount / 7,
                          fill: RS.mint,
                          segments: 7,
                        ),
                        const SizedBox(height: 14),

                        // スキンスロット(見た目の差し替え)
                        _SkinSlot(
                          skin: state.equippedSkinOf(shoe.id),
                          onTap: () => _showSkinPicker(context, state, shoe),
                        ),
                        const SizedBox(height: 18),

                        // 属性
                        Row(
                          children: [
                            Text(S.attributes, style: RS.label(size: 22)),
                            const Spacer(),
                            PillBadge(
                                text: S.attrBase,
                                color: RS.white,
                                fontSize: 11),
                            const SizedBox(width: 6),
                            PillBadge(
                                text: '+ジェム',
                                color: RS.mint,
                                fontSize: 11),
                          ],
                        ),
                        if (shoe.unspentPoints > 0) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: RS.mint.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: RS.mintDark),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars,
                                    size: 16, color: RS.mintDark),
                                const SizedBox(width: 6),
                                Text(
                                  '${S.unspentPoints}: ${shoe.unspentPoints}',
                                  style: RS.label(size: 13),
                                ),
                                const Spacer(),
                                Text('+ボタンで割り振り',
                                    style: RS.body(size: 11, color: RS.grey)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        for (final attr in ShoeAttr.values) ...[
                          _AttrLine(
                            shoe: shoe,
                            attr: attr,
                            gems: gems,
                            onAllocate: shoe.unspentPoints > 0
                                ? () => state.allocatePoint(shoe, attr)
                                : null,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // 下部アクションバー
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF9F2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: RS.mintDark, width: 1.5),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
            spacing: 18,
            children: [
              _ActionItem(
                icon: Icons.upgrade,
                label: S.levelUp,
                onTap: () => _showLevelUpDialog(context, state, shoe),
              ),
              _ActionItem(
                icon: Icons.build,
                label: S.repair,
                onTap: () => _showRepairDialog(context, state, shoe),
              ),
              _ActionItem(
                icon: Icons.favorite_border,
                label: S.mint,
                onTap: () => _openMint(context, state, shoe),
              ),
              _ActionItem(
                icon: Icons.sell_outlined,
                label: S.sell,
                onTap: () => _showSellDialog(context, state, shoe),
              ),
              _ActionItem(
                icon: Icons.gavel,
                label: S.enhance,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const EnhanceScreen()),
                ),
              ),
              _ActionItem(
                icon: Icons.science_outlined,
                label: S.fusion,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => FusionScreen(baseId: shoe.id)),
                ),
              ),
              _ActionItem(icon: Icons.sync_alt, label: S.transfer),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- ミント / 売却 ----

  void _openMint(BuildContext context, AppState state, Shoe shoe) {
    final reason = state.mint.mintBlockReason(shoe);
    if (reason != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${S.mint}: $reason')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MintScreen(parentId: shoe.id)),
    );
  }

  void _showSellDialog(BuildContext context, AppState state, Shoe shoe) {
    final price = state.mint.sellPrice(shoe);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.sellTitle, style: RS.label(size: 20)),
              const SizedBox(height: 10),
              SneakerArt(
                  shoe: shoe, size: 120, skin: state.equippedSkinOf(shoe.id)),
              const SizedBox(height: 8),
              Text(shoe.displayName, style: RS.label(size: 14)),
              const SizedBox(height: 10),
              Text(S.sellConfirm,
                  textAlign: TextAlign.center,
                  style: RS.body(size: 12, color: RS.grey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F5EF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFDDDCD4)),
                ),
                child: Row(
                  children: [
                    Text(S.sellPriceLabel,
                        style: RS.label(size: 13, color: RS.grey)),
                    const Spacer(),
                    Text('${price.toStringAsFixed(1)} SP',
                        style: RS.label(size: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StepnButton(
                      label: S.cancel,
                      color: RS.white,
                      height: 48,
                      fontSize: 14,
                      onTap: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StepnButton(
                      label: S.confirm,
                      height: 48,
                      fontSize: 14,
                      onTap: () async {
                        final navigator = Navigator.of(dialogContext);
                        final rootNavigator = Navigator.of(context);
                        await state.sellShoe(shoe);
                        navigator.pop();
                        rootNavigator.pop(); // 詳細画面も閉じる(靴が消えたため)
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- ソケット操作 ----

  void _onSocketTap(
      BuildContext context, AppState state, Shoe shoe, GemType type) {
    final equipped = state.equippedGemOf(shoe.id, type);
    if (equipped != null) {
      _showGemDetail(context, state, equipped);
    } else {
      _showGemPicker(context, state, shoe, type);
    }
  }

  void _showGemDetail(BuildContext context, AppState state, Gem gem) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: gem.type.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child:
                        GemArt(type: gem.type, level: gem.level, size: 44),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(gem.displayName, style: RS.label(size: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F5EF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _EffectRow(
                        label: '固定値',
                        value: '+${gem.flatBonus.toStringAsFixed(1)}'),
                    const SizedBox(height: 6),
                    _EffectRow(
                        label: '倍率',
                        value:
                            'x${(1 + gem.percentBonus / 100).toStringAsFixed(2)}'),
                    const Divider(),
                    _EffectRow(
                      label: gem.type.label,
                      value:
                          '+${(gem.flatBonus * (1 + gem.percentBonus / 100)).toStringAsFixed(1)}',
                      emphasize: true,
                      color: gem.type.color,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StepnButton(
                label: S.removeGem,
                height: 48,
                fontSize: 15,
                onTap: () {
                  state.unequipGem(gem);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGemPicker(
      BuildContext context, AppState state, Shoe shoe, GemType type) {
    final candidates = state.unequippedGems(type);
    Gem? selected;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: RS.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${type.label}ジェム', style: RS.label(size: 18)),
              const SizedBox(height: 16),
              if (candidates.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(S.noGems, style: RS.body(size: 13)),
                )
              else
                Flexible(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: [
                      for (final gem in candidates)
                        GestureDetector(
                          onTap: () => setState(() => selected = gem),
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected == gem
                                  ? type.color.withValues(alpha: 0.2)
                                  : RS.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected == gem
                                    ? RS.ink
                                    : const Color(0xFFDDDCD4),
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 4,
                                  left: 6,
                                  child: Text('+${gem.flatBonus.toStringAsFixed(0)}',
                                      style: RS.label(
                                          size: 10,
                                          color: type.color)),
                                ),
                                Center(
                                  child: GemArt(
                                      type: gem.type,
                                      level: gem.level,
                                      size: 40),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: StepnButton(
                      label: S.cancel,
                      color: RS.white,
                      height: 48,
                      fontSize: 14,
                      onTap: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StepnButton(
                      label: S.equipGem,
                      height: 48,
                      fontSize: 14,
                      onTap: candidates.isEmpty
                          ? null
                          : () {
                              final gem = selected ?? candidates.first;
                              state.equipGem(shoe.id, gem);
                              Navigator.of(sheetContext).pop();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- スキン装着 ----

  void _showSkinPicker(BuildContext context, AppState state, Shoe shoe) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: RS.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        final equipped = state.equippedSkinOf(shoe.id);
        final available = state.unequippedSkins;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.selectSkin, style: RS.label(size: 18)),
              const SizedBox(height: 6),
              Text(S.skinNote,
                  textAlign: TextAlign.center,
                  style: RS.body(size: 11, color: RS.grey)),
              const SizedBox(height: 16),
              if (equipped != null) ...[
                _SkinTile(
                  skin: equipped,
                  shoe: shoe,
                  selected: true,
                  onTap: () async {
                    await state.unequipSkin(equipped);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                  trailing: Text(S.removeSkin,
                      style: RS.label(size: 12, color: RS.red)),
                ),
                const Divider(height: 24),
              ],
              if (available.isEmpty && equipped == null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(S.noSkins, style: RS.body(size: 13)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final s in available)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SkinTile(
                            skin: s,
                            shoe: shoe,
                            selected: false,
                            onTap: () async {
                              await state.equipSkin(shoe.id, s);
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              StepnButton(
                label: S.cancel,
                color: RS.white,
                height: 48,
                fontSize: 14,
                onTap: () => Navigator.of(sheetContext).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- レベルアップ / リペア ----

  void _showLevelUpDialog(BuildContext context, AppState state, Shoe shoe) {
    final cost = GameConfig.levelUpCost(shoe.level);
    final maxed = shoe.level >= GameConfig.maxLevel;
    final milestone =
        !maxed && GameConfig.milestoneLevels.contains(shoe.level + 1);
    final basePoints = GameConfig.pointsPerLevelByRarity[shoe.rarity.index];
    final canPay =
        state.spBalance >= cost.sp && state.gpBalance >= cost.gp;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(S.levelUp, style: RS.label(size: 20)),
              const SizedBox(height: 12),
              Text(
                maxed
                    ? S.maxLevelReached
                    : 'Lv ${shoe.level} → Lv ${shoe.level + 1}',
                style: RS.label(size: 15),
              ),
              if (!maxed) ...[
                const SizedBox(height: 4),
                Text('振り分けポイント +$basePoints',
                    style: RS.body(size: 12, color: RS.mintDark)),
                Text(S.critChanceNote,
                    style: RS.body(size: 12, color: RS.mintDark)),
                if (milestone)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: RS.purpleDeep.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: RS.purpleDeep.withValues(alpha: 0.5)),
                      ),
                      child: Text(S.milestoneNote,
                          style:
                              RS.label(size: 12, color: RS.purpleDeep)),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              _CostRow(cost: cost),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: StepnButton(
                      label: S.cancel,
                      color: RS.white,
                      height: 48,
                      fontSize: 14,
                      onTap: () => Navigator.of(dialogContext).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StepnButton(
                      label: S.confirm,
                      height: 48,
                      fontSize: 14,
                      onTap: maxed || !canPay
                          ? null
                          : () async {
                              final result = await state.levelUpShoe(shoe);
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              if (result != null && context.mounted) {
                                _showLevelUpResult(context, result);
                              }
                            },
                    ),
                  ),
                ],
              ),
              if (!maxed && !canPay)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(S.notEnoughSp,
                      style: RS.body(size: 12, color: RS.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// レベルアップの結果演出。クリティカル段階で色と文言が変わる。
  void _showLevelUpResult(
      BuildContext context, ({int points, int critTier}) result) {
    final (title, color, icon) = switch (result.critTier) {
      2 => (S.critSuper, RS.purpleDeep, Icons.auto_awesome),
      1 => (S.critBig, const Color(0xFFE8940A), Icons.celebration),
      _ => (S.critNormal, RS.mintDark, Icons.upgrade),
    };
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: color),
              const SizedBox(height: 8),
              Text(title, style: RS.label(size: 22, color: color)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Text('${S.pointsGained} +${result.points}pt',
                    style: RS.label(size: 17, color: color)),
              ),
              const SizedBox(height: 18),
              StepnButton(
                label: 'OK',
                height: 46,
                fontSize: 15,
                width: 150,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepairDialog(BuildContext context, AppState state, Shoe shoe) {
    var target = 100.0;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final amount = (target - shoe.durability).clamp(0.0, 100.0);
          final cost = state.repairCost(shoe, amount);
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 36),
                      Text(S.repair, style: RS.label(size: 22)),
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: RS.mint,
                            shape: BoxShape.circle,
                            border: Border.all(color: RS.ink, width: 2),
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SneakerArt(
                      shoe: shoe,
                      size: 150,
                      skin: state.equippedSkinOf(shoe.id)),
                  const SizedBox(height: 8),
                  Text(
                    '${S.durability}:${shoe.durability.toStringAsFixed(0)}/100',
                    style: RS.label(size: 18, color: RS.purpleDeep),
                  ),
                  Slider(
                    value: target.clamp(shoe.durability, 100.0),
                    min: shoe.durability,
                    max: 100,
                    activeColor: RS.mint,
                    onChanged: shoe.durability >= 100
                        ? null
                        : (v) => setState(() => target = v),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F5EF),
                      borderRadius: BorderRadius.circular(999),
                      border:
                          Border.all(color: const Color(0xFFDDDCD4)),
                    ),
                    child: Row(
                      children: [
                        Text(S.cost,
                            style:
                                RS.label(size: 13, color: RS.grey)),
                        const Spacer(),
                        Text('${cost.toStringAsFixed(1)} SP',
                            style: RS.label(size: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: StepnButton(
                          label: S.cancel,
                          color: RS.white,
                          height: 48,
                          fontSize: 14,
                          onTap: () =>
                              Navigator.of(dialogContext).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StepnButton(
                          label: S.confirm,
                          height: 48,
                          fontSize: 14,
                          onTap: amount <= 0 || state.spBalance < cost
                              ? null
                              : () async {
                                  await state.repairShoe(shoe, amount);
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarLine extends StatelessWidget {
  const _BarLine({
    required this.label,
    required this.progress,
    required this.fill,
    this.segments,
  });

  final String label;
  final double progress;
  final Color fill;
  final int? segments;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: RS.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RS.ink, width: 1.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: fill),
          ),
          if (segments != null)
            Row(
              children: [
                for (var i = 1; i < segments!; i++) ...[
                  const Spacer(),
                  Container(width: 1.5, color: RS.ink.withValues(alpha: 0.3)),
                ],
                const Spacer(),
              ],
            ),
          Center(child: Text(label, style: RS.label(size: 13))),
        ],
      ),
    );
  }
}

class _AttrLine extends StatelessWidget {
  const _AttrLine(
      {required this.shoe, required this.attr, required this.gems, this.onAllocate});

  final Shoe shoe;
  final ShoeAttr attr;
  final List<Gem> gems;

  /// 未割り当てポイントがある時、属性を+1する。nullなら+ボタン非表示。
  final VoidCallback? onAllocate;

  @override
  Widget build(BuildContext context) {
    final base = shoe.baseAttr(attr);
    final total = shoe.totalAttr(attr, gems);
    final color = [
      RS.attrEfficiency,
      RS.attrLuck,
      RS.attrComfort,
      RS.attrResilience
    ][attr.index];
    const maxScale = 120.0;

    return Row(
      children: [
        AttrIcon(color: color, size: 18),
        const SizedBox(width: 8),
        SizedBox(
            width: 52, child: Text(attr.label, style: RS.label(size: 13))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFE8E7E0)),
                  // ジェム込み(色薄め)
                  FractionallySizedBox(
                    widthFactor: (total / maxScale).clamp(0.0, 1.0),
                    child: Container(color: color.withValues(alpha: 0.45)),
                  ),
                  // 基礎値
                  FractionallySizedBox(
                    widthFactor: (base / maxScale).clamp(0.0, 1.0),
                    child: Container(color: RS.mint),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 46,
          child: Text(total.toStringAsFixed(1),
              textAlign: TextAlign.right, style: RS.label(size: 14)),
        ),
        if (onAllocate != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onAllocate,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: RS.mint,
                shape: BoxShape.circle,
                border: Border.all(color: RS.ink, width: 1.6),
              ),
              child: const Icon(Icons.add, size: 15),
            ),
          ),
        ],
      ],
    );
  }
}

class _EffectRow extends StatelessWidget {
  const _EffectRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: RS.label(size: emphasize ? 14 : 12)),
        const Spacer(),
        Text(value,
            style: RS.label(
                size: emphasize ? 17 : 14, color: color ?? RS.ink)),
      ],
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.cost});

  final ({double sp, double gp}) cost;

  @override
  Widget build(BuildContext context) {
    final text = cost.gp > 0
        ? '${cost.sp.toStringAsFixed(1)} SP + ${cost.gp.toStringAsFixed(1)} GP'
        : '${cost.sp.toStringAsFixed(1)} SP';
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
          Text(text, style: RS.label(size: 16)),
        ],
      ),
    );
  }
}

class _SkinSlot extends StatelessWidget {
  const _SkinSlot({required this.skin, required this.onTap});

  final Skin? skin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final equipped = skin != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: RS.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped ? RS.blue : const Color(0xFFDDDCD4),
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: equipped
                    ? RS.blue.withValues(alpha: 0.12)
                    : const Color(0xFFF0EFE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                equipped ? Icons.palette : Icons.palette_outlined,
                color: equipped ? RS.blue : RS.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.skin, style: RS.label(size: 13, color: RS.grey)),
                  const SizedBox(height: 2),
                  Text(
                    equipped ? skin!.name : S.noSkinEquipped,
                    style: RS.label(size: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: RS.grey),
          ],
        ),
      ),
    );
  }
}

class _SkinTile extends StatelessWidget {
  const _SkinTile({
    required this.skin,
    required this.shoe,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final Skin skin;
  final Shoe shoe;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? RS.blue.withValues(alpha: 0.08) : RS.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? RS.blue : const Color(0xFFDDDCD4),
            width: 1.6,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 48,
              child: SneakerArt(shoe: shoe, size: 64, skin: skin),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(skin.name, style: RS.label(size: 15)),
                  const SizedBox(height: 2),
                  Text('${skin.visualType.label} / ${skin.paletteRarity.label}',
                      style: RS.body(size: 11, color: RS.grey)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label(${S.comingSoon})')),
              ),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: RS.mintDark, size: 26),
            const SizedBox(height: 2),
            Text(label, style: RS.label(size: 10.5)),
          ],
        ),
      ),
    );
  }
}
