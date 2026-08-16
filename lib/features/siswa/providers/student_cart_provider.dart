import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentCartItem {
  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String? imageUrl;
  final String? notes;
  final List<String> selectedOptions;

  StudentCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.notes,
    this.selectedOptions = const <String>[],
  });

  int get total => price * quantity;

  StudentCartItem copyWith({
    String? productId,
    String? name,
    int? price,
    int? quantity,
    String? imageUrl,
    String? notes,
    List<String>? selectedOptions,
  }) {
    return StudentCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}

class StudentCartState {
  final List<StudentCartItem> items;
  final String? canteenId;
  final String? canteenName;
  final String deliveryMethod; // 'pickup' or 'delivery'
  final int deliveryFee;
  final String deliveryLocation;

  const StudentCartState({
    this.items = const <StudentCartItem>[],
    this.canteenId,
    this.canteenName,
    this.deliveryMethod = 'pickup',
    this.deliveryFee = 2000,
    this.deliveryLocation = '',
  });

  /// Total harga seluruh menu produk di keranjang (tanpa ongkir)
  int get itemsTotal {
    return items.fold(0, (int sum, StudentCartItem item) => sum + item.total);
  }

  /// Total akhir tagihan (harga menu + ongkir jika mode delivery aktif)
  int get totalAmount {
    final int subtotal = itemsTotal;
    if (subtotal == 0) return 0;
    return subtotal + (deliveryMethod == 'delivery' ? deliveryFee : 0);
  }

  /// Jumlah total porsi/item makanan dalam keranjang
  int get totalItems {
    return items.fold(0, (int sum, StudentCartItem item) => sum + item.quantity);
  }

  StudentCartState copyWith({
    List<StudentCartItem>? items,
    String? canteenId,
    String? canteenName,
    String? deliveryMethod,
    int? deliveryFee,
    String? deliveryLocation,
  }) {
    return StudentCartState(
      items: items ?? this.items,
      canteenId: canteenId ?? this.canteenId,
      canteenName: canteenName ?? this.canteenName,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
    );
  }
}

class StudentCartNotifier extends StateNotifier<StudentCartState> {
  StudentCartNotifier() : super(const StudentCartState());

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Mengecek apakah penambahan produk dari [newCanteenId] bentrok dengan stan saat ini
  bool checkCanteenConflict(String newCanteenId) {
    if (state.items.isEmpty || state.canteenId == null) {
      return false;
    }
    return state.canteenId != newCanteenId;
  }

  /// Menambahkan produk dengan identitas stan (Single-Merchant Cart)
  void addProductWithCanteen({
    required String canteenId,
    required String canteenName,
    required int deliveryFee,
    required String productId,
    required String name,
    required int price,
    String? imageUrl,
    int quantity = 1,
    List<String> selectedOptions = const <String>[],
  }) {
    List<StudentCartItem> items;

    // Jika ganti stan baru, reset isi keranjang sebelumnya
    if (state.canteenId != null && state.canteenId != canteenId) {
      items = [];
    } else {
      items = List<StudentCartItem>.from(state.items);
    }

    final int index = items.indexWhere((StudentCartItem item) =>
        item.productId == productId && _listsEqual(item.selectedOptions, selectedOptions));

    if (index != -1) {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + quantity,
        imageUrl: imageUrl ?? items[index].imageUrl,
      );
    } else {
      items.add(StudentCartItem(
        productId: productId,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
        selectedOptions: selectedOptions,
      ));
    }

    state = state.copyWith(
      items: items,
      canteenId: canteenId,
      canteenName: canteenName,
      deliveryFee: deliveryFee,
    );
  }

  void addProduct(
    String id,
    String name,
    int price, {
    String? imageUrl,
    int quantity = 1,
    List<String> selectedOptions = const <String>[],
  }) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items);
    final int index = items.indexWhere((StudentCartItem item) =>
        item.productId == id && _listsEqual(item.selectedOptions, selectedOptions));

    if (index != -1) {
      items[index] = items[index].copyWith(
        quantity: items[index].quantity + quantity,
        imageUrl: imageUrl ?? items[index].imageUrl,
      );
    } else {
      items.add(StudentCartItem(
        productId: id,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
        selectedOptions: selectedOptions,
      ));
    }
    state = state.copyWith(items: items);
  }

  void removeProduct(String id, {List<String> selectedOptions = const <String>[]}) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items)
        .where((StudentCartItem item) => !(item.productId == id && _listsEqual(item.selectedOptions, selectedOptions)))
        .toList();

    state = state.copyWith(
      items: items,
      canteenId: items.isEmpty ? null : state.canteenId,
      canteenName: items.isEmpty ? null : state.canteenName,
    );
  }

  void decreaseQuantity(String id, {List<String> selectedOptions = const <String>[]}) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items);
    final int index = items.indexWhere((StudentCartItem item) =>
        item.productId == id && _listsEqual(item.selectedOptions, selectedOptions));

    if (index != -1) {
      if (items[index].quantity > 1) {
        items[index] = items[index].copyWith(quantity: items[index].quantity - 1);
      } else {
        items.removeAt(index);
      }
      state = state.copyWith(
        items: items,
        canteenId: items.isEmpty ? null : state.canteenId,
        canteenName: items.isEmpty ? null : state.canteenName,
      );
    }
  }

  void increaseQuantity(String id, {List<String> selectedOptions = const <String>[]}) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items);
    final int index = items.indexWhere((StudentCartItem item) =>
        item.productId == id && _listsEqual(item.selectedOptions, selectedOptions));

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
      state = state.copyWith(items: items);
    }
  }

  void setDeliveryMethod(String method) {
    state = state.copyWith(deliveryMethod: method);
  }

  void setDeliveryFee(int fee) {
    state = state.copyWith(deliveryFee: fee);
  }

  void setDeliveryLocation(String location) {
    state = state.copyWith(deliveryLocation: location);
  }

  void clearCart() {
    state = const StudentCartState();
  }
}

final StateNotifierProvider<StudentCartNotifier, StudentCartState> studentCartProvider =
    StateNotifierProvider<StudentCartNotifier, StudentCartState>((Ref ref) {
  return StudentCartNotifier();
});
