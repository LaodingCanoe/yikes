import 'package:flutter/material.dart';
import 'MobileHomePage.dart';
import 'authorization.dart';
import 'account_page.dart';
import 'db_class.dart';
import 'CartCard.dart';
import 'ProductPage.dart';
import 'EmailConfirmationPage.dart';
import 'searchCart.dart';

final dbHelper = DatabaseHelper();

void main() => runApp(const MobileNavigationBar());

class MobileNavigationBar extends StatelessWidget {
  const MobileNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: NavigationExample());
  }
}

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  Map<String, dynamic>? userData;
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
      bottomNavigationBar: Padding(
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Меньше отступов
  child: Container(
    height: 60, // Фиксированная высота панели
    decoration: BoxDecoration(
      color: Color(0xFF5D5755),
      borderRadius: BorderRadius.circular(20),
    ),
    child: NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 50, // Уменьшаем высоту самой навигационной панели
        labelTextStyle: MaterialStateProperty.all(TextStyle(fontSize: 0)), // Убираем подписи
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        indicatorColor: Colors.white,
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            if (index == 2) {
              cartScreenKey.currentState?.refreshCart();
            }
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: currentPageIndex == 0 ? Color(0xFF333333) : Colors.white),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.search, color: currentPageIndex == 1 ? Color(0xFF333333) : Colors.white),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart, color: currentPageIndex == 2 ? Color(0xFF333333) : Colors.white),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.login, color: currentPageIndex == 3 ? Color(0xFF333333) : Colors.white),
            label: '',
          ),
        ],
      ),
    ),
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
