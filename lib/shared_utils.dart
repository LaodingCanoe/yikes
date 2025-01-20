import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'db_class.dart';
final dbHelper = DatabaseHelper();

class SharedUtils {

  Future<void> addToCartLocally(int productId, int sizeId) async {
  final prefs = await SharedPreferences.getInstance();
  final cart = prefs.getStringList('localCart') ?? [];

  // Добавляем товар в локальную корзину
  final cartItem = json.encode({'productId': productId, 'sizeId': sizeId});
  cart.add(cartItem);

  await prefs.setStringList('localCart', cart);
}
Future<bool> _checkUserAuthorization() async {
  // Проверяем, авторизован ли пользователь
  // Например, через проверку токена или состояния приложения
  final userData =  await dbHelper.getLoginData();
  return userData.length > 0;
}

void _saveSelectedSizeToLocalStorage(Map<String, dynamic> size) {
  // Сохраняем выбранный размер в локальной памяти приложения.
  // Используйте предпочитаемый способ, например, SharedPreferences.
  print('Сохранено: $size');
}
}
