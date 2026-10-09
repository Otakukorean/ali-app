import '../core/db/database_helper.dart';
import '../core/security/password_hasher.dart';
import '../core/storage/image_storage.dart';
import '../models/app_user.dart';

class UsernameTakenException implements Exception {}

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  Future<List<AppUser>> getAdmins() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['admin'],
      orderBy: 'username ASC',
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<void> addAdmin(
    String username,
    String password, {
    String? sourceImagePath,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final salt = PasswordHasher.generateSalt();
    final hash = PasswordHasher.hash(password, salt);
    final storedImagePath = sourceImagePath == null
        ? null
        : await ImageStorage.copyToAppStorage(
            sourceImagePath,
            subfolder: 'avatars',
          );

    try {
      await db.insert('users', {
        'username': username.trim(),
        'password_hash': hash,
        'password_salt': salt,
        'role': 'admin',
        'image_path': storedImagePath,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on Exception catch (e) {
      if (e.toString().contains('UNIQUE')) throw UsernameTakenException();
      rethrow;
    }
  }

  Future<void> updateAdmin(
    int id, {
    required String username,
    String? password,
    String? sourceImagePath,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final values = <String, Object?>{'username': username.trim()};

    if (password != null && password.isNotEmpty) {
      final salt = PasswordHasher.generateSalt();
      values['password_salt'] = salt;
      values['password_hash'] = PasswordHasher.hash(password, salt);
    }

    if (sourceImagePath != null) {
      values['image_path'] = await ImageStorage.copyToAppStorage(
        sourceImagePath,
        subfolder: 'avatars',
      );
    }

    try {
      await db.update('users', values, where: 'id = ?', whereArgs: [id]);
    } on Exception catch (e) {
      if (e.toString().contains('UNIQUE')) throw UsernameTakenException();
      rethrow;
    }
  }

  Future<void> deleteAdmin(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
