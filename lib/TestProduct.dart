import 'package:flutter/material.dart';
import 'ProductCart.dart';

void main() {
  runApp(ProductListPage());
}

class ProductListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Product List',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: ProductPage(),
    );
  }
}

class ProductPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ProductCart(
        gendrCode: 1,
        maxItems: 10,
        layoutType: LayoutType.horizontal,
      ),
    );
  }
}
