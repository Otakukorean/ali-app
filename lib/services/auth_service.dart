import '../core/db/database_helper.dart';
import '../core/security/password_hasher.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  AppUser? currentUser;

  Future<AppUser?> login(String username, String password) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final row = rows.first;
    final salt = row['password_salt'] as String;
    final expectedHash = row['password_hash'] as String;

    if (!PasswordHasher.verify(password, salt, expectedHash)) {
      return null;
    }

    final user = AppUser.fromMap(row);
    currentUser = user;
    return user;
  }

  void logout() {
    currentUser = null;
  }
}
