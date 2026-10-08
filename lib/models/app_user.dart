import 'user_role.dart';

class AppUser {
  final int id;
  final String username;
  final UserRole role;
  final String? imagePath;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    this.imagePath,
  });

  factory AppUser.fromMap(Map<String, Object?> map) {
    return AppUser(
      id: map['id'] as int,
      username: map['username'] as String,
      role: UserRoleX.fromDb(map['role'] as String),
      imagePath: map['image_path'] as String?,
    );
  }
}
