import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shop/utils/constants.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    @required this.imageUrl,
    this.isFavorite = false,
  });

  Future<void> toggleFavorite(String token, String userId) async {
    isFavorite = !isFavorite;
    final response = await http.put(
      Uri.https(
        Constants.BASE_API_URL,
        '${Constants.BASE_API_USERFAVORITE}/$userId/$id.json',
        {'auth': token},
      ),
      body: json.encode(isFavorite),
    );

    if (response.statusCode >= 400) {
      print(response.statusCode);
    } else {
      notifyListeners();
    }
  }
}
