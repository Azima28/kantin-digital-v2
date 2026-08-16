/// Data model untuk tabel `canteen_operators`.
///
/// Merepresentasikan data operator/pemilik stan kantin.
class CanteenOperator {
  final String id;
  final String canteenName;
  final int balanceEarned;
  final bool isDeliveryEnabled;
  final int deliveryFee;

  const CanteenOperator({
    required this.id,
    required this.canteenName,
    this.balanceEarned = 0,
    this.isDeliveryEnabled = true,
    this.deliveryFee = 2000,
  });

  factory CanteenOperator.fromJson(Map<String, dynamic> json) {
    return CanteenOperator(
      id: json['id'] as String,
      canteenName: json['canteen_name']?.toString() ?? '',
      balanceEarned:
          (double.tryParse(json['balance_earned']?.toString() ?? '0') ?? 0.0).toInt(),
      isDeliveryEnabled: json['is_delivery_enabled'] as bool? ?? true,
      deliveryFee: (double.tryParse(json['delivery_fee']?.toString() ?? '2000') ?? 2000.0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'canteen_name': canteenName,
        'balance_earned': balanceEarned,
        'is_delivery_enabled': isDeliveryEnabled,
        'delivery_fee': deliveryFee,
      };

  CanteenOperator copyWith({
    String? id,
    String? canteenName,
    int? balanceEarned,
    bool? isDeliveryEnabled,
    int? deliveryFee,
  }) {
    return CanteenOperator(
      id: id ?? this.id,
      canteenName: canteenName ?? this.canteenName,
      balanceEarned: balanceEarned ?? this.balanceEarned,
      isDeliveryEnabled: isDeliveryEnabled ?? this.isDeliveryEnabled,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }

  @override
  String toString() =>
      'CanteenOperator(id: $id, canteenName: $canteenName, balance: $balanceEarned, isDeliveryEnabled: $isDeliveryEnabled, deliveryFee: $deliveryFee)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CanteenOperator && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
