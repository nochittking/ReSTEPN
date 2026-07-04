import 'package:flutter/material.dart';

import '../models/shoe.dart';
import '../theme/restep_theme.dart';
import '../widgets/sneaker_art.dart';

/// 開発用: 全タイプ×レアリティのシューズ描画を一覧確認する画面。
/// リリースビルドには含めない(main.dartからは通常参照しない)。
class GalleryDebug extends StatelessWidget {
  const GalleryDebug({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RS.cream,
      appBar: AppBar(title: const Text('Sneaker Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final type in ShoeType.values) ...[
            Text(type.label, style: RS.label(size: 16)),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final rarity in Rarity.values)
                  Expanded(
                    child: Column(
                      children: [
                        SneakerArt(
                          shoe: Shoe(
                            id: '${type.name}-${rarity.name}',
                            type: type,
                            rarity: rarity,
                            serial: type.index * 100 + rarity.index * 7 + 3,
                          ),
                          size: 78,
                        ),
                        Text(rarity.label,
                            style: RS.body(size: 9, color: RS.grey)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
