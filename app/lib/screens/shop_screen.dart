import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings_ja.dart';
import '../state/app_state.dart';
import '../theme/restep_theme.dart';
import '../widgets/sneaker_art.dart';
import '../widgets/stepn_button.dart';

/// ショップ(マーケットプレイス風)。SP払いでシューズを購入する。
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: RS.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: RS.ink, width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(S.lowestPrice, style: RS.label(size: 13)),
                      const Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: state.refreshShop,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: RS.mint,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: RS.ink, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.refresh, size: 16),
                        const SizedBox(width: 4),
                        Text(S.shopRefresh, style: RS.label(size: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.directions_walk, size: 18),
                const SizedBox(width: 4),
                Text(state.spBalance.toStringAsFixed(2),
                    style: RS.label(size: 15)),
                const SizedBox(width: 6),
                Text('SP', style: RS.label(size: 12, color: RS.grey)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              itemCount: state.shopCatalog.length,
              itemBuilder: (context, i) {
                final listing = state.shopCatalog[i];
                final shoe = listing.shoe;
                final affordable = state.spBalance >= listing.priceSp;
                return StepnCard(
                  padding: EdgeInsets.zero,
                  radius: 24,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9E8E1),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(21)),
                        ),
                        child: Center(
                          child: Text(
                            '${shoe.type.label}  ${shoe.type.rangeLabel}',
                            style: RS.label(size: 11.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Center(
                                child: SneakerArt(shoe: shoe, size: 115)),
                            if (listing.onSale)
                              Positioned(
                                top: 6,
                                left: 8,
                                child: PillBadge(
                                  text: S.sale,
                                  color: RS.red,
                                  textColor: RS.white,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      PillBadge(
                        text: shoe.serialLabel,
                        color: RS.white,
                        textColor: RS.rarityColor(shoe.rarity),
                        borderColor: RS.rarityColor(shoe.rarity),
                        fontSize: 11,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${S.mintLabel}: ${shoe.mintCount}',
                                style: RS.label(size: 11)),
                            Text('Lv ${shoe.level}',
                                style: RS.label(size: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: listing.onSale
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          listing.originalPriceSp
                                              .toStringAsFixed(0),
                                          style: RS
                                              .body(
                                                  size: 11,
                                                  color: RS.grey)
                                              .copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough),
                                        ),
                                        Text(
                                          listing.priceSp
                                              .toStringAsFixed(0),
                                          style: RS.number(
                                              size: 18, color: RS.red),
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      listing.priceSp.toStringAsFixed(0),
                                      style: RS.number(size: 20),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                            StepnButton(
                              label: S.buy,
                              height: 38,
                              width: 84,
                              fontSize: 13,
                              onTap: affordable
                                  ? () async {
                                      final ok =
                                          await state.buyShoe(listing);
                                      if (ok && context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text(
                                                    '${shoe.displayName} ${S.bought}')));
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
