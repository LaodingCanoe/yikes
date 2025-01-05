import 'package:flutter/material.dart';
import 'image_carousel.dart'; // Ensure this is implemented correctly
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'configuration.dart';

class MobileProductList extends StatefulWidget {
  MobileProductList({Key? key}) : super(key: key);

  @override
  _MobileProductListState createState() => _MobileProductListState();
}

class _MobileProductListState extends State<MobileProductList> {
  List<dynamic> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  Map<String, dynamic>? _user; // No longer final, now we manage user state here

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Method to fetch products from the server
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
        });
      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method to fetch product images
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

  // Update user data after successful login
void _updateUser(Map<String, dynamic> newUser) async {
  setState(() {
    _user = newUser; // Update the user data state
  });

  // Save avatar URL to SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('avatarUrl', newUser['avatarUrl'] ?? '');
}
void _loadUserAvatar() async {
  final prefs = await SharedPreferences.getInstance();
  final avatarUrl = prefs.getString('avatarUrl');
  setState(() {
    _user = avatarUrl != null ? {'avatarUrl': avatarUrl} : null;
  });
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Search bar
            Container(
              height: 50,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Image.asset('assets/search.png', width: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Найти',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // User avatar or icon
// IconButton(
//   icon: _user != null && _user!['avatarUrl'] != null
//       ? CircleAvatar(
//           radius: 20,
//           backgroundImage: NetworkImage(_user!['avatarUrl']),
//         )
//       : CircleAvatar(
//           radius: 20,
//           backgroundImage: AssetImage('assets/defolt_logo.jpg'),
//         ),
//   onPressed: () {
//     if (_user != null) {
      

//     } else {
//       // Если пользователь не авторизован, переходим на экран авторизации
      
//     }
//   },
// )

          ],
        ),
      ),

      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && !_isLoading) {
            _fetchProducts(); // Fetch more products when scrolled to the bottom
          }
          return true;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.0,
            crossAxisSpacing: 8.0,
            childAspectRatio: 0.455, // Adjust card height
          ),
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
            //final rating = product['Подкатегория'] ?? 'Без подкатегория';
            //final reviews = product['Цвет'] ?? 'Без цвета';
            //final isDiscounted = product['Уценка'] == true;
            final price = product['Цена'] ?? 'Нет данных';

            return Card(
  margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Image carousel
                  Stack(
                    children: [
                      FutureBuilder<List<String>>(
                        future: _fetchProductImages(id),
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
                              imageUrls: snapshot.data!, // Use image URLs in carousel
                            );
                          }
                        },
                      ),
                      // if (isDiscounted)
                      //   Positioned(
                      //     bottom: 8,
                      //     left: 8,
                      //     child: Container(
                      //       padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      //       decoration: BoxDecoration(
                      //         color: Color(0xFF4D7B4A),
                      //         borderRadius: BorderRadius.circular(4),
                      //       ),
                      //       child: Text(
                      //         'Уценка',
                      //         style: TextStyle(color: Colors.white, fontSize: 12),
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                  // Product price
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$price ₽',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 12, 12, 12),
                        ),
                      ),
                    ),
                  ),
                  // Product info
                  
                        SizedBox(height: 4),
                        Text(
                          store,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        
                      ],
                    ),
                  ),
      // Spacer to push the button to the bottom
      Spacer(),
      // Add to cart button
      Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // Add to cart logic
          },
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
    ],
  ),
);

          },
        ),
      ),
    );
  }
}
