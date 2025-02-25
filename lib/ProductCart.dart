import 'package:flutter/material.dart';
import 'image_carousel.dart';
import 'db_class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'shared_utils.dart';
import 'ProductPage.dart';
import 'dart:math';
enum LayoutType { vertical, horizontal, grid }
final dbHelper = DatabaseHelper();
final shared = SharedUtils();
final userdata = dbHelper.getLoginData();

class ProductCart extends StatefulWidget {
  final int? gendrCode;
  final int? obraz;
  final int? categories;
  final int? subcategory;
  final int maxItems;
  final LayoutType layoutType;
  final String? hashtag;
  final bool shuffle;
  final List<int>? excludeProductIds;
  final String? searchQuery;

  ProductCart({
    Key? key,
    this.gendrCode,
    this.categories = null,
    this.subcategory = null,
    this.maxItems = 1000,
    this.layoutType = LayoutType.vertical,
    this.hashtag = null,
    this.obraz = null,
    this.shuffle = false,
    this.excludeProductIds,
    this.searchQuery = null,
  }) : super(key: key);

  @override
  _ProductCartState createState() => _ProductCartState();
}

class _ProductCartState extends State<ProductCart> {
  List<dynamic> _products = [];
  Future<List<String>>? _imagesFuture;
  bool _isLoading = true;
  int prodId = 0;
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
      hashtag: widget.hashtag,
      obraz: widget.obraz,
      categoryId: widget.categories,
      subcategory: widget.subcategory,
      search: widget.searchQuery,
    );
    if (widget.excludeProductIds != null) {
      _products.removeWhere((product) => widget.excludeProductIds!.contains(product['ТоварID']));
    }

    // Перемешиваем список, если указано
    if (widget.shuffle) {
      _products.shuffle(Random());
    }

    _groupedProducts = {};
    _currentProducts = {};

    // Группируем товары по артикулу
    for (var product in _products) {
      final article = product['Артикул'] ?? 'unknown';
      prodId = product['ТоварID'];
      
      _imagesFuture =  DatabaseHelper.fetchProductImages(prodId);
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
void _addToCart(int productId, int sizeId) async {
  final userData = await dbHelper.getLoginData();
  bool isUserLoggedIn = userData["userId"] != null;
  print('login? ${isUserLoggedIn}');

  if (isUserLoggedIn) {
    // Если пользователь авторизован, сохраняем в базе данных
    final isSuccess = await dbHelper.addToCart(productId, sizeId, userData["userId"], null);
    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Товар добавлен в корзину!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось добавить товар в корзину.')),
      );
    }
  } else {
    // Если пользователь не авторизован, сохраняем в локальное хранилище
    print('size: ${sizeId}');
    await dbHelper.fetchAndSaveCartData(sizeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Товар добавлен в локальную корзину!')),
    );
  }
}


void _showSizeSelectionBottomSheet(BuildContext context, int productId) async {
  final sizes = await dbHelper.fetchProductSizes(productId);

  if (sizes.isEmpty) {
    // Если размеры недоступны, выводим сообщение
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Размеры недоступны для этого товара.')),
    );
    return;
  }

  if (sizes.length == 1) {
    // Если доступен только один размер, сразу добавляем товар в корзину
    final sizeId = sizes.first['РазмерID'];
    if (sizeId != null) {
      _addToCart(productId, sizeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Товар с размером ${sizes.first['Размер']} добавлен в корзину.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: РазмерID отсутствует.')),
      );
    }
    return;
  }

  // Если доступно несколько размеров, показываем плашку
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        height: sizes.length * 80.0, // Высота плашки зависит от количества размеров
        child: ListView.builder(
          shrinkWrap: true, // Make sure this is within ListView
          physics: NeverScrollableScrollPhysics(),
          itemCount: sizes.length,
          itemBuilder: (context, index) {
            final size = sizes[index];
            return ListTile(
              title: Text('${size['Размер']}'),
              subtitle: Text('На складе: ${size['КоличествоНаСкладе']}'),
              onTap: () {
                final sizeId = size['РазмерID'];
                if (sizeId != null) {
                  _addToCart(productId, sizeId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Вы выбрали размер ${size['Размер']}.',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: РазмерID отсутствует.')),
                  );
                }
              },
            );
          },
        ),
      );
    },
  );
}



Widget buildProductCard(dynamic product) {
  final article = product['Артикул'] ?? '';
  final name = product['Название'] ?? 'Без названия';
  final store = product['Бренд'] ?? 'Без бренда';
  final price = product['Цена'] ?? 'Нет данных';
  final colorCode = product['КодЦвета'];

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductPage(article: article),
        ),
      );
    },
    child: Card(
      margin:  EdgeInsets.only(left: 0.0, right: 0,  top: 0,  bottom: 20) ,
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
                  isCompact: true,
                );
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              height: 46,
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
                    _showSizeSelectionBottomSheet(context, product['ТоварID']);
                  },
                  icon: Icon(Icons.shopping_cart),
                  color: Color(0xFF333333),
                ),
              ],
            ),
          ),
        ],
      ),
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
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
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
