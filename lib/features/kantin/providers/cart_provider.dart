import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String? productId; // null for custom extra charge
  final String name;
  final int basePrice;
  final int price; // unit price (base + options)
  final int quantity;
  final List<String> selectedOptions;
  final String? notes;

  CartItem({
    this.productId,
    required this.name,
    required this.price,
    this.basePrice = 0,
    required this.quantity,
    this.selectedOptions = const <String>[],
    this.notes,
  });

  int get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    int? price,
    int? basePrice,
    int? quantity,
    List<String>? selectedOptions,
    String? notes,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      basePrice: basePrice ?? this.basePrice,
      quantity: quantity ?? this.quantity,
      selectedOptions: selectedOptions ?? this.selectedOptions,
      notes: notes ?? this.notes,
    );
  }
}

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const <CartItem>[]});

  int get totalAmount {
    return items.fold(0, (int sum, CartItem item) => sum + item.total);
  }

  int get totalItems {
    return items.fold(0, (int sum, CartItem item) => sum + item.quantity);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void addProduct(
    String id,
    String name,
    int price, {
    int? basePrice,
    List<String> selectedOptions = const <String>[],
    String? notes,
    int quantity = 1,
  }) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) =>
        item.productId == id &&
        _listsEqual(item.selectedOptions, selectedOptions) &&
        (item.notes ?? '') == (notes ?? ''));

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + quantity);
    } else {
      items.add(CartItem(
        productId: id,
        name: name,
        price: price,
        basePrice: basePrice ?? price,
        quantity: quantity,
        selectedOptions: selectedOptions,
        notes: notes,
      ));
    }
    state = CartState(items: items);
  }

  void addCustomCharge(String name, int price) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) => item.productId == null && item.name == name);

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItem(
        productId: null,
        name: name,
        price: price,
        basePrice: price,
        quantity: 1,
      ));
    }
    state = CartState(items: items);
  }

  void removeProduct(String id) {
    final List<CartItem> items = List<CartItem>.from(state.items)
        .where((CartItem item) => item.productId != id)
        .toList();
    state = CartState(items: items);
  }

  void removeCustomCharge(String name) {
    final List<CartItem> items = List<CartItem>.from(state.items)
        .where((CartItem item) => !(item.productId == null && item.name == name))
        .toList();
    state = CartState(items: items);
  }

  void decreaseQuantity(String? id, String name, {List<String>? selectedOptions, String? notes}) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) {
      if (item.productId != id || item.name != name) return false;
      if (selectedOptions != null && !_listsEqual(item.selectedOptions, selectedOptions)) return false;
      if (notes != null && (item.notes ?? '') != notes) return false;
      return true;
    });

    if (index != -1) {
      if (items[index].quantity > 1) {
        items[index] = items[index].copyWith(quantity: items[index].quantity - 1);
      } else {
        items.removeAt(index);
      }
      state = CartState(items: items);
    }
  }

  void increaseQuantity(String? id, String name, {List<String>? selectedOptions, String? notes}) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) {
      if (item.productId != id || item.name != name) return false;
      if (selectedOptions != null && !_listsEqual(item.selectedOptions, selectedOptions)) return false;
      if (notes != null && (item.notes ?? '') != notes) return false;
      return true;
    });

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
      state = CartState(items: items);
    }
  }

  void clearCart() {
    state = const CartState();
  }
}

final StateNotifierProvider<CartNotifier, CartState> cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((Ref ref) {
  return CartNotifier();
});
