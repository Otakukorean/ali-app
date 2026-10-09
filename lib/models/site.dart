class Site {
  final int id;
  final String name;
  final int sortOrder;

  const Site({required this.id, required this.name, required this.sortOrder});

  factory Site.fromMap(Map<String, Object?> map) {
    return Site(
      id: map['id'] as int,
      name: map['name'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }
}
