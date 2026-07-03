import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/gem.dart';
import '../models/shoe.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/gem_art.dart';
import '../widgets/magic_circle.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';
import 'shoe_detail_screen.dart';

/// シューズタブ: 3セグメント(シューズ/ジェム/その他)+サブタブ。
class ShoesTab extends StatefulWidget {
  const ShoesTab({super.key});

  @override
  State<ShoesTab> createState() => _ShoesTabState();
}

class _ShoesTabState extends State<ShoesTab> {
  int _segment = 0; // 0=シューズ 1=ジェム 2=その他
  int _gemSub = 0; // 0=ギャラリー 1=強化

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _BalanceBar(state: state),
          ),
          const SizedBox(height: 12),

          // セグメント切替
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE4E3DC),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  for (final (i, label) in [
                    (0, S.segSneakers),
                    (1, S.segGems),
                    (2, S.segOthers)
                  ].map((e) => e))
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _segment = i),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _segment == i
                                ? RS.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            border: _segment == i
                                ? Border.all(color: RS.ink, width: 2)
                                : null,
                          ),
                          child: Center(
                              child:
                                  Text(label, style: RS.label(size: 15))),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ジェムのサブタブ
          if (_segment == 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 10, 32, 0),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4E3DC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    for (final (i, label) in [
                      (0, S.subGallery),
                      (1, S.subUpgrade)
                    ].map((e) => e))
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gemSub = i),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _gemSub == i
                                  ? RS.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: _gemSub == i
                                  ? Border.all(color: RS.ink, width: 1.6)
                                  : null,
                            ),
                            child: Center(
                                child: Text(label,
                                    style: RS.label(size: 13))),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: switch (_segment) {
              0 => _SneakerGrid(state: state),
              1 => _gemSub == 0
                  ? _GemGallery(state: state)
                  : _GemUpgrade(state: state),
              _ => _OthersPlaceholder(),
            },
          ),
        ],
      ),
    );
  }
}

/// 残高バー(共通ヘッダー)
class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              const SizedBox(width: 12),
              Text('G', style: RS.label(size: 13, color: const Color(0xFFB99A2E))),
              const SizedBox(width: 4),
              Text(state.gpBalance.toStringAsFixed(2),
                  style: RS.label(size: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

/// シューズカードグリッド
class _SneakerGrid extends StatelessWidget {
  const _SneakerGrid({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final shoes = state.inventory.shoes;
    if (shoes.isEmpty) {
      return Center(child: Text(S.noShoes, style: RS.body(size: 14)));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: shoes.length,
      itemBuilder: (context, i) {
        final shoe = shoes[i];
        final gems = state.equippedGems(shoe.id);
        return StepnCard(
          padding: EdgeInsets.zero,
          radius: 24,
          semanticLabel: shoe.displayName,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
                builder: (_) => ShoeDetailScreen(shoeId: shoe.id)),
          ),
          child: Column(
            children: [
              // タイプピルヘッダー
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: RS.typeColor(shoe.type),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(21)),
                ),
                child: Center(
                  child: Text(shoe.type.label,
                      style: RS.label(size: 13, color: RS.white)),
                ),
              ),
              Expanded(
                  child: Center(child: SneakerArt(shoe: shoe, size: 120))),
              PillBadge(
                text: shoe.serialLabel,
                color: RS.white,
                textColor: RS.rarityColor(shoe.rarity),
                borderColor: RS.rarityColor(shoe.rarity),
                fontSize: 11,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${S.mintLabel}: ${shoe.mintCount}',
                        style: RS.label(size: 11)),
                    Text('Lv ${shoe.level}', style: RS.label(size: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: shoe.durability / 100,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFE8E7E0),
                    valueColor: const AlwaysStoppedAnimation(RS.mint),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // 4属性ミニ表示
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final attr in ShoeAttr.values)
                      Row(
                        children: [
                          AttrIcon(
                              color: [
                                RS.attrEfficiency,
                                RS.attrLuck,
                                RS.attrComfort,
                                RS.attrResilience
                              ][attr.index],
                              size: 12),
                          const SizedBox(width: 2),
                          Text(
                            shoe
                                .totalAttr(attr, gems)
                                .toStringAsFixed(0),
                            style: RS.label(size: 10),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ジェムギャラリー
class _GemGallery extends StatelessWidget {
  const _GemGallery({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final gems = state.gems;
    if (gems.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(S.noGems,
            textAlign: TextAlign.center, style: RS.body(size: 14)),
      ));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.92,
      ),
      itemCount: gems.length,
      itemBuilder: (context, i) {
        final gem = gems[i];
        return StepnCard(
          padding: EdgeInsets.zero,
          radius: 24,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: gem.type.color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(21)),
                ),
                child: Center(
                  child: Text('${gem.type.label}ジェム',
                      style: RS.label(size: 13, color: RS.white)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('+${gem.flatBonus.toStringAsFixed(0)}',
                            style: RS.label(
                                size: 13, color: gem.type.color)),
                        Text('+${gem.percentBonus.toStringAsFixed(0)}%',
                            style: RS.label(
                                size: 13, color: gem.type.color)),
                      ],
                    ),
                    Text('lv${gem.level}', style: RS.label(size: 13)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                    child: GemArt(
                        type: gem.type, level: gem.level, size: 64)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PillBadge(
                  text: gem.equippedShoeId != null
                      ? '装着中'
                      : '#${gem.id.hashCode.abs() % 100000000}',
                  color: RS.white,
                  textColor: gem.type.color,
                  borderColor: gem.type.color,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ジェム強化(魔法陣)
class _GemUpgrade extends StatefulWidget {
  const _GemUpgrade({required this.state});

  final AppState state;

  @override
  State<_GemUpgrade> createState() => _GemUpgradeState();
}

class _GemUpgradeState extends State<_GemUpgrade> {
  GemType _type = GemType.efficiency;
  int _level = 1;

  Future<void> _doUpgrade() async {
    try {
      final outcome = await widget.state.upgradeGems(_type, _level);
      if (!mounted) return;
      final success = outcome.result != null;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(success ? S.upgradeSuccess : S.upgradeFailed,
                    style: RS.label(size: 17)),
                const SizedBox(height: 16),
                if (success)
                  GemArt(
                      type: outcome.result!.type,
                      level: outcome.result!.level,
                      size: 80)
                else
                  const Icon(Icons.heart_broken,
                      size: 64, color: RS.grey),
                const SizedBox(height: 20),
                StepnButton(
                  label: 'OK',
                  height: 44,
                  fontSize: 15,
                  width: 140,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final materials = state
        .unequippedGems(_type)
        .where((g) => g.level == _level)
        .toList();
    final canUpgrade = materials.length >= 3;
    final cost = 100.0 * _level;
    final rate = state.gemSuccessRate(_level);

    // レベル別在庫(選択種類)
    final counts = <int, int>{};
    for (final gem in state.unequippedGems(_type)) {
      counts[gem.level] = (counts[gem.level] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        MagicCircle(
          slots: [
            for (var i = 0; i < 3; i++)
              i < materials.length && canUpgrade
                  ? GemArt(type: _type, level: _level, size: 34)
                  : null,
          ],
          center: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(cost.toStringAsFixed(0),
                  style: RS.number(size: 22, color: RS.white)),
              Text('SP', style: RS.label(size: 11, color: RS.grey)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${S.successRate}: ${(rate * 100).toStringAsFixed(0)}%',
            style: RS.label(size: 16, color: RS.orange),
          ),
        ),
        Center(
          child: Text(S.upgradeFailNote,
              style: RS.body(size: 12, color: RS.grey)),
        ),
        const SizedBox(height: 14),

        // 種類タブ
        Row(
          children: [
            for (final type in GemType.values) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _type = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _type == type
                          ? RS.white
                          : type.color.withValues(alpha: 0.15),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border: _type == type
                          ? Border.all(color: RS.ink, width: 1.6)
                          : null,
                    ),
                    child: Center(
                        child: Text(type.label,
                            style: RS.label(size: 12))),
                  ),
                ),
              ),
            ],
          ],
        ),
        // 在庫と素材レベル選択
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RS.white,
            border: Border.all(color: RS.ink, width: 2),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16), top: Radius.circular(4)),
          ),
          child: counts.isEmpty
              ? Center(
                  child: Text(S.noGems,
                      style: RS.body(size: 12, color: RS.grey)))
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final entry
                        in (counts.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key))))
                      GestureDetector(
                        onTap: () =>
                            setState(() => _level = entry.key),
                        child: Container(
                          width: 74,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _level == entry.key
                                ? _type.color.withValues(alpha: 0.2)
                                : RS.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _level == entry.key
                                    ? RS.ink
                                    : const Color(0xFFDDDCD4),
                                width: 2),
                          ),
                          child: Column(
                            children: [
                              GemArt(
                                  type: _type,
                                  level: entry.key,
                                  size: 36),
                              const SizedBox(height: 4),
                              Text('Lv${entry.key} ×${entry.value}',
                                  style: RS.label(size: 11)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        StepnButton(
          label: S.upgradeButton,
          fontSize: 17,
          onTap: canUpgrade && state.spBalance >= cost ? _doUpgrade : null,
        ),
        if (!canUpgrade)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
                child: Text(S.notEnoughGems,
                    style: RS.body(size: 12, color: RS.grey))),
          ),
      ],
    );
  }
}

/// その他(スクロール/バッジ)プレースホルダ
class _OthersPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 56, color: RS.grey),
          const SizedBox(height: 12),
          Text('${S.subScroll} / ${S.subBadges}',
              style: RS.label(size: 15, color: RS.grey)),
          Text(S.comingSoon, style: RS.body(size: 13, color: RS.grey)),
        ],
      ),
    );
  }
}
