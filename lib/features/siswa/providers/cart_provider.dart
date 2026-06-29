import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_digital/core/models/models.dart';

// ─────────────────────────────────────────────────────────────
// CartState — state keranjang multi-kantin
// ─────────────────────────────────────────────────────────────

class CartState {
  /// Map: operatorId → CartCanteenEntry
  final Map<String, CartCanteenEntry> canteens;

  const CartState({this.canteens = const {}});

  int get totalItems =>
      canteens.values.fold(0, (s, c) => s + c.itemCount);

  int get grandTotal =>
      canteens.values.fold(0, (s, c) => s + c.totalAmount);

  bool get isEmpty => totalItems == 0;

  List<CartCanteenEntry> get canteenList =>
      canteens.values.where((c) => c.items.isNotEmpty).toList();

  CartState copyWith(Map<String, CartCanteenEntry> canteens) =>
      CartState(canteens: canteens);
}

// ─────────────────────────────────────────────────────────────
// CartNotifier
// ─────────────────────────────────────────────────────────────

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  // Tambah produk ke keranjang kantin tertentu
  void addItem({
    required String operatorId,
    required String canteenName,
    required bool deliveryEnabled,
    required int deliveryFee,
    required CartItemEntry item,
  }) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];

    if (existing == null) {
      // Kantin baru
      canteens[operatorId] = CartCanteenEntry(
        operatorId: operatorId,
        canteenName: canteenName,
        deliveryEnabled: deliveryEnabled,
        deliveryFee: deliveryFee,
        items: [item],
      );
    } else {
      // Cek apakah produk sudah ada
      final existingItems = List<CartItemEntry>.from(existing.items);
      final idx = existingItems.indexWhere((e) => e.productId == item.productId);
      if (idx >= 0) {
        existingItems[idx] =
            existingItems[idx].copyWith(quantity: existingItems[idx].quantity + 1);
      } else {
        existingItems.add(item);
      }
      canteens[operatorId] = existing.copyWith(items: existingItems);
    }

    state = state.copyWith(canteens);
  }

  // Kurangi qty (0 = hapus dari keranjang)
  void decreaseItem(String operatorId, String productId) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;

    final existingItems = List<CartItemEntry>.from(existing.items);
    final idx = existingItems.indexWhere((e) => e.productId == productId);
    if (idx < 0) return;

    if (existingItems[idx].quantity <= 1) {
      existingItems.removeAt(idx);
    } else {
      existingItems[idx] =
          existingItems[idx].copyWith(quantity: existingItems[idx].quantity - 1);
    }

    if (existingItems.isEmpty) {
      canteens.remove(operatorId);
    } else {
      canteens[operatorId] = existing.copyWith(items: existingItems);
    }
    state = state.copyWith(canteens);
  }

  // Set jumlah langsung
  void setQuantity(String operatorId, String productId, int qty) {
    if (qty <= 0) {
      removeItem(operatorId, productId);
      return;
    }
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;

    final existingItems = List<CartItemEntry>.from(existing.items);
    final idx = existingItems.indexWhere((e) => e.productId == productId);
    if (idx < 0) return;

    existingItems[idx] = existingItems[idx].copyWith(quantity: qty);
    canteens[operatorId] = existing.copyWith(items: existingItems);
    state = state.copyWith(canteens);
  }

  // Update catatan per item
  void setItemNote(String operatorId, String productId, String? note) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;

    final existingItems = List<CartItemEntry>.from(existing.items);
    final idx = existingItems.indexWhere((e) => e.productId == productId);
    if (idx < 0) return;

    existingItems[idx] = existingItems[idx].copyWith(note: note);
    canteens[operatorId] = existing.copyWith(items: existingItems);
    state = state.copyWith(canteens);
  }

  // Hapus satu item
  void removeItem(String operatorId, String productId) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;

    final existingItems =
        existing.items.where((e) => e.productId != productId).toList();
    if (existingItems.isEmpty) {
      canteens.remove(operatorId);
    } else {
      canteens[operatorId] = existing.copyWith(items: existingItems);
    }
    state = state.copyWith(canteens);
  }

  // Set tipe pengiriman per kantin
  void setDeliveryType(String operatorId, String type) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;

    canteens[operatorId] = existing.copyWith(
      deliveryType: type,
      // reset lokasi jika ganti ke takeaway
      deliveryLocation: type == 'takeaway' ? '' : existing.deliveryLocation,
    );
    state = state.copyWith(canteens);
  }

  // Set lokasi antar
  void setDeliveryLocation(String operatorId, String? location) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;
    canteens[operatorId] = existing.copyWith(deliveryLocation: location);
    state = state.copyWith(canteens);
  }

  // Set nomor WA/HP
  void setStudentPhone(String operatorId, String? phone) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;
    canteens[operatorId] = existing.copyWith(studentPhone: phone);
    state = state.copyWith(canteens);
  }

  // Set catatan order keseluruhan per kantin
  void setCanteenNote(String operatorId, String? note) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    final existing = canteens[operatorId];
    if (existing == null) return;
    canteens[operatorId] = existing.copyWith(note: note);
    state = state.copyWith(canteens);
  }

  // Kosongkan keranjang kantin tertentu
  void clearCanteen(String operatorId) {
    final canteens = Map<String, CartCanteenEntry>.from(state.canteens);
    canteens.remove(operatorId);
    state = state.copyWith(canteens);
  }

  // Kosongkan seluruh keranjang
  void clearAll() {
    state = const CartState();
  }

  // Jumlah item di keranjang untuk 1 produk tertentu
  int quantityOf(String operatorId, String productId) {
    final canteen = state.canteens[operatorId];
    if (canteen == null) return 0;
    final item = canteen.items.where((e) => e.productId == productId).firstOrNull;
    return item?.quantity ?? 0;
  }

  // Validasi semua kantin delivery sudah lengkap field wajibnya
  /// Returns map operatorId → error message jika ada yang tidak valid
  Map<String, String> validate() {
    final errors = <String, String>{};
    for (final entry in state.canteens.values) {
      if (entry.deliveryType == 'delivery') {
        if ((entry.deliveryLocation ?? '').trim().isEmpty) {
          errors[entry.operatorId] = 'Lokasi antar wajib diisi';
        } else if ((entry.studentPhone ?? '').trim().isEmpty) {
          errors[entry.operatorId] = 'Nomor WA wajib diisi untuk pengiriman';
        }
      }
    }
    return errors;
  }
}

// ─────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (_) => CartNotifier(),
);
