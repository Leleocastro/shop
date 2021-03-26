import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/product.dart';
import 'package:shop/utils/constants.dart';

class Products with ChangeNotifier {
  String _token;
  String _userId;
  Products([this._token, this._items = const [], this._userId]);
  final String _url = Constants.BASE_API_URL;
  final String _urlProducts = Constants.BASE_API_PRODUCTS;
  final String _urlFavorites = Constants.BASE_API_USERFAVORITE;
  Uri get _baseUrl {
    return Uri.https(
      _url,
      '$_urlProducts.json',
      {'auth': _token},
    );
  }

  List<Product> _items = [];

  List<Product> get items => [..._items];

  int get itemsCount {
    return _items.length;
  }

  List<Product> get favoriteItems {
    return _items.where((prod) => prod.isFavorite).toList();
  }

  Future<void> loadProducts() async {
    // print(_url);
    final response = await http.get(_baseUrl);
    final favResponse = await http.get(Uri.https(
      _url,
      '$_urlFavorites/$_userId.json',
      {'auth': _token},
    ));
    final favMap = json.decode(favResponse.body);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      _items.clear();

      if (data != null) {
        data.forEach((productId, productData) {
          final isFavorite =
              favMap == null ? false : favMap[productId] ?? false;
          _items.add(Product(
            id: productId,
            title: productData['title'],
            description: productData['description'],
            price: productData['price'].toDouble(),
            imageUrl: productData['imageUrl'],
            isFavorite: isFavorite,
          ));
        });
        notifyListeners();
      }
      return Future.value();
    } else {
      print(response.statusCode);
    }
  }

  Future<void> addProduct(Product newProduct) async {
    final response = await http.post(
      _baseUrl,
      body: json.encode({
        'title': newProduct.title,
        'description': newProduct.description,
        'price': newProduct.price,
        'imageUrl': newProduct.imageUrl,
      }),
    );
    _items.add(Product(
      id: json.decode(response.body)['name'],
      title: newProduct.title,
      description: newProduct.description,
      price: newProduct.price,
      imageUrl: newProduct.imageUrl,
    ));
    notifyListeners();
  }

  Future<void> updateProduct(Product product) async {
    if (product == null && product.id == null) {
      return;
    }

    final index = _items.indexWhere((prod) => prod.id == product.id);
    if (index >= 0) {
      await http.patch(
        Uri.https(
          _url,
          '$_urlProducts/${product.id}.json',
          {'auth': _token},
        ),
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
        }),
      );

      _items[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final index = _items.indexWhere((prod) => prod.id == id);

    if (index >= 0) {
      final product = _items[index];
      _items.remove(product);
      notifyListeners();

      final response = await http.delete(Uri.https(
        _url,
        '$_urlProducts/${product.id}.json',
        {'auth': _token},
      ));

      if (response.statusCode >= 400) {
        _items.insert(index, product);
        notifyListeners();
        throw HttpException('Ocorreu um erro na exclusão do produto!');
      }
    }
  }
}
