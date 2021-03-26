import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/auth.dart';
import 'package:shop/providers/cart.dart';
import 'package:shop/providers/orders.dart';
import 'package:shop/providers/products.dart';
import 'package:shop/utils/appRoutes.dart';
import 'package:shop/utils/customRoute.dart';
import 'package:shop/views/authHomeScreen.dart';
import 'package:shop/views/cartScreen.dart';
import 'package:shop/views/ordersScreen.dart';
import 'package:shop/views/productDetailScreen.dart';
import 'package:shop/views/productFormScreen.dart';
import 'package:shop/views/productsOverviewScreen.dart';
import 'package:shop/views/productsScreen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => new Auth(),
        ),
        ChangeNotifierProxyProvider<Auth, Products>(
          create: (_) => new Products(),
          update: (ctx, auth, previousProducts) => new Products(
            auth.token,
            previousProducts.items,
            auth.userId,
          ),
        ),
        ChangeNotifierProxyProvider<Auth, Orders>(
          create: (_) => new Orders(),
          update: (ctx, auth, previousOrders) => new Orders(
            auth.token,
            auth.userId,
            previousOrders.items,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => new Cart(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Minha Loja',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          accentColor: Colors.deepOrange,
          fontFamily: 'Lato',
          pageTransitionsTheme: PageTransitionsTheme(
            builders: {
              TargetPlatform.android: CustomPageTransition(),
              TargetPlatform.iOS: CustomPageTransition(),
            },
          ),
        ),
        routes: {
          AppRoutes.AUTH_HOME: (ctx) => AuthOrHomeScreen(),
          AppRoutes.HOME: (ctx) => ProductsOverviewScreen(),
          AppRoutes.PRODUCT_DETAIL: (ctx) => ProductDetailScreen(),
          AppRoutes.CART: (ctx) => CartScreen(),
          AppRoutes.ORDERS: (ctx) => OrderScreen(),
          AppRoutes.PRODUCTS: (ctx) => ProductsScreen(),
          AppRoutes.PRODUCTFORM: (ctx) => ProductFormScreen(),
        },
      ),
    );
  }
}
