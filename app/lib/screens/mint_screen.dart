import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/game_config.dart';
import '../l10n/strings_ja.dart';
import '../models/shoe.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/machine_art.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';

/// シューズミント: 親2足から新しい靴を生成する。
class MintScreen extends StatefulWidget {
  const MintScreen({super.key, required this.parentId});

  final String parentId;

  @override
  State<MintScreen> createState() => _MintScreenState();
}

class _MintScreenState extends State<MintScreen> {
  String? partnerId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final parent = state.inventory.byId(widget.parentId);
    if (parent == null) return const Scaffold(body: SizedBox());
    final partner = state.inventory.byId(partnerId);

    final cost = partner != null ? state.mint.mintCost(parent, partner) : null;
    final canPay = cost != null &&
        state.spBalance >= cost.sp &&
        state.gpBalance >= cost.gp;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFF8),
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
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
                        child: Text(S.mintTitle, style: RS.label(size: 22))),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  // 2つの台座
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _PedestalSlot(
                          shoe: parent,
                          label: parent.serialLabel,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _PedestalSlot(
                          shoe: partner,
                          label: partner?.serialLabel ?? S.selectPartner,
                          onTap: () => _showPartnerPicker(state, parent),
                        ),
                      ),
                    ],
                  ),
                  const MintMachineArt(),
                  const SizedBox(height: 20),

                  // 費用カード
                  StepnCard(
                    radius: 24,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(S.tokenConsumption,
                                style:
                                    RS.label(size: 14, color: RS.grey)),
                            const Spacer(),
                            Text(
                              cost != null
                                  ? '${cost.sp.toStringAsFixed(0)} SP + ${cost.gp.toStringAsFixed(0)} GP'
                                  : '---',
                              style: RS.label(size: 17),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('${S.shoeMintLabel}(親)',
                                style:
                                    RS.label(size: 13, color: RS.grey)),
                            const Spacer(),
                            Text(
                              '${parent.mintCount}/${GameConfig.mintMaxCount}'
                              '${partner != null ? '  ×  ${partner.mintCount}/${GameConfig.mintMaxCount}' : ''}',
                              style: RS.label(size: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 16, color: RS.mintDark),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '両親が同レアリティのとき、10%で1段上のレアリティが誕生',
                                style: RS.body(size: 12, color: RS.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  StepnButton(
                    label: S.mintButton,
                    fontSize: 20,
                    onTap: partner != null && canPay
                        ? () => _doMint(state, parent, partner)
                        : null,
                  ),
                  if (partner != null && !canPay)
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

  Future<void> _doMint(AppState state, Shoe parent, Shoe partner) async {
    final child = await state.mintShoes(parent, partner);
    if (child == null || !mounted) return;
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
              Text(S.mintDone,
                  textAlign: TextAlign.center, style: RS.label(size: 17)),
              const SizedBox(height: 16),
              SneakerArt(shoe: child, size: 150),
              const SizedBox(height: 8),
              PillBadge(
                text: child.displayName,
                color: RS.rarityColor(child.rarity),
                textColor: RS.white,
                fontSize: 13,
              ),
              const SizedBox(height: 6),
              Text(child.serialLabel,
                  style: RS.label(size: 12, color: RS.grey)),
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
    if (mounted) setState(() => partnerId = null);
  }

  void _showPartnerPicker(AppState state, Shoe parent) {
    final candidates = state.inventory.shoes
        .where((s) => s.id != parent.id && state.mint.canMint(s))
        .toList();
    String? selected = partnerId;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: RS.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final sel = state.inventory.byId(selected);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(S.matchingShoes, style: RS.label(size: 18)),
                const SizedBox(height: 16),
                if (candidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(S.noPartner,
                        textAlign: TextAlign.center,
                        style: RS.body(size: 13)),
                  )
                else ...[
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: candidates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final shoe = candidates[i];
                        final isSel = shoe.id == selected;
                        return Semantics(
                          label: '候補 ${shoe.displayName}',
                          button: true,
                          child: GestureDetector(
                          onTap: () =>
                              setSheetState(() => selected = shoe.id),
                          child: Container(
                            width: 96,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? RS.mint.withValues(alpha: 0.25)
                                  : RS.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: isSel
                                      ? RS.ink
                                      : const Color(0xFFDDDCD4),
                                  width: 2),
                            ),
                            child: Center(
                                child: SneakerArt(shoe: shoe, size: 80)),
                          ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  // 選択中シューズの情報
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F5EF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFDDDCD4)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoLine(
                                  label: S.idLabel,
                                  value: sel?.serialLabel ?? '-'),
                              const SizedBox(height: 10),
                              _InfoLine(
                                  label: S.classLabel,
                                  value: sel?.type.label ?? '-'),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoLine(
                                  label: S.levelLabel,
                                  value:
                                      sel != null ? 'Lv ${sel.level}' : '-'),
                              const SizedBox(height: 10),
                              _InfoLine(
                                  label: S.shoeMintLabel,
                                  value: sel != null
                                      ? '${sel.mintCount}/${GameConfig.mintMaxCount}'
                                      : '-'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                        label: S.confirm,
                        height: 48,
                        fontSize: 14,
                        onTap: selected == null
                            ? null
                            : () {
                                setState(() => partnerId = selected);
                                Navigator.of(sheetContext).pop();
                              },
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: MediaQuery.of(sheetContext).padding.bottom + 8),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PedestalSlot extends StatelessWidget {
  const _PedestalSlot({required this.shoe, required this.label, this.onTap});

  final Shoe? shoe;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: shoe == null ? label : null,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(label,
                overflow: TextOverflow.ellipsis,
                style: RS.label(size: 13, color: RS.purpleDeep)),
            const SizedBox(height: 4),
            SizedBox(
              height: 110,
              child: Center(
                child: shoe != null
                    ? SneakerArt(shoe: shoe!, size: 130)
                    : Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: RS.white.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: RS.grey,
                              width: 2,
                              strokeAlign: BorderSide.strokeAlignOutside),
                        ),
                        child: const Icon(Icons.add,
                            size: 40, color: RS.grey),
                      ),
              ),
            ),
            MintPedestal(
              mintCount: shoe?.mintCount ?? 0,
              maxMint: GameConfig.mintMaxCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RS.label(size: 11, color: RS.grey)),
        Text(value, style: RS.label(size: 14)),
      ],
    );
  }
}
