import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shop/providers/cart.dart';
import 'package:http/http.dart' as http;
import 'package:shop/utils/constants.dart';

class Order {
  final String id;
  final double total;
  final List<CartItem> products;
  final DateTime date;

  Order({
    this.id,
    this.total,
    this.products,
    this.date,
  });
}

class Orders with ChangeNotifier {
  String _token;
  String _userId;
  final String _url = Constants.BASE_API_URL;
  final String _urlOrders = Constants.BASE_API_ORDERS;
  Uri get _baseUrl {
    return Uri.https(
      _url,
      '$_urlOrders/$_userId.json',
      {'auth': _token},
    );
  }

  List<Order> _items = [];

  Orders([this._token, this._userId, this._items = const []]);

  List<Order> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> loadOrders() async {
    List<Order> loadedItems = [];

    // print(_url);
    final response = await http.get(_baseUrl);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      loadedItems.clear();
      if (data != null) {
        data.forEach((orderId, orderData) {
          loadedItems.add(
            Order(
              id: orderId,
              total: orderData['total'].toDouble(),
              date: DateTime.parse(orderData['date']),
              products: (orderData['products'] as List<dynamic>).map((item) {
                return CartItem(
                  id: item['id'],
                  productId: item['productId'],
                  title: item['title'],
                  imageUrl: item['imageUrl'],
                  quantity: item['quantity'],
                  price: item['price'].toDouble(),
                );
              }).toList(),
            ),
          );
        });
        notifyListeners();
      }

      _items = loadedItems.reversed.toList();
      return Future.value();
    } else {
      print(response.statusCode);
    }
  }

  Future<void> addOrder(Cart cart) async {
    final date = DateTime.now();
    final response = await http.post(
      _baseUrl,
      body: json.encode({
        'total': cart.totalAmount,
        'date': date.toIso8601String(),
        'products': cart.items.values
            .map((cartItem) => {
                  'id': cartItem.id,
                  'productId': cartItem.productId,
                  'title': cartItem.title,
                  'imageUrl': cartItem.imageUrl,
                  'quantity': cartItem.quantity,
                  'price': cartItem.price,
                })
            .toList(),
      }),
    );

    _items.insert(
      0,
      Order(
        id: json.decode(response.body)['name'],
        total: cart.totalAmount,
        date: date,
        products: cart.items.values.toList(),
      ),
    );

    notifyListeners();
  }
}
