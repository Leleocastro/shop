import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shop/data/store.dart';
import 'package:shop/exceptions/authException.dart';
import 'package:shop/utils/constants.dart';

class Auth with ChangeNotifier {
  DateTime _expiryDate;
  String _token;
  String _userId;
  Timer _logoutTimer;

  bool get isAuth {
    return token != null;
  }

  String get userId {
    return isAuth ? _userId : null;
  }

  String get token {
    if (_token != null &&
        _expiryDate != null &&
        _expiryDate.isAfter(DateTime.now())) {
      return _token;
    } else {
      return null;
    }
  }

  // Constants(_token);
  final Uri _urlSignup = Uri.https(Constants.BASE_API_AUTH,
      Constants.BASE_API_AUTH_SIGNUP, {'key': Constants.BASE_API_AUTH_KEY});
  final Uri _urlLogin = Uri.https(Constants.BASE_API_AUTH,
      Constants.BASE_API_AUTH_LOGIN, {'key': Constants.BASE_API_AUTH_KEY});

  Future<void> loginSignup(String email, String password, bool segment) async {
    final response = await http.post(
      segment ? _urlLogin : _urlSignup,
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    final responseBody = json.decode(response.body);
    if (responseBody["error"] != null) {
      throw AuthException(responseBody["error"]["message"]);
    } else {
      _userId = responseBody['localId'];
      _token = responseBody["idToken"];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(responseBody["expiresIn"]),
        ),
      );

      Store.saveMap('userData', {
        "token": _token,
        "userId": _userId,
        "expiryDate": _expiryDate.toIso8601String(),
      });

      _autoLogout();
      notifyListeners();
    }

    return Future.value();
  }

  Future<void> tryAutoLogin() async {
    if (isAuth) {
      return Future.value();
    }

    final userData = await Store.getMap('userData');
    if (userData == null) {
      return Future.value();
    }

    final expiryDate = DateTime.parse(userData["expiryDate"]);
    if (expiryDate.isBefore(DateTime.now())) {
      return Future.value();
    }

    _userId = userData["userId"];
    _token = userData["token"];
    _expiryDate = expiryDate;

    _autoLogout();
    notifyListeners();

    return Future.value();
  }

  void logout() {
    _token = null;
    _userId = null;
    _expiryDate = null;
    if (_logoutTimer != null) {
      _logoutTimer.cancel();
      _logoutTimer = null;
    }
    Store.remove('userData');
    notifyListeners();
  }

  void _autoLogout() {
    if (_logoutTimer != null) {
      _logoutTimer.cancel();
    }
    final timeToLogout = _expiryDate.difference(DateTime.now()).inSeconds;
    _logoutTimer = Timer(Duration(seconds: timeToLogout), logout);
  }
}
