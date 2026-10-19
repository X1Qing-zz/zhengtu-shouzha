import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhengtu_shouzha/data/settings_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('future messages', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds, trims and de-duplicates messages', () async {
      final settings = await SettingsStore.create();
      await settings.addFutureMessage('  别怕，你已经在路上了。  ');
      await settings.addFutureMessage('别怕，你已经在路上了。');
      expect(settings.futureMessages, ['别怕，你已经在路上了。']);
    });

    test('is included in backup export and restored', () async {
      final settings = await SettingsStore.create();
      await settings.addFutureMessage('给未来的一句话');
      final exported = settings.exportForBackup();
      expect(exported['future_messages'], ['给未来的一句话']);

      await settings.replaceFutureMessages([]);
      expect(settings.futureMessages, isEmpty);

      await settings.importFromBackup(exported);
      expect(settings.futureMessages, ['给未来的一句话']);
    });
  });
}
