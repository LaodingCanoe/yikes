import 'package:flutter/material.dart';
import 'MobileHomePage.dart';
import 'authorization.dart';
import 'account_page.dart';
import 'db_class.dart';
import 'CartCard.dart';
import 'ProductPage.dart';
import 'EmailConfirmationPage.dart';
import 'searchCart.dart';
import 'order_confirm_page.dart';

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
      appBar: currentPageIndex == 0 
          ? AppBar(
              centerTitle: true,
              title: const Text(
                'Keynes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'BlackOpsOne',
                  fontSize: 30.0,
                ),
              ),
            )
          : currentPageIndex == 2
              ? AppBar(
                  centerTitle: true,
                  title: const Text(
                    'Корзина',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BlackOpsOne',
                      fontSize: 30.0,             
                    ),
                  ),
                )
              : null,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFF5D5755),
            borderRadius: BorderRadius.circular(20),
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 50,
              labelTextStyle: MaterialStateProperty.all(TextStyle(fontSize: 0)),
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
        //   OrderConfirmationPage(
        //   orderNumber: 'ORD-1747222507404',
        // ),
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