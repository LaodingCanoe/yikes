import 'package:flutter/material.dart';
import 'MobileHomePage.dart';
import 'authorization.dart';
import 'account_page.dart';
import 'db_class.dart';
import 'CartCard.dart';
import 'ProductPage.dart';
import 'EmailConfirmationPage.dart';
import 'searchCart.dart';
import 'CartCard.dart';

final dbHelper = DatabaseHelper();

void main() => runApp(const WebApp());

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keynes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WebHomePage(),
    );
  }
}

class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  int currentPageIndex = 0;
  Map<String, dynamic>? userData;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<CartScreenState> cartScreenKey = GlobalKey<CartScreenState>();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final data = await dbHelper.getLoginData();
    setState(() {
      userData = data.isNotEmpty && data['userId'] != null ? data : null;
    });
  }

  void switchToHomePage() async {
    await loadUserData();
    setState(() {
      currentPageIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            // Логотип
            const Text(
              'Keynes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BlackOpsOne',
                fontSize: 30.0,
              ),
            ),
            const SizedBox(width: 32),
            
            // Кнопка категорий
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                currentPageIndex = 1;
              },
            ),
            const SizedBox(width: 16),
            
            // Поиск
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  cursorColor: Color(0xFF333333),                  
                  decoration: InputDecoration(
                    hintText: 'Поиск...',
                    hintStyle: TextStyle(
                      fontSize: 21, 
                      color: Colors.grey, 
                    ),
                    labelStyle: TextStyle( 
                      fontSize: 21,
                      fontFamily: 'Standart',
                      fontWeight: FontWeight.w500,
                      wordSpacing: 10,
                    ),
                     border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => _searchController.clear(),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (value) {
                    // Обработка поиска
                  },
                ),
              ),
            ),
            const SizedBox(width: 32),
            
            // Корзина
            IconButton(
              icon: Badge(
                label: const Text('3'), // Замените на реальное количество
                child: const Icon(Icons.shopping_cart, color: Colors.black),
              ),
              onPressed: () {
                setState(() {
                  currentPageIndex = 3;
                });
              },
            ),
            const SizedBox(width: 16),
            
            // Аккаунт
            IconButton(
              icon: const Icon(Icons.account_circle, color: Colors.black),
              onPressed: () {
                setState(() {
                  currentPageIndex = 3;
                });
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          MobileHomePage(),
          SearchPage(),
          CartScreen(key: cartScreenKey),
          userData != null
              ? AccountPage(userData: userData!, onSuccess: switchToHomePage)
              : Authorization(onSuccess: switchToHomePage),
        ],
      ),
    );
  }
}