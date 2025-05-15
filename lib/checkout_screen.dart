import 'package:flutter/material.dart';
import 'db_class.dart';
import 'package:flutter/services.dart';
import 'order_confirm_page.dart';

final dbHelper = DatabaseHelper();

class CheckoutScreen extends StatefulWidget {
  final Set<int> selectedItems;
  final int userID;

  const CheckoutScreen({
    required this.selectedItems,
    required this.userID,
    Key? key,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  late Future<List<dynamic>> _cartItems;
  late Future<List<Map<String, dynamic>>> _shopsData;
  int? _selectedShopId;
  String? _promoCode;
  final _promoCodeController = TextEditingController();
  String _preparationTime = '';
  Map<String, dynamic>? _promoResult;
  String? _promoMessage;


  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadShops();
  }

  Future<void> _loadCartItems() async {
    List<dynamic> items;
    if (widget.userID == 0) {
      items = await dbHelper.getCartData();
    } else {
      items = await dbHelper.fetchCart(userId: widget.userID);
    }
    
    items = items.where((item) => widget.selectedItems.contains(item['ТоварРазмерID'])).toList();
    
    setState(() {
      _cartItems = Future.value(items);
    });
  }

  Future<void> _loadShops() async {
    try {
      final shopsData = await dbHelper.fetchShop(0);
      setState(() {
        _shopsData = Future.value(shopsData);
      });
    } catch (e) {
      setState(() {
        _shopsData = Future.value([]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки магазинов: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _groupShops(List<Map<String, dynamic>> shopsData) {
  final Map<int, Map<String, dynamic>> groupedShops = {};

  for (var shop in shopsData) {
    final id = shop['ID'] as int;
    if (!groupedShops.containsKey(id)) {
      groupedShops[id] = {
        'ID': id,
        'Город': shop['Город']?.toString() ?? '',
        'Адрес': shop['Адрес']?.toString() ?? '',
        'ГрафикРаботы': <Map<String, dynamic>>[],
      };
    }
    
    if (shop['ДеньНедели'] != null) {
  groupedShops[id]!['ГрафикРаботы'].add({
    'ДеньНедели': shop['ДеньНедели'] as int,
    'ВремяОткрытия': _formatTime(shop['ВремяОткрытия']),
    'ВремяЗакрытия': _formatTime(shop['ВремяЗакрытия']),
  });
}
  }

  return groupedShops.values.toList();
}

// Функция для форматирования времени (если приходит в формате '09:00:00.0000000')
String _formatTime(dynamic time) {
  if (time == null) return '';
  
  final timeStr = time.toString();
  
  // Если время приходит в формате "09:00:00.0000000"
  if (timeStr.contains(':')) {
    final timeParts = timeStr.split('T');
    if (timeParts.length >= 2) {
      final time = timeParts[1].split(':');
      return '${time[0]}:${time[1]}'; // Берем только часы и минуты
    }
    return timeStr.split('.')[0]; // Альтернативный вариант
  }
  
  // Если время приходит как DateTime (1970-01-01T09:00:00.000Z)
  try {
    final dateTime = DateTime.parse(timeStr);
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  } catch (e) {
    return timeStr;
  }
}

  double _calculateTotalPrice(List<dynamic> cartItems) {
    return cartItems.fold(0.0, (total, item) => total + (item['Цена'] * item['Количество']));
  }

  double _calculateDiscountedTotal(List<dynamic> cartItems) {
  double total = _calculateTotalPrice(cartItems);

  if (_promoResult != null && _promoResult!['valid'] == true) {
    final promo = _promoResult!['data'];
    final type = promo['ТипСкидки'];
    final value = promo['ЗначениеСкидки'];
    final minOrder = promo['МинСуммаЗаказа'];

    if (type == 'фиксированная') {
      if (total >= minOrder) {
        total -= value;
      }
    } else if (type == 'процент') {
      total *= (1 - value / 100);
    }
  }

  return total < 0 ? 0 : total;
}



  void _applyPromoCode() async {
  final code = _promoCodeController.text.trim().toUpperCase();

  if (code.isEmpty) {
    setState(() {
      _promoCode = null;
      _promoResult = null;
      _promoMessage = null;
    });
    return;
  }

  final result = await dbHelper.fetchPromoCode(promoCode: code, userId: widget.userID);

  final items = await _cartItems;
  final total = _calculateTotalPrice(items);

  String? message;

  if (result['valid'] == true) {
    final promo = result['data'];
    final type = promo['ТипСкидки'];
    final value = promo['ЗначениеСкидки'];
    final minOrder = promo['МинСуммаЗаказа'];

    if (type == 'фиксированная') {
      if (total >= minOrder) {
        message = 'Промокод успешно применён, скидка ${value.toStringAsFixed(0)} ₽ при заказе от ${minOrder.toStringAsFixed(0)} ₽';
      } else {
        message = 'Сумма заказа меньше минимальной (${minOrder.toStringAsFixed(2)} ₽) для применения промокода';
        result['valid'] = false; // Промокод не должен применяться
      }
    } else if (type == 'процент') {
      message = 'Промокод успешно применён, скидка ${value.toStringAsFixed(0)}%';
    } else {
      message = 'Неизвестный тип скидки';
      result['valid'] = false;
    }
  } else {
    message = '${result['reason']}';
  }

  setState(() {
    _promoCode = code;
    _promoResult = result;
    _promoMessage = message;
    _cartItems = Future.value(items); // Триггерим пересчёт суммы
  });
}





 void _updatePreparationTime(List<dynamic> cartItems, int? shopId) {
  if (shopId == null || cartItems.isEmpty) {
    setState(() {
      _preparationTime = '';
    });
    return;
  }

  // Проверяем, что все товары из одного магазина
  final allFromSameShop = cartItems.every((item) => item['МагазинID'] == shopId);
  
  setState(() {
    _preparationTime = allFromSameShop ? '15 минут' : '3 часа';
  });
}
 
  void _placeOrder() async {
  if (_selectedShopId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Пожалуйста, выберите магазин для доставки')),
    );
    return;
  }

  final cartItems = await _cartItems;
  final orderItems = cartItems.map((item) => {
  'productId': item['ТоварРазмерID'],  // 👈 английское имя
  'count': item['Количество'],         // 👈 английское имя
}).toList();


  // Генерация номера заказа
  final orderNumber = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

  // Сумма с учетом промокода
  final totalSum = _calculateDiscountedTotal(cartItems);

  // ID промокода (если применен)
  final promoId = (_promoResult != null && _promoResult!['valid'] == true)
      ? _promoResult!['data']['ID'] as int
      : null;
  final now = DateTime.now();
  final preparationDuration = _preparationTime == '15 минут' ? 15 : 180; // в минутах
  final orderPreparationDate = now.add(Duration(minutes: preparationDuration));
  // Отправка заказа
  bool isOrderConfirm = await dbHelper.createOrder(
    orderNumber: orderNumber,
    userId: widget.userID,
    sum: totalSum,
    promoId: promoId,
    orderPreparationDate: orderPreparationDate,
    items: orderItems,
  );

  if (isOrderConfirm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationPage(
          orderNumber: orderNumber,
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Не удалось создать заказ')),
    );
  }
}

void _showShopSchedule(BuildContext context, Map<String, dynamic> shop) {
  String _getDayName(int dayNumber) {
    switch (dayNumber) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return 'День $dayNumber';
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // обязательно, чтобы корректно работала высота
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45, // было 0.5 — теперь 70% экрана при открытии
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'График работы:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  if (shop['ГрафикРаботы'] != null && shop['ГрафикРаботы'].isNotEmpty)
                    ...shop['ГрафикРаботы'].map<Widget>((schedule) {
                      String openTime = _formatTime(schedule['ВремяОткрытия']);
                      String closeTime = _formatTime(schedule['ВремяЗакрытия']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getDayName(schedule['ДеньНедели'] as int),
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            SizedBox(width: 12), // Добавляем отступ между колонками
                            Text(
                              '$openTime - $closeTime',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  else
                    Text('График работы не указан'),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оформление заказа',
                  style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 1,
                      ),),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ваш заказ',
                  style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 1,
                      ),
            ),
            SizedBox(height: 16),
            
            FutureBuilder<List<dynamic>>(
              future: _cartItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Ошибка загрузки товаров: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Нет товаров для оформления');
                } else {
                  final items = snapshot.data!;
                  return Column(
                    children: [
                      ...items.map((item) => _buildOrderItem(item)).toList(),
                      Divider(),
                      _buildTotalSection(items),
                    ],
                  );
                }
              },
            ),
            
            SizedBox(height: 24),
            Text(
              'Промокод',
                  style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 1,
                      ),
            ),
            SizedBox(height: 8),
            _buildPromoCodeField(),
            
            SizedBox(height: 24),
            Text(
              'Выбор магазина',
                  style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 1,
                      ),
            ),
            SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _shopsData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('Нет доступных магазинов');
                } else {
                  final groupedShops = _groupShops(snapshot.data!);
                  return Column(
                    children: groupedShops.map((shop) => _buildShopItem(shop)).toList(),
                  );
                }
              },
            ),
            
            if (_preparationTime.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Примерное время подготовки: $_preparationTime',
                style: TextStyle(
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 2,
                      ),
              ),
            ],
            
            SizedBox(height: 32),
            _buildPlaceOrderButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          FutureBuilder<List<String>>(
            future: DatabaseHelper.fetchProductImages(item['ТоварID']),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return Image.network(
                  snapshot.data!.first,
                  width: 60,
                  height: 90,
                  fit: BoxFit.cover,
                );
              }
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
          SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['Название'] ?? 'Товар',
                  style: TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text('Размер: ${item['Размер']}'),
                SizedBox(height: 4),
                Text('${item['Количество']} × ${item['Цена']} ₽'),
                // if (item['МагазинID'] != null) ...[
                //   SizedBox(height: 4),
                //   Text('Магазин: ${item['МагазинID']}', style: TextStyle(fontSize: 12)),
                // ],\
                if (item['МагазинID'] != null) ...[
                  SizedBox(height: 4),
                  Text('', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
          
          Text(
            '${(item['Цена'] * item['Количество']).toStringAsFixed(2)} ₽',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

Widget _buildShopItem(Map<String, dynamic> shop) {
  final isSelected = _selectedShopId == shop['ID'];
  return Container(
    margin: EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(
        color: isSelected ? Color(0xFF333333) : Colors.grey,
        width: 1.2,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedShopId = shop['ID'];
        });
        _cartItems.then((items) => _updatePreparationTime(items, shop['ID']));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Radio<int>(
                value: shop['ID'],
                groupValue: _selectedShopId,
                activeColor: Color(0xFF333333),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                onChanged: (value) {
                  setState(() {
                    _selectedShopId = value;
                  });
                  _cartItems.then((items) => _updatePreparationTime(items, value));
                },
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${shop['Город']}, ${shop['Адрес']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.access_time_rounded, color: Color(0xFF333333)),
                        tooltip: 'График работы',
                        onPressed: () => _showShopSchedule(context, shop),
                      ),
                    ],
                  ),
                  // if (_preparationTime.isNotEmpty && isSelected)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 4.0),
                  //     child: Text(
                  //       'Время подготовки: $_preparationTime',
                  //       style: TextStyle(color: Colors.grey[700]),
                  //     ),
                  //   ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _buildTotalSection(List<dynamic> items) {
  final originalTotal = _calculateTotalPrice(items);
  final discountedTotal = _calculateDiscountedTotal(items);
  final discount = originalTotal - discountedTotal;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (discount > 0)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Сумма без скидки:', style: TextStyle(fontSize: 16)),
          Text('${originalTotal.toStringAsFixed(2)} ₽', style: TextStyle(fontSize: 16)),
        ],
      ),
      if (discount > 0)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Скидка:', style: TextStyle(fontSize: 16)),
            Text('-${discount.toStringAsFixed(2)} ₽', style: TextStyle(fontSize: 16, color: const Color.fromARGB(255, 4, 90, 7))),
          ],
        ),
      if (discount > 0)
        Divider(),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Итого:', style: TextStyle( fontFamily:'Helvetica', fontSize: 18, fontWeight: FontWeight.bold)),
          Text('${discountedTotal.toStringAsFixed(2)} ₽', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    ],
  );
}


  Widget _buildPromoCodeField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: TextField(
              cursorColor: Color(0xFF333333),
              controller: _promoCodeController,              
              inputFormatters: [UpperCaseTextFormatter()],
              style: TextStyle(
                fontSize: 26,
                fontFamily: 'Standart',
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                hintText: 'Введите промокод',
                hintStyle: TextStyle(
                  fontSize: 21,
                  fontFamily: 'Standart',
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF333333)), // неактивная рамка
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF333333), width: 2), // активная рамка
                ),
                border: OutlineInputBorder(), // на всякий случай
                suffixIcon: _promoResult != null
        ? IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _promoCodeController.clear();
                _promoCode = null;
                _promoResult = null;
                _promoMessage = null;
              });
            },
          )
        : null,
  ),
  onSubmitted: (_) => _applyPromoCode(),
            ),

          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.check, color: Colors.white),
            onPressed: _applyPromoCode,
            style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 60),
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    ),
          ),
        ],
      ),
      if (_promoMessage != null) ...[
        SizedBox(height: 8),
        Text(
          _promoMessage!,
          style: TextStyle(
            //color: _promoResult?['isValid'] == true ? const Color.fromARGB(255, 8, 142, 12) : const Color.fromARGB(255, 109, 18, 11),
            
            fontWeight: FontWeight.w500,
          ),
        ),
      ]
    ],
  );
}


  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _placeOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF333333),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Оформить заказ',
          
                  style: TextStyle(
                    color: Colors.white,
                        fontFamily: 'Standart',
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 1,
                      ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }
}