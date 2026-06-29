/// Data model untuk tabel `rombels`.
class SchoolRombel {
  final String id;
  final String name;

  const SchoolRombel({
    required this.id,
    required this.name,
  });

  factory SchoolRombel.fromJson(Map<String, dynamic> json) {
    return SchoolRombel(
      id: json['id'] as String,
      name: (json['name'] ?? '') as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  @override
  String toString() => 'SchoolRombel(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolRombel && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
