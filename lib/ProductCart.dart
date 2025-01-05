import 'package:flutter/material.dart';
import 'image_carousel.dart';
import 'db_class.dart';

enum LayoutType { vertical, horizontal, grid }
final dbHelper = DatabaseHelper();
class ProductCart extends StatefulWidget {
  final int gendrCode;
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

Future<void> _loadProducts() async {
  _products = await DatabaseHelper.fetchProducts(widget.gendrCode, maxItems: widget.maxItems);
  setState(() {
    _isLoading = false;
  });
}

   Widget buildProductCard(dynamic product) {
    final id = product['ТоварID'] ?? '';
    final name = product['Название'] ?? 'Без названия';
    final store = product['Бренд'] ?? 'Без бренда';
    final price = product['Цена'] ?? 'Нет данных';
    final color = product['КодЦвета'];

    return Card(
    margin: EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<String>>(
          future: DatabaseHelper.fetchProductImages(id),
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
            padding: const EdgeInsets.only(bottom: 0),
            child: Center(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 101, 64, 124),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'В корзину',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
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

    if (widget.layoutType == LayoutType.grid) {
      return GridView.builder(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 6.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 0,
          childAspectRatio: 0.46,
        ),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          return buildProductCard(_products[index]);
        },
      );
    } else if (widget.layoutType == LayoutType.horizontal) {
      return SizedBox(
        height: 150,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 6.0),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: 150,
              width: (MediaQuery.of(context).size.width - 12.0) * 0.45,
              child: AspectRatio(
                aspectRatio: 0.46,
                child: buildProductCard(_products[index]),
              ),
            );
          },
        ),
      );
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return buildProductCard(_products[index]);
      },
    );
  }
}