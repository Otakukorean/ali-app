class ConstantsEntry {
  final int id;
  final String name;
  final String phone;
  final String ip;
  final String? imagePath;
  final int? siteId;
  final int? siteNumberId;
  final String? siteName;
  final String? number;

  const ConstantsEntry({
    required this.id,
    required this.name,
    required this.phone,
    required this.ip,
    this.imagePath,
    this.siteId,
    this.siteNumberId,
    this.siteName,
    this.number,
  });

  factory ConstantsEntry.fromMap(Map<String, Object?> map) {
    return ConstantsEntry(
      id: map['id'] as int,
      name: map['name'] as String,
      phone: map['phone'] as String,
      ip: map['ip'] as String,
      imagePath: map['image_path'] as String?,
      siteId: map['site_id'] as int?,
      siteNumberId: map['site_number_id'] as int?,
      siteName: map['site_name'] as String?,
      number: map['number'] as String?,
    );
  }
}
