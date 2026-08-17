import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/providers/shared_providers.dart';
import 'package:kantin_digital/core/theme/nebula_colors.dart';
import 'package:kantin_digital/core/utils/app_date_formatter.dart';
import 'package:kantin_digital/core/utils/riverpod_cache_extensions.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

// Provider to fetch all active products for the logged in operator (Cache 5 Menit)
final posProductsProvider =
    FutureProvider.autoDispose<List<Product>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final operatorId = ref.watch(authNotifierProvider.select((s) => s.profile?['id'] as String?));
    if (operatorId == null) return <Product>[];

    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/products', queryParams: {'canteen_id': operatorId});
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <Product>[];
  } catch (e, st) {
    debugPrint('posProductsProvider error: $e\n$st');
    return <Product>[];
  }
});

// Provider to fetch and calculate today's revenue for the logged in operator (Cache 3 Menit)
final todayRevenueProvider =
    FutureProvider.autoDispose<double>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null || profile['role']?.toString() != 'petugas_kantin') return 0.0;
    final operatorId = profile['id'] as String?;
    if (operatorId == null) return 0.0;

    final txList = await ref.watch(operatorTransactionsProvider.future);
    final now = DateTime.now();

    double sum = 0.0;
    for (final tx in txList) {
      if (tx.createdAt == null) continue;
      final dt = tx.createdAt!.toLocal();
      final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final isSuccess = tx.status == null || tx.status == 'success' || tx.status == 'completed';
      final isPurchase = tx.type == null || tx.type == 'purchase';
      if (isToday && isSuccess && isPurchase) {
        sum += tx.totalAmount.toDouble();
      }
    }
    return sum;
  } catch (e, st) {
    debugPrint('todayRevenueProvider error: $e\n$st');
    return 0.0;
  }
});

// Provider to fetch all products for management (both available and unavailable) (Cache 5 Menit)
final manageProductsProvider =
    FutureProvider.autoDispose<List<Product>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final operatorId = ref.watch(authNotifierProvider.select((s) => s.profile?['id'] as String?));
    if (operatorId == null) return <Product>[];

    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/products', queryParams: {'canteen_id': operatorId});
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <Product>[];
  } catch (e, st) {
    debugPrint('manageProductsProvider error: $e\n$st');
    return <Product>[];
  }
});

// Provider to fetch current canteen operator profile and settings (Cache 5 Menit)
final canteenOperatorProvider = FutureProvider.autoDispose<CanteenOperator?>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 5));
  try {
    final operatorId = ref.watch(authNotifierProvider.select((s) => s.profile?['id'] as String?));
    if (operatorId == null) return null;

    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/canteens');
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      for (var item in list) {
        if (item['id'] == operatorId) {
          return CanteenOperator.fromJson(item as Map<String, dynamic>);
        }
      }
    }
    return null;
  } catch (e) {
    return null;
  }
});

// Provider to fetch transaction history for the logged in operator (Cache 3 Menit)
final operatorTransactionsProvider =
    FutureProvider.autoDispose<List<OperatorTransaction>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null || profile['role']?.toString() != 'petugas_kantin') return <OperatorTransaction>[];
    final operatorId = profile['id'] as String?;
    if (operatorId == null) return <OperatorTransaction>[];

    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/pos/sales-history', queryParams: {'limit': '200'});
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list
          .map((e) => OperatorTransaction.fromOperatorJson(e as Map<String, dynamic>))
          .toList();
    }
    return <OperatorTransaction>[];
  } catch (e, st) {
    debugPrint('operatorTransactionsProvider error: $e\n$st');
    return <OperatorTransaction>[];
  }
});

final canteenOrdersProvider = FutureProvider.autoDispose<List<OrderItem>>((Ref ref) async {
  ref.cacheFor(const Duration(minutes: 3));
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null) return <OrderItem>[];
    final role = profile['role']?.toString();
    if (role != 'petugas_kantin') return <OrderItem>[];

    final operatorId = profile['id'] as String?;
    if (operatorId == null) return <OrderItem>[];

    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/orders/operator');
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) {
        final map = e as Map<String, dynamic>;
        final List<dynamic> rawItems = map['items'] ?? map['order_items'] ?? [];
        final List<OrderSubItem> subItems = rawItems.map((item) {
          final itemMap = item as Map<String, dynamic>;
          final name = itemMap['product_name'] ?? itemMap['name'] ?? '';
          return OrderSubItem(
            name: name,
            qty: (itemMap['quantity'] as num?)?.toInt() ?? 1,
            price: (itemMap['price'] as num?)?.toInt() ?? (itemMap['unit_price'] as num?)?.toInt() ?? 0,
            imageUrl: itemMap['image_url'],
          );
        }).toList();

        String createdAtStr = '';
        if (map['created_at'] != null) {
          final dt = DateTime.tryParse(map['created_at'].toString())?.toLocal();
          if (dt != null) {
            final h = dt.hour.toString().padLeft(2, '0');
            final m = dt.minute.toString().padLeft(2, '0');
            createdAtStr = '$h:$m WIB';
          }
        }

        return OrderItem(
          id: map['id']?.toString() ?? '',
          studentId: map['student_id']?.toString() ?? '',
          studentName: map['student_name']?.toString() ?? 'Siswa',
          time: createdAtStr,
          status: map['status']?.toString() ?? 'Baru',
          deliveryLocation: map['delivery_location']?.toString(),
          items: subItems,
          totalAmount: (map['total_amount'] as num?)?.toInt() ?? 0,
          cancelRequestReason: map['cancel_request_reason']?.toString(),
          createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString())?.toLocal() : null,
        );
      }).toList();
    }
    return <OrderItem>[];
  } catch (e, st) {
    debugPrint('canteenOrdersProvider error: $e\n$st');
    return <OrderItem>[];
  }
});

// Provider untuk menghitung jumlah pesanan aktif / baru / sedang proses bagi Kasir POS
final canteenActiveOrdersCountProvider = Provider.autoDispose<int>((ref) {
  final ordersAsync = ref.watch(canteenOrdersProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders.where((o) {
      final s = o.status.trim().toLowerCase();
      return s != 'selesai' && s != 'dibatalkan' && s != 'cancelled' && s != 'refunded';
    }).length,
    orElse: () => 0,
  );
});

// Provider to fetch canteen reviews (Cache 3 Menit)
final canteenReviewsProvider =
    FutureProvider.autoDispose.family<List<OrderReview>, String>((Ref ref, String operatorId) async {
  ref.cacheFor(const Duration(minutes: 3));
  try {
    final apiClient = ref.watch(apiClientProvider);
    final response = await apiClient.get('/canteens/$operatorId/reviews');
    if (response.success && response.data != null) {
      final list = response.data as List<dynamic>;
      return list.map((e) => OrderReview.fromJson(e as Map<String, dynamic>)).toList();
    }
    return <OrderReview>[];
  } catch (e) {
    return <OrderReview>[];
  }
});

// ============================================================================
// DAILY SALES VOLUME CHART PROVIDER (Canteen Operator)
// ============================================================================

class CanteenSalesFilterParam {
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;

  CanteenSalesFilterParam({
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanteenSalesFilterParam &&
          runtimeType == other.runtimeType &&
          startDate.year == other.startDate.year &&
          startDate.month == other.startDate.month &&
          startDate.day == other.startDate.day &&
          endDate.year == other.endDate.year &&
          endDate.month == other.endDate.month &&
          endDate.day == other.endDate.day &&
          periodLabel == other.periodLabel;

  @override
  int get hashCode =>
      Object.hash(startDate.year, startDate.month, startDate.day, endDate.year, endDate.month, endDate.day, periodLabel);
}

class DailySalesVolumePoint {
  final int day;
  final String label;
  final double currentAmount;
  final double previousAmount;

  DailySalesVolumePoint({
    required this.day,
    required this.label,
    required this.currentAmount,
    required this.previousAmount,
  });
}

class DailySalesVolumeData {
  final List<DailySalesVolumePoint> points;
  final double maxAmount;
  final double totalCurrent;
  final double totalPrevious;
  final double percentChange;
  final String periodLabel;

  DailySalesVolumeData({
    required this.points,
    required this.maxAmount,
    required this.totalCurrent,
    required this.totalPrevious,
    required this.percentChange,
    required this.periodLabel,
  });
}

final canteenSalesVolumeProvider = FutureProvider.autoDispose
    .family<DailySalesVolumeData, CanteenSalesFilterParam?>((ref, filterParam) async {
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null || profile['role']?.toString() != 'petugas_kantin') {
      return DailySalesVolumeData(
        points: [],
        maxAmount: 100000,
        totalCurrent: 0,
        totalPrevious: 0,
        percentChange: 0,
        periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
      );
    }

    final txList = await ref.watch(operatorTransactionsProvider.future);
    final now = DateTime.now();

    final startDate = filterParam?.startDate ?? DateTime(now.year, now.month, 1);
    final endDate = filterParam?.endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final duration = endDate.difference(startDate);
    final prevStart = startDate.subtract(duration);
    final prevEnd = startDate.subtract(const Duration(seconds: 1));

    final Map<int, double> currentDayMap = {};
    final Map<int, double> prevDayMap = {};
    double totalCurrent = 0;
    double totalPrevious = 0;

    for (var tx in txList) {
      if (tx.createdAt == null) continue;
      final isSuccess = tx.status == null || tx.status == 'success' || tx.status == 'completed';
      final isPurchase = tx.type == null || tx.type == 'purchase';
      if (!isSuccess || !isPurchase) continue;

      final dt = tx.createdAt!;
      final amt = tx.totalAmount.toDouble();

      if (dt.isAfter(startDate.subtract(const Duration(seconds: 1))) && dt.isBefore(endDate.add(const Duration(seconds: 1)))) {
        final dayKey = dt.day;
        currentDayMap[dayKey] = (currentDayMap[dayKey] ?? 0) + amt;
        totalCurrent += amt;
      } else if (dt.isAfter(prevStart.subtract(const Duration(seconds: 1))) && dt.isBefore(prevEnd.add(const Duration(seconds: 1)))) {
        final dayKey = dt.day;
        prevDayMap[dayKey] = (prevDayMap[dayKey] ?? 0) + amt;
        totalPrevious += amt;
      }
    }

    final List<DailySalesVolumePoint> points = [];
    double maxAmt = 0;

    final daysInPeriod = duration.inDays + 1;
    final int step = daysInPeriod > 31 ? (daysInPeriod / 12).ceil() : 1;

    for (int i = 0; i < daysInPeriod; i += step) {
      final date = startDate.add(Duration(days: i));
      final dayKey = date.day;
      final curAmt = currentDayMap[dayKey] ?? 0.0;
      final prevAmt = prevDayMap[dayKey] ?? 0.0;

      if (curAmt > maxAmt) maxAmt = curAmt;
      if (prevAmt > maxAmt) maxAmt = prevAmt;

      final label = daysInPeriod <= 7
          ? '${date.day} ${AppDateFormatter.shortMonths[date.month]}'
          : '${date.day}';

      points.add(DailySalesVolumePoint(
        day: dayKey,
        label: label,
        currentAmount: curAmt,
        previousAmount: prevAmt,
      ));
    }

    if (maxAmt == 0) maxAmt = 50000;

    final percentChange = totalPrevious > 0
        ? ((totalCurrent - totalPrevious) / totalPrevious) * 100
        : (totalCurrent > 0 ? 100.0 : 0.0);

    return DailySalesVolumeData(
      points: points,
      maxAmount: maxAmt,
      totalCurrent: totalCurrent,
      totalPrevious: totalPrevious,
      percentChange: percentChange,
      periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
    );
  } catch (e, st) {
    debugPrint('canteenSalesVolumeProvider error: $e\n$st');
    return DailySalesVolumeData(
      points: [],
      maxAmount: 100000,
      totalCurrent: 0,
      totalPrevious: 0,
      percentChange: 0,
      periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
    );
  }
});

// ============================================================================
// TOP SELLING FOOD DISTRIBUTION PROVIDER (Canteen Operator)
// ============================================================================

class FoodSalesDistributionItem {
  final String name;
  final int quantity;
  final double percentage;
  final Color color;

  FoodSalesDistributionItem({
    required this.name,
    required this.quantity,
    required this.percentage,
    required this.color,
  });
}

class FoodSalesDistributionData {
  final List<FoodSalesDistributionItem> items;
  final int totalQuantity;
  final int topCount;
  final String periodLabel;

  FoodSalesDistributionData({
    required this.items,
    required this.totalQuantity,
    required this.topCount,
    required this.periodLabel,
  });
}

final topSellingFoodProvider = FutureProvider.autoDispose
    .family<FoodSalesDistributionData, CanteenSalesFilterParam?>((ref, filterParam) async {
  try {
    final profile = ref.watch(authNotifierProvider.select((s) => s.profile));
    if (profile == null || profile['role']?.toString() != 'petugas_kantin') {
      return FoodSalesDistributionData(
        items: [],
        totalQuantity: 0,
        topCount: 0,
        periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
      );
    }

    final orders = await ref.watch(canteenOrdersProvider.future);
    final now = DateTime.now();
    final startDate = filterParam?.startDate ?? DateTime(now.year, now.month, 1);
    final endDate = filterParam?.endDate ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final Map<String, int> qtyMap = {};
    int totalQty = 0;

    for (var order in orders) {
      if (order.createdAt != null) {
        if (order.createdAt!.isBefore(startDate) || order.createdAt!.isAfter(endDate)) {
          continue;
        }
      }
      for (var item in order.items) {
        final name = item.name.trim();
        if (name.isNotEmpty) {
          qtyMap[name] = (qtyMap[name] ?? 0) + item.qty;
          totalQty += item.qty;
        }
      }
    }

    final palette = [
      Nebula.teal,
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
    ];

    final sortedEntries = qtyMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<FoodSalesDistributionItem> items = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final pct = totalQty > 0 ? (entry.value / totalQty) * 100 : 0.0;
      items.add(FoodSalesDistributionItem(
        name: entry.key,
        quantity: entry.value,
        percentage: pct,
        color: palette[i % palette.length],
      ));
    }

    return FoodSalesDistributionData(
      items: items,
      totalQuantity: totalQty,
      topCount: items.isNotEmpty ? items.first.quantity : 0,
      periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
    );
  } catch (e, st) {
    debugPrint('topSellingFoodProvider error: $e\n$st');
    return FoodSalesDistributionData(
      items: [],
      totalQuantity: 0,
      topCount: 0,
      periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
    );
  }
});
