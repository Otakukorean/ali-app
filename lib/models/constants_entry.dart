class ConstantsEntry {
  final int id;
  final String name;
  final String phone;
  final String ip;
  final String? imagePath;

  const ConstantsEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.ip,
    this.imagePath,
  });

  factory ConstantsEntry.fromMap(Map<String, Object?> map) {
    return ConstantsEntry(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      ip: map['ip'] as String,
      imagePath: map['image_path'] as String?,
    );
  }
}
