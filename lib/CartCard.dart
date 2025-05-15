import 'package:flutter/material.dart';
import 'image_carousel.dart';
import 'db_class.dart';
import 'checkout_screen.dart';

final dbHelper = DatabaseHelper();

class CartScreen extends StatefulWidget {
  final VoidCallback? onTabSelected;

  const CartScreen({this.onTabSelected, Key? key}) : super(key: key);

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  late Future<List<dynamic>> _cartItems;
  int userID = 0;
  bool selectAll = false;
  Set<int> selectedItems = {}; // Хранит ID выбранных товаров

 
  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }
  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  _loadCartItems();
}



  void refreshCart() {
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final userData = await dbHelper.getLoginData();
    setState(() {
      userID = userData["userId"] ?? 0;
    });
    print("UserID: $userID");
    _loadCartItems();
  }

Future<void> _loadCartItems() async {
  List<dynamic> items;
  if (userID == 0) {
    items = await dbHelper.getCartData();
  } else {
    items = await dbHelper.fetchCart(userId: userID);
  }
  setState(() {
    _cartItems = Future.value(items);
  });
}



  void _updateSelectAll(bool value, List<dynamic> cartItems) {
  setState(() {
    selectAll = value;
    selectedItems = value
        ? cartItems.map<int>((item) => item['ТоварРазмерID']).toSet()
        : {};
  });
}
   double _calculateTotalPrice(List<dynamic> cartItems) {
    return cartItems
        .where((item) => selectedItems.contains(item['ТоварРазмерID']))
        .fold(0.0, (total, item) => total + (item['Цена'] * item['Количество']));
   }

  @override
void didUpdateWidget(covariant CartScreen oldWidget) {
  super.didUpdateWidget(oldWidget);
  Future.microtask(() => _loadCartItems());
}
  Future<void> _confirmDeletion(BuildContext context, int productSizeID) async {
    bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: Text("Удаление товара"),
            content: Text("Вы уверены, что хотите удалить этот товар?"),
            actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Отмена"),
                ),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text("Удалить", style: TextStyle(color: Colors.red)),
                ),
            ],
        ),
    );

    if (confirm == true) {
        await dbHelper.deleteCart(product_sizeID: productSizeID, userID: userID);
        await _loadCartItems();
    }
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(     
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [                
                Row(
                  children: [
                    Checkbox(
                      checkColor: Colors.white,
                      activeColor: const Color(0xFF333333),
                      value: selectAll,
                      onChanged: (value) {
                        setState(() {                          
                          selectAll = value ?? false;
                          _cartItems.then((cartItems) {
                          _updateSelectAll(value ?? false, cartItems);});
                        });
                      },
                    ),
                    Text('Выбрать всё',
                        style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 5,
                      ),
                      ),
                    Spacer(),
                    ElevatedButton(                      
                      onPressed: selectedItems.isNotEmpty
                      ? () {
                          for (var itemId in selectedItems) {
                            dbHelper.deleteCart(product_sizeID: itemId, userID: userID); 
                            selectAll = false;
                          }
                          _loadCartItems();
                        }
                      : null,
                      style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 194, 64, 64),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:  BorderRadius.circular(10),
                      ),
                    ),
                  child: Text('Удалить выбранное',
                        style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 5,
                      ),),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _cartItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки корзины: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('Корзина пуста'));
                } else {
                  final cartItems = snapshot.data!;
                  return ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return CartItemCard(
                        item: item,
                        userID: userID,
                        isSelected: selectedItems.contains(item['ТоварРазмерID']),
                        onSelected: (isSelected) {
                          setState(() {
                            if (isSelected) {
                              selectedItems.add(item['ТоварРазмерID']);
                            } else {
                              selectedItems.remove(item['ТоварРазмерID']);
                            }
                            selectAll = selectedItems.length == cartItems.length;
                          });
                        },
                        onQuantityChanged: (newQuantity) async {
                        if (userID == 0) {
                          final currentCart = await dbHelper.getCartData();
                          final itemIndex = currentCart.indexWhere((i) => i['ТоварРазмерID'] == item['ТоварРазмерID']);
                          if (itemIndex != -1) {
                            currentCart[itemIndex]['Количество'] = newQuantity;
                            await dbHelper.saveCartToStorage(currentCart);
                          }
                        } else {
                          await dbHelper.updateCart(productID: item['ТоварРазмерID'], plus: newQuantity > item['Количество'], userID: userID);
                        }
                        setState(() {
                          _loadCartItems();
                        });
                      },
                        onDelete: () async {
                          await _confirmDeletion(context, item['ТоварРазмерID']);
                        },

                        onUpdateCart: _loadCartItems,
                      );
                    },
                  );
                }
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<List<dynamic>>(
                  future: _cartItems,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        '${_calculateTotalPrice(snapshot.data!).toStringAsFixed(2)} ₽',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      );
                    } else {
                      return Text('0 ₽',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                    }
                  },
                ),
                ElevatedButton(
                  onPressed: selectedItems.isNotEmpty
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutScreen(
                              selectedItems: selectedItems,
                              userID: userID,
                            ),
                          ),
                        );
                      }
                    : null,
                     
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Color(0xFFC7C7C7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                      ),
                  ),
                  child: const Text('Перейти к оформлению',
                  style: TextStyle(
                    color: Colors.white,
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 1,
                      ),),
              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class CartItemCard extends StatelessWidget {
  final dynamic item;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final int userID; // Добавляем userID как параметр
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDelete;
  final VoidCallback onUpdateCart;
  

  CartItemCard({
    required this.item,
    required this.userID, // Добавляем userID в конструктор
    required this.isSelected,
    required this.onSelected,
    required this.onQuantityChanged,
    required this.onDelete,
    required this.onUpdateCart,
  });

void _addToCart(int productId, int sizeId) async {
  final userData = await dbHelper.getLoginData();
  bool isUserLoggedIn = userData["userId"] != null;
  print('login? ${isUserLoggedIn}');

  if (isUserLoggedIn) {
    // Если пользователь авторизован, сохраняем в базе данных
    
    dbHelper.deleteCart(product_sizeID: item['ТоварРазмерID'], userID: userID);
    final isSuccess = await dbHelper.addToCart(productId, sizeId, userData["userId"], null);
      
  onUpdateCart();  
  
    
  } else {
    // Если пользователь не авторизован, сохраняем в локальное хранилище
    print('size: ${sizeId}');
    await dbHelper.fetchAndSaveCartData(sizeId);
    
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

@override
Widget build(BuildContext context) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  FutureBuilder<List<String>>(
                    future: DatabaseHelper.fetchProductImages(item['ТоварID']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SizedBox(
                          width: 150,
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Image.asset(
                          'assets/placeholder.png',
                          fit: BoxFit.cover,
                          width: 100,
                          height: 150,
                        );
                      } else {
                        return SizedBox(
                          width: 100,
                          height: 150,
                          child: ProductImageCarousel(
                            imageUrls: snapshot.data!,
                            isCompact: true,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 46, // Высота для двух строк текста
                          child: Text(
                            item['Название'] ?? 'Название товара',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${item['Цена']} ₽',
                        style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 5,
                      ),
                        ),
                        SizedBox(height: 8),
                        // Цвета и размеры
                        Row(
                          children: [
                            if (item['КодЦвета'] != null)
                              GestureDetector(
                                onTap: () {
                                  // Логика для изменения цвета
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(item['КодЦвета'].replaceFirst('#', '0xff'))),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                 _showSizeSelectionBottomSheet(context, item['ТоварID']);
                              },
                              style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF333333),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0)
                                  ),
                            ),
                              child: Text(
                                '${item['Размер'] ?? 'Размер'}', style:TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      dbHelper.deleteCart(product_sizeID: item['ТоварРазмерID'], userID: userID);
                      onUpdateCart();
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Удалить',
                        style: TextStyle(
                        fontFamily: 'Standart',
                        color: Colors.black,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 5,
                      ),),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (item['Количество'] > 1) {
                            onQuantityChanged(item['Количество'] - 1);
                            dbHelper.updateCart(product_sizeID: item['ТоварРазмерID'], plus: false, userID: userID);
                            onUpdateCart();
                          }
                        },
                        icon: Icon(Icons.remove_circle, color: Colors.grey),
                      ),
                      Text(
                        '${item['Количество'] ?? 1}',
                        style: TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        onPressed: () {
                          onQuantityChanged(item['Количество'] + 1);
                          dbHelper.updateCart(product_sizeID: item['ТоварРазмерID'], plus: true, userID: userID);
                          onUpdateCart();
                        },
                        icon: Icon(Icons.add_circle, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: -5,
          left: -5,
          child: Checkbox(
            checkColor: Colors.white,
            activeColor: const Color(0xFF333333),
            value: isSelected,
            onChanged: (value) => onSelected(value ?? false),
          ),
        ),
      ],
    ),
  );
}

}