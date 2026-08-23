import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../models/gem.dart';
import '../models/move_session.dart';
import '../models/mystery_box.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/gem_art.dart';
import '../widgets/graffiti_background.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';
import 'history_screen.dart';
import 'move_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.99);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '$h時間${m.toString().padLeft(2, '0')}分';
  }

  Future<void> _startCountdownAndMove(AppState state) async {
    // 3-2-1カウントダウンオーバーレイ
    for (var i = 3; i >= 1; i--) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.75),
        builder: (_) => Center(
          child: Text('$i', style: RS.number(size: 140, color: RS.mint)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;
    state.startMove();
    if (state.isMoving) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MoveScreen()),
      );
    }
  }

  Future<void> _openBox(AppState state, MysteryBox box) async {
    final gem = await state.openBox(box);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _GemRevealDialog(gem: gem),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final shoes = state.inventory.shoes;
    final cap = state.inventory.energyCap;
    final energy = state.energyManager.energy;

    return Container(
      color: RS.cream,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 上部ラベンダーエリア
          Container(
            decoration: const BoxDecoration(
              color: RS.lavender,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(state: state),
                  const SizedBox(height: 14),

                  // シューズヒーローカード(スワイプ切替)
                  SizedBox(
                    height: 300,
                    child: shoes.isEmpty
                        ? StepnCard(
                            child: Center(
                                child:
                                    Text(S.noShoes, style: RS.body(size: 14))))
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: shoes.length,
                            onPageChanged: (i) =>
                                state.selectShoe(shoes[i].id),
                            itemBuilder: (context, i) =>
                                _HeroShoeCard(state: state, index: i),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // ミステリーボックス4スロット
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        Expanded(
                          child: _BoxSlot(
                            box: i < state.boxes.length
                                ? state.boxes[i]
                                : null,
                            onOpen: (box) => _openBox(state, box),
                          ),
                        ),
                        if (i < 3) const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 下部クリームエリア
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            child: Column(
              children: [
                // デイリー獲得ゲージ
                ProgressPill(
                  leading: const Icon(Icons.directions_walk, size: 20),
                  text:
                      '${state.dailyEarnedSp.toStringAsFixed(2)}/${'1000'}',
                  trailing: 'デイリーSP',
                  progress: state.dailyEarnedSp / 1000,
                  fillColor: RS.orange,
                ),
                const SizedBox(height: 12),

                // エナジーピル
                ProgressPill(
                  leading:
                      const Icon(Icons.bolt, size: 20, color: Color(0xFF3F9BE0)),
                  text:
                      '${energy.toStringAsFixed(1)}/${cap.toStringAsFixed(1)}',
                  trailing:
                      '${S.refillIn} ${_fmtDuration(state.timeToNextRefill())}',
                  progress: cap == 0 ? 0 : energy / cap,
                  background: const Color(0xFFDCEBFA),
                ),
                const SizedBox(height: 12),

                // 復帰ボーナスの予告(しばらく走っていないときだけ出る)
                if (state.hasComebackBonus) ...[
                  _ComebackNotice(days: state.comebackGapDays),
                  const SizedBox(height: 12),
                ],

                // 報酬モード選択(SP/GP排他)
                Row(
                  children: [
                    for (final mode in EarnMode.values) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => state.selectMode(mode),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: state.selectedMode == mode
                                  ? RS.mint
                                  : RS.white,
                              borderRadius: BorderRadius.circular(999),
                              border:
                                  Border.all(color: RS.ink, width: 1.6),
                            ),
                            child: Center(
                              child: Text('${mode.code}モード',
                                  style: RS.label(size: 13)),
                            ),
                          ),
                        ),
                      ),
                      if (mode != EarnMode.values.last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                SwitchListTile(
                  title: Text(S.simulationMode, style: RS.body(size: 13)),
                  value: state.simulationMode,
                  activeThumbColor: RS.mintDark,
                  onChanged: state.setSimulationMode,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

                if (state.energyManager.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(S.noEnergy,
                        style: RS.body(size: 12, color: RS.red)),
                  ),
                const SizedBox(height: 6),

                // STARTボタン
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: RS.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDBDAD1)),
                      ),
                      child: const Icon(Icons.music_note,
                          color: RS.purpleDeep, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: StepnButton(
                        label: S.start,
                        fontSize: 24,
                        height: 64,
                        onTap: state.canStart
                            ? () => _startCountdownAndMove(state)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 66),
                  ],
                ),
                const SizedBox(height: 14),
                Text(S.howToPlay,
                    style: RS.label(size: 14).copyWith(
                        decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 上部バー: アバター+累計km / SP・GP残高ピル
/// 復帰ボーナスの予告。しばらく走っていないときだけホームに出る。
/// 「サボった」ではなく「戻ってきた」ことを歓迎する文面にする。
class _ComebackNotice extends StatelessWidget {
  const _ComebackNotice({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: RS.orange.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: RS.orange, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, size: 20, color: RS.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S.comebackReady(days),
              style: RS.label(size: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
      GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
        ),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: RS.white,
                shape: BoxShape.circle,
                border: Border.all(color: RS.ink, width: 2),
              ),
              child: const Icon(Icons.directions_run,
                  color: RS.ink, size: 28),
            ),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: RS.yellow,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: RS.ink, width: 1.4),
              ),
              child: Text('${state.totalKm.toStringAsFixed(0)}km',
                  style: RS.label(size: 11)),
            ),
          ],
        ),
      ),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB99A2E), width: 2),
              ),
              child: Center(
                  child: Text('G',
                      style: RS.label(size: 9, color: const Color(0xFFB99A2E)))),
            ),
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

/// シューズヒーローカード(ダークグラフィティ背景)
class _HeroShoeCard extends StatelessWidget {
  const _HeroShoeCard({required this.state, required this.index});

  final AppState state;
  final int index;

  @override
  Widget build(BuildContext context) {
    final shoe = state.inventory.shoes[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: RS.border, width: 3),
        boxShadow: const [
          BoxShadow(color: RS.border, offset: Offset(0, 5), blurRadius: 0),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(child: GraffitiBackground()),
            // タイプピル(上部中央)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 7),
                  decoration: BoxDecoration(
                    color: RS.purpleDeep,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_walk,
                          color: RS.white, size: 15),
                      const SizedBox(width: 6),
                      Text(shoe.type.label,
                          style: RS.label(size: 15, color: RS.white)),
                    ],
                  ),
                ),
              ),
            ),
            Center(
                child: SneakerArt(
                    shoe: shoe,
                    size: 220,
                    skin: state.equippedSkinOf(shoe.id))),
            // 下部ピル: #ID / 耐久 / Lv
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PillBadge(
                    text: shoe.serialLabel,
                    color: RS.purpleDeep.withValues(alpha: 0.9),
                    textColor: RS.white,
                    borderColor: RS.white,
                    fontSize: 12,
                  ),
                  PillBadge(
                    text:
                        '${shoe.durability.toStringAsFixed(1)}/100.0',
                    color: RS.mint,
                    fontSize: 12,
                  ),
                  PillBadge(
                    text: 'Lv ${shoe.level}',
                    color: RS.white,
                    textColor: RS.purpleDeep,
                    fontSize: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ミステリーボックスのスロット
class _BoxSlot extends StatelessWidget {
  const _BoxSlot({required this.box, required this.onOpen});

  final MysteryBox? box;
  final void Function(MysteryBox) onOpen;

  @override
  Widget build(BuildContext context) {
    if (box == null) {
      return Container(
        height: 92,
        decoration: BoxDecoration(
          color: RS.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(S.lootBox,
              textAlign: TextAlign.center,
              style: RS.label(size: 11, color: RS.grey)),
        ),
      );
    }
    return GestureDetector(
      onTap: () => onOpen(box!),
      child: Container(
        height: 92,
        decoration: BoxDecoration(
          color: RS.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RS.ink, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2, color: RS.orange, size: 34),
            const SizedBox(height: 4),
            Text(S.openNow,
                style: RS.label(size: 11, color: RS.mintDark)),
          ],
        ),
      ),
    );
  }
}

/// ボックス開封→ジェム入手ダイアログ
class _GemRevealDialog extends StatelessWidget {
  const _GemRevealDialog({required this.gem});

  final Gem gem;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: RS.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(S.gemObtained, style: RS.label(size: 18)),
            const SizedBox(height: 20),
            GemArt(type: gem.type, level: gem.level, size: 90),
            const SizedBox(height: 16),
            Text(gem.displayName, style: RS.label(size: 15)),
            const SizedBox(height: 24),
            StepnButton(
              label: 'OK',
              height: 48,
              fontSize: 16,
              width: 160,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
