/// Model gabungan untuk dashboard super admin.
///
/// Berisi ringkasan metrik sistem: jumlah user, total saldo global,
/// volume transaksi harian, dan jumlah transaksi hari ini.
class AdminDashboardData {
  final int userCount;
  final int globalBalance;
  final int dailyVolume;
  final int txCountToday;
  final List<int> dailyTrend;

  const AdminDashboardData({
    this.userCount = 0,
    this.globalBalance = 0,
    this.dailyVolume = 0,
    this.txCountToday = 0,
    this.dailyTrend = const [],
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    final trendList = json['daily_trend'] as List<dynamic>? ?? [];
    return AdminDashboardData(
      userCount: (json['user_count'] as num?)?.toInt() ?? 0,
      globalBalance: (double.tryParse(json['global_balance']?.toString() ?? '0') ?? 0.0).toInt(),
      dailyVolume: (double.tryParse(json['daily_volume']?.toString() ?? '0') ?? 0.0).toInt(),
      txCountToday: (json['tx_count_today'] as num?)?.toInt() ?? 0,
      dailyTrend: trendList.map((e) => (double.tryParse(e.toString()) ?? 0.0).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_count': userCount,
        'global_balance': globalBalance,
        'daily_volume': dailyVolume,
        'tx_count_today': txCountToday,
        'daily_trend': dailyTrend,
      };

  String get formattedGlobalBalance =>
      'Rp ${globalBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  String get formattedDailyVolume =>
      'Rp ${dailyVolume.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';

  AdminDashboardData copyWith({
    int? userCount,
    int? globalBalance,
    int? dailyVolume,
    int? txCountToday,
    List<int>? dailyTrend,
  }) {
    return AdminDashboardData(
      userCount: userCount ?? this.userCount,
      globalBalance: globalBalance ?? this.globalBalance,
      dailyVolume: dailyVolume ?? this.dailyVolume,
      txCountToday: txCountToday ?? this.txCountToday,
      dailyTrend: dailyTrend ?? this.dailyTrend,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdminDashboardData &&
          userCount == other.userCount &&
          globalBalance == other.globalBalance &&
          dailyVolume == other.dailyVolume &&
          txCountToday == other.txCountToday &&
          dailyTrend == other.dailyTrend;

  @override
  int get hashCode =>
      Object.hash(userCount, globalBalance, dailyVolume, txCountToday, dailyTrend);

  @override
  String toString() =>
      'AdminDashboardData(users: $userCount, balance: $globalBalance, volume: $dailyVolume)';
}
