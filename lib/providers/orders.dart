import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:http/http.dart' as http;

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem(
      {required this.id,
      required this.amount,
      required this.products,
      required this.dateTime});
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetMethod() async {
    final url = Uri.parse(
        'https://flutter-shop-57038-default-rtdb.firebaseio.com/orders.json');
    final response = await http.get(url);
    final List<OrderItem> loadedItems = [];
    final extractedData = json.decode(response.body) as Map<String, dynamic>;
    if (extractedData == null) {
      return;
    }
    extractedData.forEach((productId, orderData) {
      loadedItems.add(OrderItem(
          id: productId,
          amount: orderData['amount'],
          products: (orderData['products'] as List<dynamic>)
              .map((e) => CartItem(
                  id: e['id'],
                  title: e['title'],
                  price: e['price'],
                  quantity: e['quantity']))
              .toList(),
          dateTime: DateTime.parse(orderData['dateTime'])));
    });
    _orders = loadedItems.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProducts, double total) async {
    final url = Uri.parse(
        'https://flutter-shop-57038-default-rtdb.firebaseio.com/orders.json');
    final timeStamp = DateTime.now();
    try {
      final response = await http.post(url,
          body: json.encode({
            'amount': total,
            'dateTime': timeStamp.toIso8601String(),
            'products': cartProducts
                .map((e) => {
                      'id': e.id,
                      'title': e.title,
                      'quantity': e.quantity,
                      'price': e.price
                    })
                .toList(),
          }));
      _orders.insert(
          0,
          OrderItem(
              id: json.decode(response.body)['name'],
              amount: total,
              products: cartProducts,
              dateTime: timeStamp));
      notifyListeners();
    } catch (error) {}
  }
}
