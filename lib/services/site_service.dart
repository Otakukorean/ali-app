import '../core/db/database_helper.dart';
import '../models/site.dart';
import '../models/site_number.dart';
import '../models/site_prefix.dart';

class SiteService {
  SiteService._();

  static final SiteService instance = SiteService._();

  Future<List<Site>> getSites() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sites', orderBy: 'sort_order ASC');
    return rows.map(Site.fromMap).toList();
  }

  Future<List<SitePrefix>> getPrefixesForSite(int siteId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'site_prefixes',
      where: 'site_id = ?',
      whereArgs: [siteId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(SitePrefix.fromMap).toList();
  }

  Future<List<SiteNumber>> getNumbersForPrefix(int sitePrefixId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'site_numbers',
      where: 'site_prefix_id = ?',
      whereArgs: [sitePrefixId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(SiteNumber.fromMap).toList();
  }

  Future<SiteNumber?> findNumberForSite(int siteId, String number) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'site_numbers',
      where: 'site_id = ? AND number = ?',
      whereArgs: [siteId, number],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SiteNumber.fromMap(rows.first);
  }
}
