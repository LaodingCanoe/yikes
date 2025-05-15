import 'package:flutter/foundation.dart'; // Для определения платформы
import 'package:flutter/material.dart';
import 'BottomNavigationBar.dart'; // Импортируем ваш файл
import 'desktop_product_list.dart'; // Подключаем DesktopProductList
import 'mobile_product_list.dart'; 
import 'MobileNavigationBar.dart';
import 'WebNavigationBar.dart';
import 'TestProduct.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'GOST', // Указываем семейство шрифта
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
          headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w700),
          labelSmall: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w300),
        ),
      ),
      home: _getHomePage(), // Определяем стартовую страницу
    );
  }

  Widget _getHomePage() {
    if (kIsWeb) {
      return WebApp(); // Для Web
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return MobileNavigationBar(); // Для мобильных
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return WebApp(); // Для ПК
      default:
        return MobileNavigationBar(); // По умолчанию мобильная версия
    }
  }
}
