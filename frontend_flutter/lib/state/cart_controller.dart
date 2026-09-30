import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/phone.dart';

class CartLine {
  const CartLine({required this.phone, required this.quantity});
  final Phone phone;
  final int quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(phone: phone, quantity: quantity ?? this.quantity);

  Map<String, dynamic> toJson() => {
        'phone_id': phone.id,
        'name': phone.name,
        'slug': phone.slug,
        'price': phone.price,
        'discount_price': phone.discountPrice,
        'stock': phone.stock,
        'ram_gb': phone.ramGb,
        'storage_gb': phone.storageGb,
        'color': phone.color,
        'image_url': phone.imageUrl,
        'quantity': quantity,
      };

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final phoneJson = Map<String, dynamic>.from(json)..['id'] = json['phone_id'];
    return CartLine(
      phone: Phone.fromJson(phoneJson),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

class CartController extends ChangeNotifier {
  static const _storageKey = 'electrophone_cart_flutter';
  final List<CartLine> _lines = [];
  List<CartLine> get lines => List.unmodifiable(_lines);
  int get itemCount => _lines.fold(0, (sum, line) => sum + line.quantity);
  double get subtotal => _lines.fold(0, (sum, line) => sum + line.phone.currentPrice * line.quantity);
  double get shipping => subtotal > 1200000 || subtotal == 0 ? 0 : 20000;
  double get total => subtotal + shipping;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) return;
    try {
      final decoded = jsonDecode(stored) as List<dynamic>;
      _lines
        ..clear()
        ..addAll(decoded.map((item) => CartLine.fromJson(item as Map<String, dynamic>)));
      notifyListeners();
    } catch (_) {
      await prefs.remove(_storageKey);
    }
  }

  Future<void> add(Phone phone) async {
    final index = _lines.indexWhere((line) => line.phone.id == phone.id);
    if (index >= 0) {
      if (_lines[index].quantity < phone.stock) {
        _lines[index] = _lines[index].copyWith(quantity: _lines[index].quantity + 1);
      }
    } else if (phone.stock > 0) {
      _lines.add(CartLine(phone: phone, quantity: 1));
    }
    await _save();
  }

  Future<void> changeQuantity(int phoneId, int delta) async {
    final index = _lines.indexWhere((line) => line.phone.id == phoneId);
    if (index < 0) return;
    final next = _lines[index].quantity + delta;
    if (next <= 0) {
      _lines.removeAt(index);
    } else if (next <= _lines[index].phone.stock) {
      _lines[index] = _lines[index].copyWith(quantity: next);
    }
    await _save();
  }

  Future<void> remove(int phoneId) async {
    _lines.removeWhere((line) => line.phone.id == phoneId);
    await _save();
  }

  Future<void> clear() async {
    _lines.clear();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_lines.map((line) => line.toJson()).toList()));
    notifyListeners();
  }
}
