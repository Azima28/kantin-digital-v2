/// Data model untuk tabel `classes`.
class SchoolClass {
  final String id;
  final String name;
  final int level;

  const SchoolClass({
    required this.id,
    required this.name,
    this.level = 0,
  });

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    return SchoolClass(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
      level: json['level'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
      };

  @override
  String toString() => 'SchoolClass(id: $id, name: $name, level: $level)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolClass && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
