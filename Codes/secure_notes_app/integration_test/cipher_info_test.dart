import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:secure_notes_app/services/database_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Cipher Info', () {
    testWidgets('Get SQLCipher settings', (tester) async {
      final db = DatabaseService.instance;
      final database = await db.database;

      final version = await database.rawQuery('PRAGMA cipher_version');
      final pageSize = await database.rawQuery('PRAGMA cipher_page_size');
      final kdfIter = await database.rawQuery('PRAGMA kdf_iter');
      final memory = await database.rawQuery('PRAGMA cipher_memory_security');
      final saltLength = await database.rawQuery('PRAGMA cipher_salt_length');
      final ivLength = await database.rawQuery('PRAGMA cipher_iv_length');
      final keyLength = await database.rawQuery('PRAGMA cipher_key_length');

      print('');
      print('=========================================');
      print('   SQLCIPHER EXACT SETTINGS');
      print('=========================================');
      print('cipher_version   : ${version.first.values.first}');
      print('cipher_page_size : ${pageSize.first.values.first}');
      print('kdf_iter         : ${kdfIter.first.values.first}');
      print('memory_security  : ${memory.isNotEmpty ? memory.first.values.first : "N/A"}');
      print('salt_length      : ${saltLength.isNotEmpty ? saltLength.first.values.first : "N/A"}');
      print('iv_length        : ${ivLength.isNotEmpty ? ivLength.first.values.first : "N/A"}');
      print('key_length       : ${keyLength.isNotEmpty ? keyLength.first.values.first : "N/A"}');
      print('=========================================');

      expect(version, isNotEmpty);
    });
  });
}