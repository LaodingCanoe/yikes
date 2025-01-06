import 'package:flutter/material.dart';
import 'image_carousel.dart';
import 'db_class.dart';

enum LayoutType { vertical, horizontal, grid }
final dbHelper = DatabaseHelper();

class ProductCart extends StatefulWidget {
  final int? gendrCode;
  final int maxItems;
  final LayoutType layoutType;

  ProductCart({
    Key? key,
    required this.gendrCode,
    this.maxItems = 10,
    this.layoutType = LayoutType.vertical,
  }) : super(key: key);

  @override
  _ProductCartState createState() => _ProductCartState();
}

class _ProductCartState extends State<ProductCart> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  late Map<String, List<dynamic>> _groupedProducts;
  late Map<String, dynamic> _currentProducts; // Текущие выбранные товары по артикулу

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    _products = await DatabaseHelper.fetchProducts(
      gendrCode: widget.gendrCode,
      maxItems: widget.maxItems,
    );

    _groupedProducts = {};
    _currentProducts = {};

    // Группируем товары по артикулу
    for (var product in _products) {
      final article = product['Артикул'] ?? 'unknown';
      if (!_groupedProducts.containsKey(article)) {
        _groupedProducts[article] = [];
      }
      _groupedProducts[article]!.add(product);
    }

    // Устанавливаем текущий товар для каждого артикула
    for (var article in _groupedProducts.keys) {
      _currentProducts[article] = _groupedProducts[article]!.first;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _changeProductByColor(String article, dynamic product) {
  setState(() {
    _currentProducts[article] = product;
  });
}


  Widget buildProductCard(dynamic product) {
    final article = product['Артикул'] ?? '';
    final name = product['Название'] ?? 'Без названия';
    final store = product['Бренд'] ?? 'Без бренда';
    final price = product['Цена'] ?? 'Нет данных';
    final colorCode = product['КодЦвета'];

return Card(
  margin: EdgeInsets.all(8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      FutureBuilder<List<String>>(
        future: DatabaseHelper.fetchProductImages(product['ТоварID']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Image.asset(
              'assets/placeholder.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 150,
            );
          } else {
            return ProductImageCarousel(
              imageUrls: snapshot.data!,
            );
          }
        },
      ),
      Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 46, // Высота для двух строк текста
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: Text(
          '$price ₽',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 12, 12, 12),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
        child: Text(
          store,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            ..._groupedProducts[article]!.map((productVariant) {
              final variantColorCode = productVariant['КодЦвета'];
              return GestureDetector(
                onTap: () => _changeProductByColor(article, productVariant),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(int.parse(variantColorCode.replaceFirst('#', '0xff'))),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: product == productVariant
                          ? Color(0xFF333333)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                ),
              );
            }).toList(),
            Spacer(),
            IconButton(
              onPressed: () {
                // Добавить функционал для добавления в корзину
              },
              icon: Icon(Icons.shopping_cart),
              color: Color(0xFF333333),
            ),
          ],
        ),
      ),
    ],
  ),
);

  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_products.isEmpty) {
      return Center(child: Text('No products found.'));
    }

    final currentProductsList = _currentProducts.values.toList();

    if (widget.layoutType == LayoutType.grid) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 6.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 0,
          childAspectRatio: 0.46,
        ),
        itemCount: currentProductsList.length,
        itemBuilder: (context, index) {
          return buildProductCard(currentProductsList[index]);
        },
      );
    } else if (widget.layoutType == LayoutType.horizontal) {
      return SizedBox(
        height: 150,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 6.0),
          itemCount: currentProductsList.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: 150,
              width: (MediaQuery.of(context).size.width - 12.0) * 0.45,
              child: AspectRatio(
                aspectRatio: 0.46,
                child: buildProductCard(currentProductsList[index]),
              ),
            );
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: currentProductsList.length,
      itemBuilder: (context, index) {
        return buildProductCard(currentProductsList[index]);
      },
    );
  }
}
