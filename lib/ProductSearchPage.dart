import 'package:flutter/material.dart';
import 'ProductCart.dart';

class CategoryProductsPage extends StatefulWidget {
  final int gendrCode;
  final int? categoryId;
  final String? searchQuery;

  CategoryProductsPage({required this.gendrCode, this.categoryId, this.searchQuery});

  @override
  _CategoryProductsPageState createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  late String searchQuery;

  @override
  void initState() {
    super.initState();
    searchQuery = widget.searchQuery ?? ""; // Устанавливаем значение при инициализации
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Товары")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Поиск...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                ElevatedButton(onPressed: () {}, child: Text("Фильтр 1")),
                SizedBox(width: 10),
                ElevatedButton(onPressed: () {}, child: Text("Фильтр 2")),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ProductCart(
                  gendrCode: widget.gendrCode,
                  layoutType: LayoutType.grid,
                  categories: widget.categoryId,
                  subcategory: null,
                  shuffle: true,
                  searchQuery: searchQuery, // Передаем в ProductCart
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
