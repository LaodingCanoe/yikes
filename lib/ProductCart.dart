import 'package:flutter/material.dart';
import 'image_carousel.dart';
import 'db_class.dart';
import 'package:flutter/gestures.dart';
import 'shared_utils.dart';
import 'ProductPage.dart';
import 'dart:math';

final dbHelper = DatabaseHelper();
enum LayoutType { vertical, horizontal, grid }
final shared = SharedUtils();
final userdata = dbHelper.getLoginData();

class ProductCart extends StatefulWidget {
  final List<String>? categories;
  final List<String>? brands;
  final List<String>? colors;
  final List<String>? tags;
  final double? minPrice;
  final double? maxPrice;
  final String? search;
  final int? obraz;
  final List<String>? gender;
  final int? subcategory;
  final int maxItems;
  final LayoutType layoutType;
  final bool shuffle;
  final List<int>? excludeProductIds;
  final Map<String, dynamic> filters;
  final Function(int)? onProductsCountChanged;

  ProductCart({
    Key? key,
    this.gender,
    this.categories,
    this.subcategory,    
    this.minPrice = 0,
    this.maxPrice = 1000000,
    this.maxItems = 1000,
    this.layoutType = LayoutType.vertical,    
    this.obraz,
    this.shuffle = false,
    this.excludeProductIds,
    this.search,
    this.brands,
    this.tags,    
    this.colors,
    this.filters = const {},
    this.onProductsCountChanged,
  }) : super(key: key);

  @override
  _ProductCartState createState() => _ProductCartState();
}

class _ProductCartState extends State<ProductCart> {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  Future<List<String>>? _imagesFuture;
  bool _isLoading = true;
  int prodId = 0;
  late Map<String, List<dynamic>> _groupedProducts;
  late Map<String, dynamic> _currentProducts;
  double _minPrice = 0;
  double _maxPrice = 10000;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

@override
void didUpdateWidget(ProductCart oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.filters != widget.filters ||
      oldWidget.search != widget.search ||
      oldWidget.categories != widget.categories ||
      oldWidget.brands != widget.brands ||
      oldWidget.tags != widget.tags ||
      oldWidget.colors != widget.colors ||
      oldWidget.gender != widget.gender) {
    _loadProducts(); // Перезагружаем товары при изменении фильтров
  }
}

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
_products = await DatabaseHelper.fetchProducts(
  categories: widget.categories,
  brands: widget.brands,
  colors: widget.colors,
  tags: widget.tags,
  minPrice: widget.minPrice,
  maxPrice: widget.maxPrice,
  search: widget.search,
  obraz: widget.obraz,
  gender: widget.gender,
  subcategory: widget.subcategory,
  maxItems: widget.maxItems ?? 100000,
);


    if (widget.excludeProductIds != null) {
      _products.removeWhere((product) => widget.excludeProductIds!.contains(product['ТоварID']));
    }

    if (widget.shuffle) {
      _products.shuffle(Random());
    }

    if (_products.isNotEmpty) {
      _minPrice = _products
          .map((p) => (p['Цена'] ?? 0) as num) // Явно приводим к num
          .reduce((a, b) => a < b ? a : b)     // Находим минимум
          .toDouble();

      _maxPrice = _products
          .map((p) => (p['Цена'] ?? 0) as num) // Явно приводим к num
          .reduce((a, b) => a > b ? a : b)     // Находим максимум
          .toDouble();
    }

    _groupProducts();
    _applyFilters();
  }

  void _groupProducts() {
    _groupedProducts = {};
    _currentProducts = {};

    for (var product in _products) {
      final article = product['Артикул'] ?? 'unknown';
      prodId = product['ТоварID'];
      
      _imagesFuture = DatabaseHelper.fetchProductImages(prodId);
      if (!_groupedProducts.containsKey(article)) {
        _groupedProducts[article] = [];
      }
      _groupedProducts[article]!.add(product);
    }

    for (var article in _groupedProducts.keys) {
      _currentProducts[article] = _groupedProducts[article]!.first;
    }
  }

  void _applyFilters() {
  List<dynamic> filtered = List.from(_products);

  // Фильтр по цене
  if (widget.filters.containsKey('minPrice') && widget.filters.containsKey('maxPrice')) {
    filtered = filtered.where((product) {
      final price = product['Цена'] ?? 0;
      return price >= widget.filters['minPrice'] && price <= widget.filters['maxPrice'];
    }).toList();
  }

  // Фильтр по категориям (используем 'Категория', а не 'КатегорияID')
  if (widget.filters.containsKey('categories') && widget.filters['categories'].isNotEmpty) {
    filtered = filtered.where((product) {
      return widget.filters['categories'].contains(product['Категория']);
    }).toList();
  }

  // Фильтр по брендам (используем 'Бренд', а не 'БрендID')
  if (widget.filters.containsKey('brands') && widget.filters['brands'].isNotEmpty) {
    filtered = filtered.where((product) {
      return widget.filters['brands'].contains(product['Бренд']);
    }).toList();
  }

  // Фильтр по цветам
  if (widget.filters.containsKey('colors') && widget.filters['colors'].isNotEmpty) {
    filtered = filtered.where((product) {
      return widget.filters['colors'].contains(product['Цвет']);
    }).toList();
  }

  // Фильтр по тегам
  if (widget.filters.containsKey('tags') && widget.filters['tags'].isNotEmpty) {
    filtered = filtered.where((product) {
      final productTags = product['Теги'] as List<dynamic>? ?? [];
      return productTags.any((tag) => widget.filters['tags'].contains(tag['Название']));
    }).toList();
  }

  // Фильтр по полу
  if (widget.filters.containsKey('gender') && widget.filters['gender'].isNotEmpty) {
    filtered = filtered.where((product) {
      return widget.filters['gender'].contains(product['Гендер']);
    }).toList();
  }

  setState(() {
    _filteredProducts = filtered;
    _isLoading = false;
    widget.onProductsCountChanged?.call(_filteredProducts.length);
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

    if (isUserLoggedIn) {
      final isSuccess = await dbHelper.addToCart(productId, sizeId, userData["userId"], null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSuccess ? 'Товар добавлен в корзину!' : 'Не удалось добавить товар')),
      );
    } else {
      await dbHelper.fetchAndSaveCartData(sizeId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Товар добавлен в локальную корзину!')),
      );
    }
  }

  void _showSizeSelectionBottomSheet(BuildContext context, int productId) async {
    final sizes = await dbHelper.fetchProductSizes(productId);

    if (sizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Размеры недоступны для этого товара.')),
      );
      return;
    }

    if (sizes.length == 1) {
      final sizeId = sizes.first['РазмерID'];
      if (sizeId != null) {
        _addToCart(productId, sizeId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Товар с размером ${sizes.first['Размер']} добавлен в корзину.')),
        );
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Выберите размер', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
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
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageContent(dynamic product) {
    return FutureBuilder<List<String>>(
      future:  DatabaseHelper.fetchProductImages(product['ТоварID']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Image.asset(
            'assets/placeholder.png',
            fit: BoxFit.cover,
            width: double.infinity,
          );
        } else {
          return ProductImageCarousel(
            imageUrls: snapshot.data!,
            isCompact: true,
            fit: BoxFit.cover,
          );
        }
      },
    );
  }

  Widget buildProductCard(dynamic product) {
    final article = product['Артикул'] ?? '';
    final name = product['Название'] ?? 'Без названия';
    final price = product['Цена'] ?? 'Нет данных';
    final isMobile = MediaQuery.of(context).size.width < 400;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductPage(article: article),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            isMobile
                ? AspectRatio(
                    aspectRatio: 3 / 4,
                    child: _buildImageContent(product),
                  )
                : Expanded(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: _buildImageContent(product),
                    ),
                  ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '$price ₽',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: isMobile ? 0 : 20),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _groupedProducts[article]!.map((productVariant) {
                              final variantColorCode = productVariant['КодЦвета'];
                              return Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: GestureDetector(
                                  onTap: () => _changeProductByColor(article, productVariant),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Color(int.parse(variantColorCode.replaceFirst('#', '0xff'))),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: product == productVariant
                                            ? Colors.black
                                            : Colors.transparent,
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () {
                          _showSizeSelectionBottomSheet(context, product['ТоварID']);
                        },
                        icon: Icon(Icons.shopping_cart),
                        color: Colors.black,
                      ),
                    ],
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
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_filteredProducts.isEmpty) return Center(child: Text('Товары не найдены'));

    final currentProductsList = _currentProducts.values.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (widget.layoutType == LayoutType.grid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final aspectRatio = isMobile ? 0.49 : 0.63;
          final crossAxisCount = isMobile
              ? 2
              : constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                      ? 3
                      : 2;

          return GridView.builder(
            shrinkWrap: true,
            physics: ClampingScrollPhysics(),
            padding: EdgeInsets.all(0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: aspectRatio,
            ),
            itemCount: currentProductsList.length,
            itemBuilder: (context, index) {
              return buildProductCard(currentProductsList[index]);
            },
          );
        },
      );
    } else if (widget.layoutType == LayoutType.horizontal) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth * (isMobile ? 0.40 : 0.30);
          final cardHeight = cardWidth / (isMobile ? 0.47 : 0.63);

          return ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxHeight: cardHeight,
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 12),
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                itemCount: currentProductsList.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: cardWidth,
                    child: buildProductCard(currentProductsList[index]),
                  );
                },
                separatorBuilder: (context, index) => SizedBox(width: 12),
              ),
            ),
          );
        },
      );
    }

    // Вертикальный список
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: currentProductsList.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: buildProductCard(currentProductsList[index]),
        );
      },
    );
  }
}