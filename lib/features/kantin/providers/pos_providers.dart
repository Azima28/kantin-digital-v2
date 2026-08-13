import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kantin_digital/features/auth/providers/auth_provider.dart';
import 'package:kantin_digital/core/models/models.dart';
import 'package:kantin_digital/features/kantin/models/order_item.dart';

// Provider to fetch all active products for the logged in operator
final posProductsProvider =
    FutureProvider<List<Product>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <Product>[];

    final client = ref.watch(supabaseClientProvider);
    final List<dynamic> response = await client
        .from('products')
        .select()
        .eq('operator_id', operatorId)
        .eq('is_available', true)
        .order('name');

    return response
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('posProductsProvider error: $e\n$st');
    rethrow;
  }
});

// Provider to fetch and calculate today's revenue for the logged in operator
final todayRevenueProvider =
    FutureProvider.autoDispose<double>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return 0.0;

    final client = ref.watch(supabaseClientProvider);

    // Calculate today's date boundary in UTC or local day string representation
    final todayDate = DateTime.now().toLocal();
    final startOfToday =
        DateTime(todayDate.year, todayDate.month, todayDate.day)
            .toUtc()
            .toIso8601String();
    final endOfToday =
        DateTime(todayDate.year, todayDate.month, todayDate.day, 23, 59, 59)
            .toUtc()
            .toIso8601String();

    final List<dynamic> response = await client
        .from('transactions')
        .select('total_amount')
        .eq('operator_id', operatorId)
        .eq('status', 'success')
        .gte('created_at', startOfToday)
        .lte('created_at', endOfToday);

    double sum = 0.0;
    for (var tx in response) {
      final amt = tx['total_amount'];
      if (amt != null) {
        sum += double.tryParse(amt.toString()) ?? 0.0;
      }
    }
    return sum;
  } catch (e, st) {
    debugPrint('todayRevenueProvider error: $e\n$st');
    rethrow;
  }
});

// Provider to fetch all products for management (both available and unavailable)
final manageProductsProvider =
    FutureProvider<List<Product>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <Product>[];

    final client = ref.watch(supabaseClientProvider);
    final List<dynamic> response = await client
        .from('products')
        .select()
        .eq('operator_id', operatorId)
        .order('name');

    return response
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('manageProductsProvider error: $e\n$st');
    rethrow;
  }
});

// Provider to fetch transaction history for the logged in operator
final operatorTransactionsProvider =
    FutureProvider.autoDispose<List<OperatorTransaction>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <OperatorTransaction>[];

    final client = ref.watch(supabaseClientProvider);
    final List<dynamic> response = await client
        .from('transactions')
        .select(
            'id, total_amount, type, status, created_at, student_id, students(profiles:profiles!students_id_fkey(full_name))')
        .eq('operator_id', operatorId)
        .order('created_at', ascending: false)
        .limit(50);

    return response
        .map(
            (e) => OperatorTransaction.fromOperatorJson(e as Map<String, dynamic>))
        .toList();
  } catch (e, st) {
    debugPrint('operatorTransactionsProvider error: $e\n$st');
    rethrow;
  }
});

final canteenOrdersProvider = FutureProvider.autoDispose<List<OrderItem>>((Ref ref) async {
  try {
    final authState = ref.watch(authNotifierProvider);
    final operatorId = authState.profile?['id'];
    if (operatorId == null) return <OrderItem>[];

    final client = ref.watch(supabaseClientProvider);
    
    final List<dynamic> response = await client
        .from('orders')
        .select('id, student_id, student_name, status, delivery_location, total_amount, created_at, cancel_request_reason, order_items(product_name, quantity, price)')
        .eq('operator_id', operatorId)
        .order('created_at', ascending: false);

    return response.map((e) {
      final map = e as Map<String, dynamic>;
      final List<dynamic> rawItems = map['order_items'] ?? [];
      final List<OrderSubItem> subItems = rawItems.map((item) {
        final itemMap = item as Map<String, dynamic>;
        return OrderSubItem(
          name: itemMap['product_name'] ?? '',
          qty: (itemMap['quantity'] as num).toInt(),
          price: (itemMap['price'] as num).toInt(),
        );
      }).toList();

      final createdAtStr = map['created_at'] != null 
          ? '${DateFormat('HH:mm').format(DateTime.parse(map['created_at']).toLocal())} WIB'
          : '';

      return OrderItem(
        id: map['id'] ?? '',
        studentId: map['student_id'] ?? '',
        studentName: map['student_name'] ?? 'Siswa',
        time: createdAtStr,
        status: map['status'] ?? 'Baru',
        deliveryLocation: map['delivery_location'],
        items: subItems,
        totalAmount: (map['total_amount'] as num).toInt(),
        cancelRequestReason: map['cancel_request_reason'],
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']).toLocal() : null,
      );
    }).toList();
  } catch (e, st) {
    debugPrint('canteenOrdersProvider error: $e\n$st');
    rethrow;
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

final canteenSalesVolumeProvider = StreamProvider.autoDispose
    .family<DailySalesVolumeData, CanteenSalesFilterParam?>((ref, filterParam) {
  final authState = ref.watch(authNotifierProvider);
  final operatorId = authState.profile?['id'];

  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<DailySalesVolumeData>();

  if (operatorId == null) {
    controller.add(DailySalesVolumeData(
      points: [],
      maxAmount: 100,
      totalCurrent: 0,
      totalPrevious: 0,
      percentChange: 0,
      periodLabel: 'Bulan Ini',
    ));
    return controller.stream;
  }

  Future<void> fetchData() async {
    try {
      final now = DateTime.now();

      // Determine Start & End Dates for Current Period
      final DateTime startDate = filterParam?.startDate ?? DateTime(now.year, now.month, 1);
      final DateTime endDate = filterParam?.endDate ?? DateTime(now.year, now.month + 1, 0);

      final startCurrentUtc = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0)
          .toUtc()
          .toIso8601String();
      final endCurrentUtc = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      // Calculate Previous Period of matching duration right before startDate
      final int durationDays = endDate.difference(startDate).inDays + 1;
      final DateTime prevEndDate = startDate.subtract(const Duration(days: 1));
      final DateTime prevStartDate = prevEndDate.subtract(Duration(days: durationDays - 1));

      final startPrevUtc = DateTime(prevStartDate.year, prevStartDate.month, prevStartDate.day, 0, 0, 0)
          .toUtc()
          .toIso8601String();
      final endPrevUtc = DateTime(prevEndDate.year, prevEndDate.month, prevEndDate.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      // Query Supabase for Current and Previous Period Transactions
      final List<dynamic> currentTx = await client
          .from('transactions')
          .select('total_amount, created_at')
          .eq('operator_id', operatorId)
          .eq('status', 'success')
          .gte('created_at', startCurrentUtc)
          .lte('created_at', endCurrentUtc);

      final List<dynamic> prevTx = await client
          .from('transactions')
          .select('total_amount, created_at')
          .eq('operator_id', operatorId)
          .eq('status', 'success')
          .gte('created_at', startPrevUtc)
          .lte('created_at', endPrevUtc);

      final List<DailySalesVolumePoint> points = [];
      double maxAmount = 0.0;
      double totalCurrent = 0.0;
      double totalPrevious = 0.0;

      if (durationDays <= 31) {
        // Daily Aggregation
        final Map<String, double> currentDaily = {};
        final Map<String, double> prevDaily = {};

        for (var tx in currentTx) {
          final date = DateTime.parse(tx['created_at']).toLocal();
          final key = DateFormat('yyyy-MM-dd').format(date);
          final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;
          currentDaily[key] = (currentDaily[key] ?? 0.0) + amount;
          totalCurrent += amount;
        }

        for (var tx in prevTx) {
          final date = DateTime.parse(tx['created_at']).toLocal();
          final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;
          final dayOffset = date.difference(prevStartDate).inDays;
          if (dayOffset >= 0 && dayOffset < durationDays) {
            prevDaily[dayOffset.toString()] = (prevDaily[dayOffset.toString()] ?? 0.0) + amount;
          }
          totalPrevious += amount;
        }

        DateTime curr = startDate;
        int index = 0;
        while (!curr.isAfter(endDate)) {
          final key = DateFormat('yyyy-MM-dd').format(curr);
          final cAmt = currentDaily[key] ?? 0.0;
          final pAmt = prevDaily[index.toString()] ?? 0.0;

          if (cAmt > maxAmount) maxAmount = cAmt;
          if (pAmt > maxAmount) maxAmount = pAmt;

          points.add(DailySalesVolumePoint(
            day: curr.day,
            label: durationDays <= 14
                ? DateFormat('E dd', 'id_ID').format(curr)
                : curr.day.toString().padLeft(2, '0'),
            currentAmount: cAmt,
            previousAmount: pAmt,
          ));

          curr = curr.add(const Duration(days: 1));
          index++;
        }
      } else {
        // Monthly Aggregation (for multi-month or year date ranges)
        final Map<String, double> currentMonthly = {};
        final Map<String, double> prevMonthly = {};

        for (var tx in currentTx) {
          final date = DateTime.parse(tx['created_at']).toLocal();
          final key = DateFormat('yyyy-MM').format(date);
          final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;
          currentMonthly[key] = (currentMonthly[key] ?? 0.0) + amount;
          totalCurrent += amount;
        }

        for (var tx in prevTx) {
          final date = DateTime.parse(tx['created_at']).toLocal();
          final key = DateFormat('yyyy-MM').format(date);
          final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0.0;
          prevMonthly[key] = (prevMonthly[key] ?? 0.0) + amount;
          totalPrevious += amount;
        }

        DateTime curr = DateTime(startDate.year, startDate.month, 1);
        final DateTime endMonth = DateTime(endDate.year, endDate.month, 1);
        DateTime prevCurr = DateTime(prevStartDate.year, prevStartDate.month, 1);

        while (!curr.isAfter(endMonth)) {
          final key = DateFormat('yyyy-MM').format(curr);
          final prevKey = DateFormat('yyyy-MM').format(prevCurr);

          final cAmt = currentMonthly[key] ?? 0.0;
          final pAmt = prevMonthly[prevKey] ?? 0.0;

          if (cAmt > maxAmount) maxAmount = cAmt;
          if (pAmt > maxAmount) maxAmount = pAmt;

          points.add(DailySalesVolumePoint(
            day: curr.month,
            label: DateFormat('MMM', 'id_ID').format(curr),
            currentAmount: cAmt,
            previousAmount: pAmt,
          ));

          curr = DateTime(curr.year, curr.month + 1, 1);
          prevCurr = DateTime(prevCurr.year, prevCurr.month + 1, 1);
        }
      }

      double pctChange = 0.0;
      if (totalPrevious > 0) {
        pctChange = ((totalCurrent - totalPrevious) / totalPrevious) * 100;
      } else if (totalCurrent > 0) {
        pctChange = 100.0;
      }

      if (!controller.isClosed) {
        controller.add(DailySalesVolumeData(
          points: points,
          maxAmount: maxAmount > 0 ? maxAmount : 100000,
          totalCurrent: totalCurrent,
          totalPrevious: totalPrevious,
          percentChange: pctChange,
          periodLabel: filterParam?.periodLabel ?? 'Bulan Ini',
        ));
      }
    } catch (e, st) {
      debugPrint('canteenSalesVolumeProvider error: $e\n$st');
    }
  }

  fetchData();

  // Supabase Realtime Channel
  final channel = client.channel('realtime:canteen_sales_vol_${operatorId}_${filterParam?.hashCode ?? 'default'}');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'transactions',
    filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'operator_id', value: operatorId),
    callback: (_) => fetchData(),
  ).subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
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

final topSellingFoodProvider = StreamProvider.autoDispose
    .family<FoodSalesDistributionData, CanteenSalesFilterParam?>((ref, filterParam) {
  final authState = ref.watch(authNotifierProvider);
  final operatorId = authState.profile?['id'];

  final client = ref.watch(supabaseClientProvider);
  final controller = StreamController<FoodSalesDistributionData>();

  if (operatorId == null) {
    controller.add(FoodSalesDistributionData(
      items: [],
      totalQuantity: 0,
      topCount: 0,
      periodLabel: 'Hari Ini',
    ));
    return controller.stream;
  }

  Future<void> fetchData() async {
    try {
      final now = DateTime.now();

      // Determine Start & End Dates
      final DateTime startDate = filterParam?.startDate ?? DateTime(now.year, now.month, now.day);
      final DateTime endDate = filterParam?.endDate ?? DateTime(now.year, now.month, now.day);

      final startUtc = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0)
          .toUtc()
          .toIso8601String();
      final endUtc = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          .toUtc()
          .toIso8601String();

      final Map<String, int> productQtyMap = {};

      // 1. Query POS Transaction Items
      try {
        final List<dynamic> txItemsRes = await client
            .from('transaction_items')
            .select('quantity, products!inner(name), transactions!inner(operator_id, created_at, status)')
            .eq('transactions.operator_id', operatorId)
            .eq('transactions.status', 'success')
            .gte('transactions.created_at', startUtc)
            .lte('transactions.created_at', endUtc);

        for (var row in txItemsRes) {
          final qty = (row['quantity'] as num?)?.toInt() ?? 0;
          final prodName = row['products']?['name']?.toString() ?? 'Menu Kantin';
          if (qty > 0) {
            productQtyMap[prodName] = (productQtyMap[prodName] ?? 0) + qty;
          }
        }
      } catch (e) {
        debugPrint('Error fetching transaction_items for food chart: $e');
      }

      // 2. Query Online Order Items
      try {
        final List<dynamic> orderItemsRes = await client
            .from('order_items')
            .select('product_name, quantity, orders!inner(operator_id, created_at, status)')
            .eq('orders.operator_id', operatorId)
            .neq('orders.status', 'cancelled')
            .neq('orders.status', 'dibatalkan')
            .gte('orders.created_at', startUtc)
            .lte('orders.created_at', endUtc);

        for (var row in orderItemsRes) {
          final qty = (row['quantity'] as num?)?.toInt() ?? 0;
          final prodName = row['product_name']?.toString() ?? 'Menu Kantin';
          if (qty > 0) {
            productQtyMap[prodName] = (productQtyMap[prodName] ?? 0) + qty;
          }
        }
      } catch (e) {
        debugPrint('Error fetching order_items for food chart: $e');
      }

      // Calculate totals and sort
      final sortedEntries = productQtyMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      int totalQty = 0;
      for (var entry in sortedEntries) {
        totalQty += entry.value;
      }

      final List<FoodSalesDistributionItem> items = [];
      final defaultColors = const [
        Color(0xFF1D4ED8), // Royal Blue
        Color(0xFF06B6D4), // Cyan
        Color(0xFF0F172A), // Dark Slate
        Color(0xFF8B5CF6), // Purple
        Color(0xFF94A3B8), // Other Slate
      ];

      if (sortedEntries.isNotEmpty && totalQty > 0) {
        int otherQty = 0;
        final int topLimit = 4;

        for (int i = 0; i < sortedEntries.length; i++) {
          if (i < topLimit) {
            final entry = sortedEntries[i];
            final pct = (entry.value / totalQty) * 100;
            items.add(FoodSalesDistributionItem(
              name: entry.key,
              quantity: entry.value,
              percentage: pct,
              color: defaultColors[i % defaultColors.length],
            ));
          } else {
            otherQty += sortedEntries[i].value;
          }
        }

        if (otherQty > 0) {
          final pct = (otherQty / totalQty) * 100;
          items.add(FoodSalesDistributionItem(
            name: 'Lainnya',
            quantity: otherQty,
            percentage: pct,
            color: defaultColors.last,
          ));
        }
      }

      if (!controller.isClosed) {
        controller.add(FoodSalesDistributionData(
          items: items,
          totalQuantity: totalQty,
          topCount: sortedEntries.length > 4 ? 4 : sortedEntries.length,
          periodLabel: filterParam?.periodLabel ?? 'Hari Ini',
        ));
      }
    } catch (e, st) {
      debugPrint('topSellingFoodProvider error: $e\n$st');
    }
  }

  fetchData();

  // Supabase Realtime Channel
  final channel = client.channel('realtime:canteen_top_food_${operatorId}_${filterParam?.hashCode ?? 'default'}');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'transactions',
    filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'operator_id', value: operatorId),
    callback: (_) => fetchData(),
  ).onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'orders',
    filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'operator_id', value: operatorId),
    callback: (_) => fetchData(),
  ).subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});


