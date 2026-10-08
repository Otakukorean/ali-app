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
    final dbPath = debugDatabasePathOverride ??
        p.join((await getApplicationSupportDirectory()).path, 'alghaif.db');

    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 4,
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
      CREATE TABLE constants_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        ip TEXT NOT NULL,
        image_path TEXT,
        created_at TEXT NOT NULL
      )
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
  }
}
