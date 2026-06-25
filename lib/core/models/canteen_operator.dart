/// Data model untuk tabel `canteen_operators`.
///
/// Merepresentasikan data operator/pemilik stan kantin.
class CanteenOperator {
  final String id;
  final String canteenName;
  final int balanceEarned;

  const CanteenOperator({
    required this.id,
    required this.canteenName,
    this.balanceEarned = 0,
  });

  factory CanteenOperator.fromJson(Map<String, dynamic> json) {
    return CanteenOperator(
      id: json['id'] as String,
      canteenName: json['canteen_name']?.toString() ?? '',
      balanceEarned:
          (double.tryParse(json['balance_earned']?.toString() ?? '0') ?? 0.0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'canteen_name': canteenName,
        'balance_earned': balanceEarned,
      };

  CanteenOperator copyWith({
    String? id,
    String? canteenName,
    int? balanceEarned,
  }) {
    return CanteenOperator(
      id: id ?? this.id,
      canteenName: canteenName ?? this.canteenName,
      balanceEarned: balanceEarned ?? this.balanceEarned,
    );
  }

  @override
  String toString() =>
      'CanteenOperator(id: $id, canteenName: $canteenName, balance: $balanceEarned)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CanteenOperator && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
