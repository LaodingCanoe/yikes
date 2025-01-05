import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'configuration.dart';

class DesktopProductList extends StatefulWidget {
  @override
  _DesktopProductListState createState() => _DesktopProductListState();
}

class _DesktopProductListState extends State<DesktopProductList> {
  List<dynamic> _products = [];
  int _offset = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/products'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedProducts = json.decode(response.body);

        setState(() {
          _products.addAll(fetchedProducts);
          _offset += fetchedProducts.length;
          if (fetchedProducts.length < _limit) {
            _hasMore = false;
          }
        });
      } else {
        throw Exception('Не удалось загрузить продукты: ${response.statusCode}');
      }
    } catch (e) {
      print('Ошибка при загрузке продуктов: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<String>> _fetchProductImages(int productId) async {
   try {
    final response = await http.get(
      Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/productImages?productId=$productId'),
      headers: {
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((item) => item['Путь'] as String).toList();
      } else {
        throw Exception('Unexpected data format');
      }
    } else {
      throw Exception('Failed to fetch media');
    }
  } catch (e) {
    print('Error fetching media: $e');
    return [];
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список продуктов'),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
            _fetchProducts();
          }
          return true;
        },
        child: ListView.builder(
          itemCount: _products.length + (_hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final product = _products[index];
            final id = product['ТоварID'] ?? '';
            final name = product['Название'] ?? 'Без названия';
            final store = product['Бренд'] ?? 'Без бренда';
            final rating = product['Подкатегория'] ?? 'Без подкатегория';
            final reviews = product['Цвет'] ?? 'Без цвета';
            final price = product['Цена'] ?? 'Нет данных';
            final gendr = product['Гендр'] ?? 'Нет данных';

            return Card(
              margin: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 200,
                child: Row(
                  children: [
                    // Изображение
                    Stack(
                      children: [
                        FutureBuilder<List<String>>(
                          future: _fetchProductImages(id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return SizedBox(
                                width: 150,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                width: 150,
                                child: Image.asset(
                                  'assets/placeholder.png',
                                  fit: BoxFit.contain,
                                ),
                              );
                            } else {
                              return Container(
                                width: 150,
                                height: 200,
                                child: CarouselSlider(
                                  items: snapshot.data!.map((imagePath) {
                                    return Image.network(imagePath, fit: BoxFit.contain);
                                  }).toList(),
                                  options: CarouselOptions(
                                    height: 200,
                                    autoPlay: true,
                                    enlargeCenterPage: true,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // Описание товара
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 5),
                            Text('Бренд: $store', style: TextStyle(color: Colors.black)),
                            Text('Тип: $gendr', style: TextStyle(color: Colors.black)),
                            Text('Категория: $rating', style: TextStyle(color: Colors.black)),
                            Text('Цвет: $reviews', style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    // Цена и кнопка
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$price ₽',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4D7B4A),
                            ),
                          ),
                          SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              // Логика добавления в корзину
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 101, 64, 124), // Цвет кнопки
                            ),
                            child: Text('В корзину', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
