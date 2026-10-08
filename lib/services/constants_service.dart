import '../core/db/database_helper.dart';
import '../core/storage/image_storage.dart';
import '../models/constants_entry.dart';

class ConstantsService {
  ConstantsService._();

  static final ConstantsService instance = ConstantsService._();

  Future<List<ConstantsEntry>> getEntries() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('constants_entries', orderBy: 'id DESC');
    return rows.map(ConstantsEntry.fromMap).toList();
  }

  Future<void> addEntry({
    required String name,
    required String phone,
    required String ip,
    String? sourceImagePath,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final storedImagePath = sourceImagePath == null
        ? null
        : await ImageStorage.copyToAppStorage(sourceImagePath, subfolder: 'images');

    await db.insert('constants_entries', {
      'name': name.trim(),
      'phone': phone.trim(),
      'ip': ip.trim(),
      'image_path': storedImagePath,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteEntry(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('constants_entries', where: 'id = ?', whereArgs: [id]);
  }
}
