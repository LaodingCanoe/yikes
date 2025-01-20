import 'package:flutter/material.dart';
import 'MobileHomePage.dart';
import 'authorization.dart';
import 'account_page.dart';
import 'db_class.dart';
import 'CartCard.dart';

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
      //currentPageIndex = userData != null ? 1 : 1;
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
          });
        },
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.home), label: ''),
          NavigationDestination(icon: Icon(Icons.person), label: ''),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: ''),
          NavigationDestination(icon: Icon(Icons.login), label: ''),
        ],
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: [
          MobileHomePage(),
          const Center(child: Text('Search Page')),
          CartScreen(),
          userData != null
              ? AccountPage(userData: userData!, onSuccess: switchToHomePage) // Передаём данные в AccountPage
              : Authorization(onSuccess: switchToHomePage), // Страница авторизации
        ],
      ),
    );
  }
}
