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
  String _selectedColor = "";
  int? _selectedSize;
  int _cartQuantity = 0;
  int productId = 0;
  Future<Map<String, dynamic>?>? sizesForSelectedColor;
  bool obraz = false;
  Future<List<String>>? _imagesFuture;
  Future<List<Map<String, dynamic>>>? _sizesFuture;
  int userID = 0;
  bool _isFullScreen = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();  
    _initializeUserData();
    _productFuture = dbHelper.fetchProduct(widget.article);
    _productFuture?.then((product) {
      if (product != null) {      
        if (product['obraz'] != null){
          obraz = true;
        } else {
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

  Future<void> _initializeUserData() async {
    final userData = await dbHelper.getLoginData();
    if (userData != null && userData["userId"] != null) {
      setState(() {
        userID = userData["userId"] as int;
      });
    }
    print("UserID: $userID");
  }

  void _selectColor(String color, Map<String, dynamic> product) async {
    setState(() {
      _selectedColor = color;
      _selectedSize = null;
      _cartQuantity = 0;
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
      _cartQuantity = 0;
    });
    await _updateCartQuantity(productId, sizeId);
  }

  Future<void> _updateCartQuantity(int productId, int sizeId) async {
    final cartItems = await dbHelper.fetchCart(userId: userID, productID: productId, sizeID: sizeId);
    
    print('productID in cart: ${productId}');
    if (cartItems.isNotEmpty) {
      setState(() {
        _cartQuantity = cartItems[0]['Количество'];
      });
    } else {
      setState(() {
        _cartQuantity = 0;
      });
    }
  }

  Future<void> _addToCart(int productId, int sizeId, int userId) async {
    if (productId == 0 || sizeId == 0 || userId == 0) {
      print('Ошибка: некорректные параметры для добавления в корзину');
      return;
    }
    print('productId:${productId}, userID:${userId}, sizeId:${sizeId}');
    await dbHelper.addToCart(productId, sizeId, userId, null);
    setState(() {
      _cartQuantity = 1;
    });
  }

  Future<void> _updateCart(int productId, int? sizeId, bool isIncrement, int userId) async {
    if (productId == 0 || sizeId == null || userId == 0) {
      print('Ошибка: некорректные параметры для обновления корзины');
      return;
    }
    await dbHelper.updateCart(productID: productId, sizeID: sizeId, plus: isIncrement, userID: userId);
    setState(() {
      _cartQuantity += isIncrement ? 1 : -1;
    });
  }

  Future<void> _removeFromCart(int productId, int? sizeId, int userId) async {
    if (productId == 0 || sizeId == null || userId == 0) {
      print('Ошибка: некорректные параметры для удаления из корзины');
      return;
    }
    await dbHelper.deleteCart(productID: productId, sizeID: sizeId, userID: userId);
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

   Widget _buildImageContent(BuildContext context, List<String> imageUrls, {bool isFullScreen = false}) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: imageUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                if (isFullScreen) {
                  Navigator.pop(context);
                } else {
                  _showFullScreenImage(context, imageUrls);
                }
              },
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            );
          },
        ),
        if (!isFullScreen)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  void _showFullScreenImage(BuildContext context, List<String> imageUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: _buildImageContent(context, imageUrls, isFullScreen: true),
          ),
        ),
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

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
                  child: isLargeScreen
                      ? _buildLargeScreenLayout(product, context)
                      : _buildMobileLayout(product, context),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: _buildBottomBar(product, isLargeScreen),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLargeScreenLayout(Map<String, dynamic> product, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Левая половина - изображение
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 3 / 4,
                        child: FutureBuilder<List<String>>(
                          future: DatabaseHelper.fetchProductImages(product['id']),
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
                              return GestureDetector(
                                onTap: () => _showFullScreenImage(context, snapshot.data!),
                                child: _buildImageContent(context, snapshot.data!),
                              );
                            }
                          },
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
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
                ),
              ),
              // Правая половина - информация о товаре
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${product['price']} ₽',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 12, 12, 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildColorSelection(product),
                      const SizedBox(height: 24),
                      _buildSizeSelection(product),
                      const SizedBox(height: 24),
                      _buildDescription(product, context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (obraz) _buildObrazSection(product),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Map<String, dynamic> product, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 3 / 4,
              child: FutureBuilder<List<String>>(
                future: DatabaseHelper.fetchProductImages(product['id']),
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
              ),
            ),
            Positioned(
              top: 40,
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
                  color: Color.fromARGB(255, 12, 12, 12),
                ),
              ),
              const SizedBox(height: 16),
              _buildColorSelection(product),
              const SizedBox(height: 16),
              _buildSizeSelection(product),
              const SizedBox(height: 16),
              _buildDescription(product, context),
              if (obraz) ...[
                const SizedBox(height: 20),
                _buildObrazSection(product),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelection(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildSizeSelection(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Размеры:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
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
                  if (sizeValue == null) return const SizedBox();
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
      ],
    );
  }

  Widget _buildDescription(Map<String, dynamic> product, BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDescriptionExpanded = !_isDescriptionExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
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
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObrazSection(Map<String, dynamic> product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Собери весь образ',
          style: TextStyle(
            fontFamily: 'Standart',
            fontSize: 36,
            fontWeight: FontWeight.w500, 
          ),
        ),
        SizedBox(
          height: 450,
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
        const SizedBox(height: 20),
        const Text(
          'Похожее',
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
                gender: [product['gender']],
                layoutType: LayoutType.grid,
                categories: [product['category']],
                excludeProductIds: [product['id']],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> product, bool isLargeScreen) {
    if (_cartQuantity == 0) {
      return ElevatedButton(
        onPressed: (_selectedColor != null && _selectedSize != null)
            ? () => _addToCart(productId, _selectedSize!, userID)
            : null,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: const Color(0xFF333333),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text('Добавить в корзину', style: TextStyle(color: Colors.white)),
      );
    } else {
      if (isLargeScreen) {
        return Row(
          children: [
            Expanded(
              child: Text(
                product['name'],
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${product['price']} ₽',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            FutureBuilder(
              future: _sizesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || 
                    !snapshot.hasData || 
                    _selectedSize == null) {
                  return const SizedBox();
                }
                
                final sizes = snapshot.data!;
                return DropdownButton<int>(
                  value: _selectedSize,
                  items: sizes.map<DropdownMenuItem<int>>((size) {
                    return DropdownMenuItem<int>(
                      value: size['РазмерID'],
                      child: Text(size['Размер']),
                    );
                  }).toList(),
                  onChanged: (value) => _selectSize(value!),
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 50),
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'В корзине',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
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
        );
      } else {
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF333333),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'В корзине',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Expanded(
              flex: 1,
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
        );
      }
    }
  }    
  
}