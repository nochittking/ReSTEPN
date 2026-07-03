import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/strings_ja.dart';
import 'screens/home_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/shoes_tab.dart';
import 'screens/shop_screen.dart';
import 'state/app_state.dart';
import 'theme/restep_theme.dart';

void main() {
  runApp(const ReStepApp());
}

class ReStepApp extends StatelessWidget {
  const ReStepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: MaterialApp(
        title: S.appTitle,
        debugShowCheckedModeBanner: false,
        theme: RS.theme(),
        home: const MainShell(),
      ),
    );
  }
}

/// 下部4タブのメインシェル(ムーブ/シューズ/ランキング/ショップ)。
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    ShoesTab(),
    RankingScreen(),
    ShopScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final loaded = context.select<AppState, bool>((s) => s.loaded);
    if (!loaded) {
      return const Scaffold(
        backgroundColor: RS.cream,
        body: Center(child: CircularProgressIndicator(color: RS.mintDark)),
      );
    }

    return Scaffold(
      backgroundColor: RS.cream,
      body: IndexedStack(index: _index, children: _tabs),
      extendBody: true,
      bottomNavigationBar: _BottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _icons = [
    Icons.directions_run,
    Icons.electric_bolt,
    Icons.emoji_events_outlined,
    Icons.shopping_cart_outlined,
  ];
  static const _labels = [S.tabMove, S.tabShoes, S.tabRanking, S.tabShop];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: const Color(0xFFEDECE4).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFDBDAD1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Semantics(
                    label: _labels[i],
                    button: true,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: index == i ? RS.mint : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Icon(_icons[i], color: RS.ink, size: 26),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
