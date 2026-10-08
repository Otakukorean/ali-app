class SitePrefix {
  final int id;
  final int siteId;
  final String prefix;
  final int sortOrder;

  const SitePrefix({
    required this.id,
    required this.siteId,
    required this.prefix,
    required this.sortOrder,
  });

  factory SitePrefix.fromMap(Map<String, Object?> map) {
    return SitePrefix(
      id: map['id'] as int,
      siteId: map['site_id'] as int,
      prefix: map['prefix'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }
}
