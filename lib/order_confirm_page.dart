import 'package:flutter/material.dart';
import 'db_class.dart';

final dbHelper = DatabaseHelper();

class OrderConfirmationPage extends StatefulWidget {
  final String orderNumber;

  const OrderConfirmationPage({
    Key? key,
    required this.orderNumber,
  }) : super(key: key);

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  Map<String, dynamic>? orderData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      final result = await dbHelper.fetchOrders(widget.orderNumber);
      if (result.isNotEmpty) {
        setState(() {
          orderData = result[0];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Заказ не найден.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка при загрузке заказа: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Icon(Icons.check_circle, color: Colors.green, size: 80),
                      ),
                      const SizedBox(height: 16),
                      const Center(
                        child: Text(
                          'Заказ оформлен',
                           style: TextStyle(
              fontFamily: 'Standart',
              fontSize: 35,
              fontWeight: FontWeight.w600,
              wordSpacing: 1,
            ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Номер заказа: ${widget.orderNumber}',
                          style: TextStyle(
              fontFamily: 'Standart',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              wordSpacing: 1,
            ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Статус заказа:',
                        style:  TextStyle(
              fontFamily: 'Standart',
              fontSize: 28,
              fontWeight: FontWeight.w500,
              wordSpacing: 1,
            ),
                      ),
                      const SizedBox(height: 8),
                      _buildStatusCard(
                        orderData?['Статус'] ?? 'Неизвестен',
                        _formatDate(orderData?['ДатаПодготовкиЗаказа']),
                      ),
                      const SizedBox(height: 32),                      
                      _buildShopDetails(orderData),
                    ],
                  ),
                ),
    );
  }

  void _showShopSchedule(BuildContext context, Map<String, dynamic>? shop) {
    if (shop == null) return;
    
    String _getDayName(int dayNumber) {
      switch (dayNumber) {
        case 1: return 'Понедельник';
        case 2: return 'Вторник';
        case 3: return 'Среда';
        case 4: return 'Четверг';
        case 5: return 'Пятница';
        case 6: return 'Суббота';
        case 7: return 'Воскресенье';
        default: return 'День $dayNumber';
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
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
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'График работы:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (shop['ГрафикРаботы'] != null && shop['ГрафикРаботы'].isNotEmpty)
                      ...(shop['ГрафикРаботы'] as List).map<Widget>((schedule) {
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
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$openTime - $closeTime',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }).toList()
                    else
                      const Text('График работы не указан'),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShopDetails(Map<String, dynamic>? shop) {
    if (shop == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Место получения:',
            style: TextStyle(
              fontFamily: 'Standart',
              fontSize: 26,
              fontWeight: FontWeight.w500,
              wordSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${shop['Город'] ?? ''}, ${shop['Адрес'] ?? ''}',
                  style: const TextStyle(
              fontFamily: 'Standart',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              wordSpacing: 1,
            ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.access_time_rounded, color: Color(0xFF333333)),
                tooltip: 'График работы',
                onPressed: () => _showShopSchedule(context, shop),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    
    final timeStr = time.toString();
    
    if (timeStr.contains(':')) {
      final timeParts = timeStr.split('T');
      if (timeParts.length >= 2) {
        final time = timeParts[1].split(':');
        return '${time[0]}:${time[1]}';
      }
      return timeStr.split('.')[0];
    }
    
    try {
      final dateTime = DateTime.parse(timeStr);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  Widget _buildStatusCard(String status, String deliveryTime) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow('Статус', status),
            const SizedBox(height: 8),
            _buildStatusRow('Срок получения до:', deliveryTime),
            const SizedBox(height: 8),
            _buildStatusRow('Оплата', 'При получении'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(
              fontFamily: 'Standart',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              wordSpacing: 1,
            ),),
        Text(value, style: const TextStyle(
              fontFamily: 'Standart',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              wordSpacing: 1,
            ),),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Не указано';
    
    try {
      DateTime parsedDate = date is DateTime ? date : DateTime.parse(date.toString());
      DateTime resultDate = parsedDate.add(const Duration(days: 4));
      
      String day = resultDate.day.toString().padLeft(2, '0');
      String month = resultDate.month.toString().padLeft(2, '0');
      String year = resultDate.year.toString().substring(2);
      String hours = resultDate.hour.toString().padLeft(2, '0');
      String minutes = resultDate.minute.toString().padLeft(2, '0');
      
      return '$day.$month.$year $hours:$minutes';
    } catch (e) {
      return 'Неверный формат даты';
    }
  }
}