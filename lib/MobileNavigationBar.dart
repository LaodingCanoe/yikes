import 'package:flutter/material.dart';
import 'mobile_product_list.dart';
import 'MobileHomePage.dart';

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

  final List<Widget> pages = [
    MobileHomePage(),
    const Center(child: Text('Search Page')),
    const Center(child: Text('Cart Page')),
    const Center(child: Text('Account Page')),
  ];

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
          NavigationDestination(
            icon: Icon(Icons.home), // Home
            label: '', // Empty label
          ),
          NavigationDestination(
            icon: Icon(Icons.search), // Search
            label: '', // Empty label
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart), // Cart
            label: '', // Empty label
          ),
          NavigationDestination(
            icon: Icon(Icons.person), // Account
            label: '', // Empty label
          ),
        ],
      ),
      body: pages[currentPageIndex],
    );
  }
}
