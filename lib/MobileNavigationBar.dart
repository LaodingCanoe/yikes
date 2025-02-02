import 'package:flutter/material.dart';
import 'MobileHomePage.dart';
import 'authorization.dart';
import 'account_page.dart';
import 'db_class.dart';
import 'CartCard.dart';
import 'ProductPage.dart';
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPageIndex,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            if (index == 2) {
              cartScreenKey.currentState?.refreshCart();
            }
          });
        },
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.home), label: ''),
          NavigationDestination(icon: Icon(Icons.search), label: ''),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: ''),
          NavigationDestination(icon: Icon(Icons.login), label: ''),  
          ],
      ),  
          body: IndexedStack(
        index: currentPageIndex,
        children: [
          MobileHomePage(),
          ProductPage(article: '4420642842-37'),
          //const Center(child: Text('Search Page')),
          CartScreen(key: cartScreenKey),
          userData != null
              ? AccountPage(userData: userData!, onSuccess: switchToHomePage)
              : Authorization(onSuccess: switchToHomePage),
        ],
      ),
    );
  }
}