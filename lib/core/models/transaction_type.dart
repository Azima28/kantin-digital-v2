/// Data model untuk tabel `transaction_types`.
class TransactionType {
  final String id;
  final String name;
  final String? description;
  final String? type;
  final DateTime? createdAt;

  const TransactionType({
    required this.id,
    required this.name,
    this.description,
    this.type,
    this.createdAt,
  });

  factory TransactionType.fromJson(Map<String, dynamic> json) {
    return TransactionType(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type,
        'created_at': createdAt?.toIso8601String(),
      };

  TransactionType copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    DateTime? createdAt,
  }) {
    return TransactionType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'TransactionType(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransactionType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
