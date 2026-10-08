enum UserRole { admin, superAdmin }

extension UserRoleX on UserRole {
  String get dbValue => this == UserRole.superAdmin ? 'superadmin' : 'admin';

  String get labelAr => this == UserRole.superAdmin ? 'مشرف عام' : 'مشرف';

  static UserRole fromDb(String value) {
    return value == 'superadmin' ? UserRole.superAdmin : UserRole.admin;
  }
}
