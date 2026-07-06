import 'package:flutter_test/flutter_test.dart';
import 'package:restep_mvp/models/skin.dart';
import 'package:restep_mvp/models/shoe.dart';
import 'package:restep_mvp/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('スキン装着/解除', () {
    test('初回ロードでスターター・スキンが配布される', () async {
      final state = AppState();
      await state.load();
      expect(state.skins, isNotEmpty);
      // 全て未装着で始まる
      expect(state.unequippedSkins.length, state.skins.length);
    });

    test('装着すると対象靴に紐付き、未装着一覧から外れる', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      final skin = state.skins.first;
      await state.equipSkin(shoe.id, skin);
      expect(state.equippedSkinOf(shoe.id), skin);
      expect(state.unequippedSkins, isNot(contains(skin)));
    });

    test('同じ靴に別スキンを装着すると前のスキンは自動で外れる', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      final first = state.skins[0];
      final second = state.skins[1];
      await state.equipSkin(shoe.id, first);
      await state.equipSkin(shoe.id, second);
      expect(state.equippedSkinOf(shoe.id), second);
      expect(first.equippedShoeId, isNull); // 外れて再利用可能
      expect(state.unequippedSkins, contains(first));
    });

    test('解除すると靴の見た目は元に戻り、スキンは再利用できる', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      final skin = state.skins.first;
      await state.equipSkin(shoe.id, skin);
      await state.unequipSkin(skin);
      expect(state.equippedSkinOf(shoe.id), isNull);
      expect(skin.equippedShoeId, isNull);
      expect(state.unequippedSkins, contains(skin));
    });

    test('装着状態は保存・復元される', () async {
      final state = AppState();
      await state.load();
      final shoe = state.inventory.shoes.first;
      final skin = state.skins.first;
      await state.equipSkin(shoe.id, skin);
      final equippedId = skin.id;

      // 別インスタンスで再ロード
      final restored = AppState();
      await restored.load();
      final restoredSkin =
          restored.skins.firstWhere((s) => s.id == equippedId);
      expect(restoredSkin.equippedShoeId, shoe.id);
    });
  });

  group('スキンのJSON', () {
    test('往復で内容が保たれる', () {
      final skin = Skin(
        id: 'x',
        name: 'テスト',
        visualType: ShoeType.runner,
        paletteRarity: Rarity.epic,
        seed: 12345,
        equippedShoeId: 'shoe-1',
      );
      final round = Skin.fromJson(skin.toJson());
      expect(round.id, 'x');
      expect(round.name, 'テスト');
      expect(round.visualType, ShoeType.runner);
      expect(round.paletteRarity, Rarity.epic);
      expect(round.seed, 12345);
      expect(round.equippedShoeId, 'shoe-1');
    });
  });
}
