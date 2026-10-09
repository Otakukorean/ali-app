import '../core/db/database_helper.dart';
import '../core/storage/image_storage.dart';
import '../models/constants_entry.dart';
import '../models/number_constants.dart';

class ConstantsService {
  ConstantsService._();

  static final ConstantsService instance = ConstantsService._();

  Future<List<ConstantsEntry>> getEntries({int? siteNumberId}) async {
    final db = await DatabaseHelper.instance.database;
    final isNumberView = siteNumberId != null;
    final rows = await db.rawQuery('''
      SELECT constants_entries.*, sites.name AS site_name
      FROM constants_entries
      LEFT JOIN sites ON sites.id = constants_entries.site_id
      ${isNumberView ? 'WHERE constants_entries.site_number_id = ?' : ''}
      ORDER BY constants_entries.id DESC
      ''', isNumberView ? [siteNumberId] : null);
    return rows.map(ConstantsEntry.fromMap).toList();
  }

  Future<void> addEntry({
    required String name,
    required String phone,
    required String ip,
    required int siteId,
    required int siteNumberId,
    required String number,
    String? sourceImagePath,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final storedImagePath = sourceImagePath == null
        ? null
        : await ImageStorage.copyToAppStorage(
            sourceImagePath,
            subfolder: 'images',
          );

    await db.insert('constants_entries', {
      'name': name.trim(),
      'phone': phone.trim(),
      'ip': ip.trim(),
      'image_path': storedImagePath,
      'site_id': siteId,
      'site_number_id': siteNumberId,
      'number': number,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateEntry({
    required int id,
    required String name,
    required String phone,
    required String ip,
    String? sourceImagePath,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final values = <String, Object?>{
      'name': name.trim(),
      'phone': phone.trim(),
      'ip': ip.trim(),
    };
    if (sourceImagePath != null) {
      values['image_path'] = await ImageStorage.copyToAppStorage(
        sourceImagePath,
        subfolder: 'images',
      );
    }
    await db.update(
      'constants_entries',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<NumberConstants> getNumberConstants(int siteNumberId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'number_constants',
      where: 'site_number_id = ?',
      whereArgs: [siteNumberId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Constants are missing for site number $siteNumberId');
    }
    return NumberConstants.fromMap(rows.first);
  }

  Future<void> updateNumberConstants({
    required int id,
    required String ip,
    required String whatsapp,
    required String landline,
    String? sourceImagePath,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final values = <String, Object?>{
      'ip': ip.trim(),
      'whatsapp': whatsapp.trim(),
      'landline': landline.trim(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (sourceImagePath != null) {
      values['image_path'] = await ImageStorage.copyToAppStorage(
        sourceImagePath,
        subfolder: 'number_constants',
      );
    }
    await db.update(
      'number_constants',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteEntry(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('constants_entries', where: 'id = ?', whereArgs: [id]);
  }
}
