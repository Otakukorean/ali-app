class SiteNumber {
  final int id;
  final int siteId;
  final int sitePrefixId;
  final String number;
  final int sortOrder;

  const SiteNumber({
    required this.id,
    required this.siteId,
    required this.sitePrefixId,
    required this.number,
    required this.sortOrder,
  });

  factory SiteNumber.fromMap(Map<String, Object?> map) {
    return SiteNumber(
      id: map['id'] as int,
      siteId: map['site_id'] as int,
      sitePrefixId: map['site_prefix_id'] as int,
      number: map['number'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }
}
