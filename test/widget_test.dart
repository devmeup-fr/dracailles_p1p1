import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:p1p1_dracailles/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('un booster fait 14 cartes, sans doublon', () async {
    final data = await SetData.load((await SetInfo.loadAll()).first);
    for (var i = 0; i < 300; i++) {
      final pack = data.openPack(Random(i));
      expect(pack.length, 14);
      expect(pack.map((p) => p.card.name).toSet().length, 14);
    }
  });
}
