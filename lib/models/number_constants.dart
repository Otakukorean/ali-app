class NumberConstants {
  final int id;
  final int siteNumberId;
  final String ip;
  final String whatsapp;
  final String landline;
  final String? imagePath;

  const NumberConstants({
    required this.id,
    required this.siteNumberId,
    required this.ip,
    required this.whatsapp,
    required this.landline,
    this.imagePath,
  });

  factory NumberConstants.fromMap(Map<String, Object?> map) {
    return NumberConstants(
      id: map['id'] as int,
      siteNumberId: map['site_number_id'] as int,
      ip: map['ip'] as String,
      whatsapp: map['whatsapp'] as String,
      landline: map['landline'] as String,
      imagePath: map['image_path'] as String?,
    );
  }
}
