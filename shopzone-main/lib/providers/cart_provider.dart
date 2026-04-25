import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  bool _loading = false;

  List<CartItem> get items => _items;
  bool get loading => _loading;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get shipping => subtotal > 50 ? 0 : 5.99;
  double get total => subtotal + shipping;

  Future<void> loadCart() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await ApiService.getCart();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> addItem(String productId) async {
    await ApiService.addToCart(productId);
    await loadCart();
  }

  Future<void> updateQuantity(int id, int qty) async {
    if (qty <= 0) {
      await removeItem(id);
      return;
    }
    await ApiService.updateCartItem(id, qty);
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) _items[idx].quantity = qty;
    notifyListeners();
  }

  Future<void> removeItem(int id) async {
    await ApiService.removeFromCart(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }
}