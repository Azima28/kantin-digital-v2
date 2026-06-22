import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String? productId; // null for custom extra charge
  final String name;
  final int price;
  final int quantity;
  final String? notes;

  CartItem({
    this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
  });

  int get total => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    int? price,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
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

  void addProduct(String id, String name, int price) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) => item.productId == id);

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
    } else {
      items.add(CartItem(
        productId: id,
        name: name,
        price: price,
        quantity: 1,
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

  void decreaseQuantity(String? id, String name) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) => item.productId == id && item.name == name);

    if (index != -1) {
      if (items[index].quantity > 1) {
        items[index] = items[index].copyWith(quantity: items[index].quantity - 1);
      } else {
        items.removeAt(index);
      }
      state = CartState(items: items);
    }
  }

  void increaseQuantity(String? id, String name) {
    final List<CartItem> items = List<CartItem>.from(state.items);
    final int index = items.indexWhere((CartItem item) => item.productId == id && item.name == name);

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
