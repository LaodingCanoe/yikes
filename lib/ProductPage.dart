import 'package:flutter/material.dart';
import 'db_class.dart';
import 'image_carousel.dart';
import 'ProductCart.dart';

final dbHelper = DatabaseHelper();

class ProductPage extends StatefulWidget {
  final String article;

  const ProductPage({Key? key, required this.article}) : super(key: key);

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Future<Map<String, dynamic>?>? _productFuture;
  bool _isDescriptionExpanded = false;
  String _selectedColor ="";
  int? _selectedSize;
  int _cartQuantity = 0;
  int productId = 0;
  Future<Map<String, dynamic>?>? sizesForSelectedColor;
  bool obraz = false;
  Future<List<String>>? _imagesFuture;
  Future<List<Map<String, dynamic>>>? _sizesFuture;
  int userID = 0;

@override
void initState() {
  super.initState();  
  _initializeUserData();
  _productFuture = dbHelper.fetchProduct(widget.article);
  _productFuture?.then((product) {
    if (product != null) {      
      if (product['obraz'] != null){
        obraz = true;
      }
      else{
        obraz = false;
      }
      final initialColor = product['colors'].isNotEmpty ? product['colors'][0]['code'] : null;
      dbHelper.fetchProductSizesByColorCode(product['article'], product['colors'][0]['code'])
        .then((initialSizes) {
          setState(() {
            _selectedColor = initialColor;
            _selectedSize = initialSizes.isNotEmpty ? initialSizes[0]['id'] : null;
            _imagesFuture = DatabaseHelper.fetchProductImages(product['id']);
            _sizesFuture = dbHelper.fetchProductSizesByColorCode(product['article'], _selectedColor);
            productId = product['id'];
          });
        });
    }
  });
}
// @override
// void didChangeDependencies() {
//     super.didChangeDependencies();
//     initState();
// }
Future<void> _initializeUserData() async {
    final userData = await dbHelper.getLoginData();
    setState(() {
      userID = userData["userId"] ?? 0;
    });
    print("UserID: $userID");
  }

void _selectColor(String color, Map<String, dynamic> product) async {
  setState(() {
    _selectedColor = color;
    _selectedSize = null; // Сброс размера при смене цвета
    _cartQuantity = 0; // Сброс количества в корзине
  });
  final sizesForSelectedColor = await dbHelper.fetchProductSizesByColorCode(
    product['article'], color
  );
  productId = sizesForSelectedColor[0]['ТоварID'];
    _imagesFuture = DatabaseHelper.fetchProductImages(productId);
    _sizesFuture = dbHelper.fetchProductSizesByColorCode(product['article'], _selectedColor);

  if (sizesForSelectedColor.isNotEmpty) {
    
      setState(() {
        _selectedSize = sizesForSelectedColor[0]['id'];
      });    
  }
}

void _selectSize(int sizeId) async {
  setState(() {
    _selectedSize = sizeId;
    _cartQuantity = 0; // Сброс количества в корзине
  });

  // Проверка, есть ли этот товар в корзине
  await _updateCartQuantity(productId, sizeId);
}

Future<void> _updateCartQuantity(int productId, int sizeId) async {
  final cartItems = await dbHelper.fetchCart(userId: userID, productID: productId, sizeID: sizeId);
  
  print('productID in cart: ${productId}');
  if (cartItems.isNotEmpty) {
    setState(() {
      _cartQuantity = cartItems[0]['Количество']; // Получаем количество в корзине
    });
  } else {
    setState(() {
      _cartQuantity = 0;
    });
  }
}
Future<void> _addToCart(int productId, int sizeId, int userId) async {
  print('productId:${productId}, userID:${userId}, sizeId:${sizeId}');
  await dbHelper.addToCart(productId, sizeId, userId, null);
  setState(() {
    _cartQuantity = 1;
  });
}

Future<void> _updateCart(int productId, int? sizeId, bool isIncrement, int userId) async {
  await dbHelper.updateCart(productID: productId, sizeID: sizeId, plus: isIncrement, userID: userId);
  setState(() {
    _cartQuantity += isIncrement ? 1 : -1;
  });
}

Future<void> _removeFromCart(int productId, int? _selectedSize, int userId) async {
  await dbHelper.deleteCart(productID: productId, sizeID:_selectedSize, userID: userId);
  setState(() {
    _cartQuantity = 0;
  });
}

 void _onCategoryTap(String category) {
  // Логика перехода на страницу категории
}

void _onBrandTap(String brand) {
  // Логика перехода на страницу бренда
}

void _onHashtagTap(String hashtag) {
  // Логика обработки нажатия на хэштег
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Ошибка загрузки данных'));
          }
          final product = snapshot.data!;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          FutureBuilder<List<String>>(
                            future: _imagesFuture,
                            builder: (context, imageSnapshot) {
                              return SizedBox(
                                height: 550,
                                width: double.infinity,
                                child: imageSnapshot.connectionState == ConnectionState.waiting
                                    ? const Center(child: CircularProgressIndicator())
                                    : imageSnapshot.hasError || !imageSnapshot.hasData || imageSnapshot.data!.isEmpty
                                        ? Image.asset('assets/placeholder.png', fit: BoxFit.cover)
                                        : ProductImageCarousel(imageUrls: imageSnapshot.data!, isCompact: false),
                              );
                            },
                          ),
                          Positioned(
                            top: 40, // Отступ от верхнего края экрана, чтобы не залезать на строку уведомлений
                            left: 16,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['name'],
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${product['price']} ₽',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 12, 12, 12),)
                            ),
                            const SizedBox(height: 16),
                            Text('Цвета:', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              children: product['colors'].map<Widget>((color) {
                                final colorCode = color['code'];
                                print("colorcode: ${colorCode}");
                                return GestureDetector(
                                  onTap: () => _selectColor(colorCode, product),
                                  child: CircleAvatar(
                                    backgroundColor: Color(int.parse(colorCode.replaceAll('#', '0xff'))),
                                    radius: 20,
                                    child: _selectedColor == colorCode
                                        ? const Icon(Icons.check, color: Colors.white)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          // Размеры
                          Text('Размеры:', style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                          // if (_getSizesForSelectedColor(product).isEmpty)
                            //   const Text('Нет доступных размеров для выбранного цвета'),
                            FutureBuilder(
                              future: _sizesFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Text('Нет доступных размеров');
                                } else {
                                  final sizes = snapshot.data!;
                                  return Wrap(
                                  spacing: 8.0,
                                  children: sizes.map<Widget>((size) {
                                    final sizeId = size['РазмерID'];
                                    final sizeValue = size['Размер'];
                                    if (sizeValue == null) return const SizedBox(); // Пропускаем, если значение null
                                      return ElevatedButton(
                                      onPressed: () => _selectSize(sizeId),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _selectedSize == sizeId ? const Color(0xFF333333) : const Color(0xFFC7C7C7),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10.0),
                                        ),
                                      ),
                                      child: Text(
                                        sizeValue,
                                        style: TextStyle(
                                        color: _selectedSize == sizeId ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      );
                                    }).toList(),
                                );                          
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            // Описание
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isDescriptionExpanded = !_isDescriptionExpanded;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity, // Растягиваем на весь экран
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white, // Цвет плашки изменён на белый
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Описание:',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        Icon(
                                          _isDescriptionExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                          size: 24,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutQuad,
                                      child: _isDescriptionExpanded
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _onCategoryTap(product['category']),
                                                  child: Text(
                                                    '${product['category']} > ${product['subcategory']}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                          fontWeight: FontWeight.bold,
                                                          color: Color.fromARGB(255, 67, 60, 60),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  product['description']?.trim() ?? 'Нет описания',
                                                  style: Theme.of(context).textTheme.bodyMedium,
                                                ),
                                                const SizedBox(height: 8),
                                                // Хэштеги
                                                Wrap(
                                                  spacing: 8.0,
                                                  runSpacing: 8.0,
                                                  children: product['hashtags'].map<Widget>((hashtag) {
                                                    return GestureDetector(
                                                      onTap: () => _onHashtagTap(hashtag['name']),
                                                      child: Chip(
                                                        label: Text(
                                                          '#${hashtag['name']}',
                                                          style: const TextStyle(color: Colors.white),
                                                        ),
                                                        backgroundColor: Color.fromARGB(255, 67, 60, 60),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                                const SizedBox(height: 8),

                                                // Бренд
                                                GestureDetector(
                                                  onTap: () => _onBrandTap(product['brand']),
                                                  child: Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 20,
                                                        backgroundImage: AssetImage('assets/brand_logo.png'),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        product['brand'],
                                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                              color: Color.fromARGB(255, 67, 60, 60),
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const SizedBox(), // Когда скрыто, занимает 0 места
                                    ),
                                  ],
                                ),
                              ),
                            ),                                                    
                            ],
                        ),
                      ),
                      if (obraz) ...[
                        const SizedBox(height: 20),
                        const Text(
                          '  Собери весь образ',
                          style: TextStyle(
                            fontFamily: 'Standart',
                            fontSize: 36,
                            fontWeight: FontWeight.w500, 
                          ),
                        ),
                        SizedBox(
                          height: 426,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return ProductCart(          
                                layoutType: LayoutType.horizontal,
                                obraz: product['obraz'],
                                excludeProductIds: [product['id']],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),const Text(
                          '  Похожее',
                          style: TextStyle(
                            fontFamily: 'Standart',
                            fontSize: 36,
                            fontWeight: FontWeight.w500, 
                          ),
                        ),
                        SizedBox(                          
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return ProductCart(
                                gendrCode: product['genderId'],
                                layoutType: LayoutType.grid,
                                categories: product['categoryId'],
                                excludeProductIds: [product['id']],
                              );
                            },
                          ),
                        ),

                        
                      ]
                    ],                    
                  ),                  
                ),                
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: _cartQuantity == 0
                      ? ElevatedButton(
                          onPressed: (_selectedColor != null && _selectedSize != null)
                              ? () => _addToCart(productId, _selectedSize!, userID)
                              : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            backgroundColor: const Color(0xFF333333),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Добавить в корзину',  style: TextStyle(color: Colors.white)),
                        )
                      :Row(
                        children: [
                          Expanded(
                            flex: 1, // Половина строки
                            child: ElevatedButton(
                              onPressed: () {
                                // Действие при нажатии
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                backgroundColor: const Color(0xFF333333),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text(
                                'В корзине',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1, // Вторая половина для кнопок и количества
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: () => _cartQuantity == 1
                                      ? _removeFromCart(product['id'], _selectedSize, userID)
                                      : _updateCart(product['id'], _selectedSize, false, userID),
                                  icon: const Icon(Icons.remove),
                                ),
                                Text('$_cartQuantity', style: const TextStyle(fontSize: 18)),
                                IconButton(
                                  onPressed: () => _updateCart(product['id'], _selectedSize, true, userID),
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}