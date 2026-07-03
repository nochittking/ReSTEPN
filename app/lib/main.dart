import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/strings_ja.dart';
import 'screens/home_screen.dart';
import 'state/app_state.dart';

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E9B6C)),
          useMaterial3: true,
          fontFamily: 'NotoSansJP',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2FBF8B),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'NotoSansJP',
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
