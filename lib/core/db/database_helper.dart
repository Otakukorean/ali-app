import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common/utils/utils.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../security/password_hasher.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  static const String defaultSuperAdminUsername = 'superadmin';
  static const String defaultSuperAdminPassword = 'admin123';
  static const List<String> defaultSitePrefixes = ['111', '113', '100', '115'];

  /// Overrides the on-disk database path. Used by widget tests, which have
  /// no real path_provider platform channel to resolve a support directory.
  @visibleForTesting
  static String? debugDatabasePathOverride;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final db = await _open();
    _database = db;
    return db;
  }

  Future<Database> _open() async {
    final dbPath =
        debugDatabasePathOverride ??
        p.join((await getApplicationSupportDirectory()).path, 'alghaif.db');

    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 8,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    await _seedIfNeeded(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        role TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE site_prefixes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_id INTEGER NOT NULL,
        prefix TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE site_numbers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_id INTEGER NOT NULL,
        site_prefix_id INTEGER NOT NULL,
        number TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        UNIQUE (site_id, number),
        FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE,
        FOREIGN KEY (site_prefix_id) REFERENCES site_prefixes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX site_numbers_prefix_idx
      ON site_numbers (site_prefix_id, sort_order)
    ''');

    await db.execute('''
      CREATE TABLE number_constants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        site_number_id INTEGER NOT NULL UNIQUE,
        ip TEXT NOT NULL,
        whatsapp TEXT NOT NULL,
        landline TEXT NOT NULL,
        image_path TEXT,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (site_number_id) REFERENCES site_numbers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE constants_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        ip TEXT NOT NULL,
        image_path TEXT,
        site_id INTEGER,
        site_number_id INTEGER,
        number TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE,
        FOREIGN KEY (site_number_id) REFERENCES site_numbers(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX constants_entries_site_number_idx
      ON constants_entries (site_id, number)
    ''');

    await db.execute('''
      CREATE INDEX constants_entries_number_id_idx
      ON constants_entries (site_number_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS constants_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          ip TEXT NOT NULL,
          image_path TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS site_prefixes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          site_id INTEGER NOT NULL,
          prefix TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
        )
      ''');

      final existingSites = await db.query('sites');
      for (final site in existingSites) {
        final siteId = site['id'] as int;
        final legacyPrefix = site['prefix'] as String?;

        final prefixes = <String>[
          ?legacyPrefix,
          for (final prefix in defaultSitePrefixes)
            if (prefix != legacyPrefix) prefix,
        ];

        for (var i = 0; i < prefixes.length; i++) {
          await db.insert('site_prefixes', {
            'site_id': siteId,
            'prefix': prefixes[i],
            'sort_order': i + 1,
          });
        }
      }
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE constants_entries ADD COLUMN site_id INTEGER',
      );
      await db.execute('ALTER TABLE constants_entries ADD COLUMN number TEXT');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS constants_entries_site_number_idx
        ON constants_entries (site_id, number)
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS site_numbers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          site_id INTEGER NOT NULL,
          site_prefix_id INTEGER NOT NULL,
          number TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          UNIQUE (site_id, number),
          FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE,
          FOREIGN KEY (site_prefix_id) REFERENCES site_prefixes(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS site_numbers_prefix_idx
        ON site_numbers (site_prefix_id, sort_order)
      ''');
      await _seedSiteNumbers(db);
      await db.execute(
        'ALTER TABLE constants_entries ADD COLUMN site_number_id INTEGER',
      );
      await db.execute('''
        UPDATE constants_entries
        SET site_number_id = (
          SELECT site_numbers.id
          FROM site_numbers
          WHERE site_numbers.site_id = constants_entries.site_id
            AND site_numbers.number = constants_entries.number
          LIMIT 1
        )
        WHERE site_id IS NOT NULL AND number IS NOT NULL
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS constants_entries_number_id_idx
        ON constants_entries (site_number_id)
      ''');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS number_constants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          site_number_id INTEGER NOT NULL UNIQUE,
          ip TEXT NOT NULL,
          whatsapp TEXT NOT NULL,
          landline TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (site_number_id) REFERENCES site_numbers(id) ON DELETE CASCADE
        )
      ''');
      await _seedNumberConstants(db);
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE number_constants ADD COLUMN image_path TEXT',
      );
    }
  }

  Future<void> _seedIfNeeded(Database db) async {
    final userCount = firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );
    if (userCount == 0) {
      final salt = PasswordHasher.generateSalt();
      final hash = PasswordHasher.hash(defaultSuperAdminPassword, salt);
      await db.insert('users', {
        'username': defaultSuperAdminUsername,
        'password_hash': hash,
        'password_salt': salt,
        'role': 'superadmin',
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    final siteCount = firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM sites'),
    );
    if (siteCount == 0) {
      const sites = ['الكرار', 'الأمين', 'المفيد'];
      for (var i = 0; i < sites.length; i++) {
        final siteId = await db.insert('sites', {
          'name': sites[i],
          'sort_order': i + 1,
        });

        for (var j = 0; j < defaultSitePrefixes.length; j++) {
          await db.insert('site_prefixes', {
            'site_id': siteId,
            'prefix': defaultSitePrefixes[j],
            'sort_order': j + 1,
          });
        }
      }
    }

    await _seedSiteNumbers(db);
    await _seedNumberConstants(db);
  }

  Future<void> _seedSiteNumbers(Database db) async {
    final prefixes = await db.query(
      'site_prefixes',
      columns: ['id', 'site_id', 'prefix'],
    );
    final batch = db.batch();
    for (final prefix in prefixes) {
      final prefixId = prefix['id'] as int;
      final siteId = prefix['site_id'] as int;
      final prefixValue = prefix['prefix'] as String;
      final existingCount = firstIntValue(
        await db.rawQuery(
          'SELECT COUNT(*) FROM site_numbers WHERE site_prefix_id = ?',
          [prefixId],
        ),
      );
      if (existingCount == 100) continue;
      for (var suffix = 0; suffix < 100; suffix++) {
        batch.insert('site_numbers', {
          'site_id': siteId,
          'site_prefix_id': prefixId,
          'number': '$prefixValue${suffix.toString().padLeft(2, '0')}',
          'sort_order': suffix,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
    await batch.commit(noResult: true);
  }

  Future<void> _seedNumberConstants(Database db) async {
    await db.rawInsert(
      '''
      INSERT OR IGNORE INTO number_constants (
        site_number_id,
        ip,
        whatsapp,
        landline,
        updated_at
      )
      SELECT id, ?, ?, ?, ? FROM site_numbers
      ''',
      [
        '192.168.1.10',
        '+964 770 123 4567',
        '07701234567',
        DateTime.now().toIso8601String(),
      ],
    );
  }
}
