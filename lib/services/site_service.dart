import '../core/db/database_helper.dart';
import '../models/site.dart';
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
}
