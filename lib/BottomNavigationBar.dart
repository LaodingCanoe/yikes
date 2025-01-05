import 'package:flutter/material.dart';
import 'mobile_product_list.dart'; // Импортируем MobileProductList

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0; // Индекс выбранной вкладки
  final List<Widget> _pages = [
    MobileProductList(), // Вкладка Home: используем MobileProductList
    Center(child: Text('Search Page')), // Вкладка Search
    Center(child: Text('Heart Page')), // Вкладка Heart
    Center(child: Text('Bell Page')), // Вкладка Bell
  ];

  // Метод для получения пути к иконке в зависимости от выбранной вкладки и состояния
  String _getIconPath(int index, bool isSelected) {
    String platform = isSelected ? 'touch' : 'standart'; // Выбор платформы
    String iconName;
    switch (index) {
      case 0:
        iconName = 'home';
        break;
      case 1:
        iconName = 'search';
        break;
      case 2:
        iconName = 'heart';
        break;
      case 3:
        iconName = 'bell';
        break;
      default:
        iconName = 'home';
    }

    // Путь к иконке для выбранной платформы и вкладки
    return 'assets/images/$iconName/$platform/android/$iconName.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.grey[200], // Цвет фона навигационной панели
        selectedItemColor: Colors.blue, // Цвет выбранного элемента
        unselectedItemColor: Colors.grey, // Цвет невыбранных элементов
        items: List.generate(4, (index) {
          return BottomNavigationBarItem(
            icon: Image.asset(
              _getIconPath(index, _selectedIndex == index),
              width: 30,
              height: 30,
            ),
            label: _getLabelForIndex(index),
          );
        }),
      ),
    );
  }

  // Метод для получения названия вкладки
  String _getLabelForIndex(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Search';
      case 2:
        return 'Heart';
      case 3:
        return 'Bell';
      default:
        return '';
    }
  }
}
