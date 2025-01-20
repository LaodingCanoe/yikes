import 'package:flutter/material.dart';
import 'image_carousel.dart';
import 'db_class.dart';

final dbHelper = DatabaseHelper();

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<dynamic>> _cartItems;
  int userID = 0;
  bool selectAll = true;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    final userData = await dbHelper.getLoginData();
    setState(() {
      userID = userData["userId"];
    });
    _loadCartItems();
  }

  void _loadCartItems() {
    setState(() {
      _cartItems = dbHelper.fetchCart(userId: userID, productID: null);
    });
  }

  @override
  void didUpdateWidget(covariant CartScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadCartItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Корзина'),
        
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Пункт выдачи',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (value) {
                        setState(() {
                          selectAll = value ?? false;
                        });
                      },
                    ),
                    Text('Выбрать всё'),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // Logic to delete selected items
                      },
                      child: Text('Удалить выбранное'),
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
                        onQuantityChanged: (newQuantity) async {
                          _loadCartItems();
                        },
                        onDelete: () async {
                          _loadCartItems();
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
                Text(
                  'Итоговая цена: 0 ₽', // Replace with actual calculation
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Logic for proceeding to checkout
                  },
                  child: Text('Перейти к оформлению'),
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
  final int userID; // Добавляем userID как параметр
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onDelete;
  final VoidCallback onUpdateCart;

  CartItemCard({
    required this.item,
    required this.userID, // Добавляем userID в конструктор
    required this.onQuantityChanged,
    required this.onDelete,
    required this.onUpdateCart,
  });

@override
Widget build(BuildContext context) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
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
                          ),
                        );
                      }
                    },
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Checkbox(
                      value: true, // По умолчанию включено
                      onChanged: (value) {
                        // Логика обработки изменения статуса галочки
                      },
                    ),
                  ),
                ],
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
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    SizedBox(height: 8),
                    // Цвета и размеры
                    Row(
                      children: [
                        // Цвета товара
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
                        // Кнопка размера
                        ElevatedButton(
                          onPressed: () {
                            // Логика для выбора размера
                          },
                          child: Text(
                            '${item['Международный'] ?? 'Размер'} (${item['Российский'] ?? ''})',
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
                  dbHelper.deleteCart(productID: item['ТоварРазмерID'], userID: userID);
                  onUpdateCart();
                },
                icon: Icon(Icons.delete, color: Colors.red),
                label: Text('Удалить'),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (item['Количество'] > 1) {
                        onQuantityChanged(item['Количество'] - 1);
                        dbHelper.updateCart(productID: item['ТоварРазмерID'], plus: false, userID: userID);
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
                      dbHelper.updateCart(productID: item['ТоварРазмерID'], plus: true, userID: userID);
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
  );
}
}