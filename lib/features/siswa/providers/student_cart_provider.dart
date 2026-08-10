import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentCartItem {
  final String productId;
  final String name;
  final int price;
  final int quantity;
  final String? notes;
  final List<String> selectedOptions;

  StudentCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
    this.selectedOptions = const <String>[],
  });

  int get total => price * quantity;

  StudentCartItem copyWith({
    String? productId,
    String? name,
    int? price,
    int? quantity,
    String? notes,
    List<String>? selectedOptions,
  }) {
    return StudentCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      selectedOptions: selectedOptions ?? this.selectedOptions,
    );
  }
}

class StudentCartState {
  final List<StudentCartItem> items;
  final String deliveryMethod; // 'pickup' or 'delivery'

  const StudentCartState({this.items = const <StudentCartItem>[], this.deliveryMethod = 'pickup'});

  int get totalAmount {
    return items.fold(0, (int sum, StudentCartItem item) => sum + item.total);
  }

  int get totalItems {
    return items.fold(0, (int sum, StudentCartItem item) => sum + item.quantity);
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

  void addProduct(String id, String name, int price, {int quantity = 1, List<String> selectedOptions = const <String>[]}) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items);
    final int index = items.indexWhere((StudentCartItem item) => 
        item.productId == id && _listsEqual(item.selectedOptions, selectedOptions));

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + quantity);
    } else {
      items.add(StudentCartItem(
        productId: id,
        name: name,
        price: price,
        quantity: quantity,
        selectedOptions: selectedOptions,
      ));
    }
    state = StudentCartState(items: items, deliveryMethod: state.deliveryMethod);
  }

  void removeProduct(String id, {List<String> selectedOptions = const <String>[]}) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items)
        .where((StudentCartItem item) => !(item.productId == id && _listsEqual(item.selectedOptions, selectedOptions)))
        .toList();
    state = StudentCartState(items: items, deliveryMethod: state.deliveryMethod);
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
      state = StudentCartState(items: items, deliveryMethod: state.deliveryMethod);
    }
  }

  void increaseQuantity(String id, {List<String> selectedOptions = const <String>[]}) {
    final List<StudentCartItem> items = List<StudentCartItem>.from(state.items);
    final int index = items.indexWhere((StudentCartItem item) => 
        item.productId == id && _listsEqual(item.selectedOptions, selectedOptions));

    if (index != -1) {
      items[index] = items[index].copyWith(quantity: items[index].quantity + 1);
      state = StudentCartState(items: items, deliveryMethod: state.deliveryMethod);
    }
  }

  void setDeliveryMethod(String method) {
    state = StudentCartState(items: state.items, deliveryMethod: method);
  }

  void clearCart() {
    state = const StudentCartState();
  }
}

final StateNotifierProvider<StudentCartNotifier, StudentCartState> studentCartProvider =
    StateNotifierProvider<StudentCartNotifier, StudentCartState>((Ref ref) {
  return StudentCartNotifier();
});
