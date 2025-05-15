import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'configuration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseHelper {
  static final storage = FlutterSecureStorage();
  Future<List<String>> fetchImages(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/$endpoint'),
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
        throw Exception('Failed to fetch images');
      }
    } catch (e) {
      print('Error fetching images: $e');
      return [];
    }
  }  
static Future<List<Map<String, dynamic>>> fetchProducts({
  List<String>? categories,
  List<String>? brands,
  List<String>? colors,
  List<String>? tags,
  double? minPrice,
  double? maxPrice,
  String? search,
  int? obraz,
  List<String>? gender,
  int? subcategory,
  int maxItems = 1000,
}) async {
  final uri = Uri(
    scheme: 'http',
    host: Configuration.ip_adress,
    port: Configuration.port,
    path: '/products',
    queryParameters: {
      if (categories != null && categories.isNotEmpty)
        'categories': categories.join(','),
      if (brands != null && brands.isNotEmpty)
        'brands': brands.join(','),
      if (colors != null && colors.isNotEmpty)
        'colors': colors.join(','),
      if (tags != null && tags.isNotEmpty)
        'tags': tags.join(','),
      if (gender != null && gender.isNotEmpty)
        'gender': gender.join(','),
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (obraz != null) 'obraz': obraz.toString(),
      if (subcategory != null) 'subcategory': subcategory.toString(),
    },
  );

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 40));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(data.take(maxItems));
    } else {
      print('Ошибка сервера: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Ошибка загрузки продуктов: $e');
    return [];
  }
}



  static Future<List<String>> fetchProductImages(int productId) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://${Configuration.ip_adress}:${Configuration.port}/productImages?productId=$productId',
        ),
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
Future<List<Map<String, dynamic>>> fetchProductSizes(int productId) async {
  final String baseUrl = 'http://${Configuration.ip_adress}:${Configuration.port}'; // Замените на адрес вашего сервера
  final String endpoint = '/product-sizes';

  try {
    // Формируем URL с параметром productId
    final Uri url = Uri.parse('$baseUrl$endpoint?productId=$productId');

    // Выполняем GET-запрос
    final response = await http.get(url);

    // Проверяем статус ответа
    if (response.statusCode == 200) {
      // Парсим JSON-ответ
      final List<dynamic> jsonData = json.decode(response.body);
      // Преобразуем каждый элемент в Map<String, dynamic>
      return jsonData.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 400) {
      throw Exception('Invalid request: ProductId is required');
    } else {
      throw Exception('Failed to fetch product sizes: ${response.statusCode}');
    }
  } catch (error) {
    // Обрабатываем ошибки
    print('Error fetching product sizes: $error');
    throw Exception('Error fetching product sizes: $error');
  }
}


 Future<bool> registerUser({
  required String email,
  required String password,
  required String name, // Имя
  required String firstname, // Фамилия
  required String patranomic, // Отчество
  String? avatarPath, // Аватар
  required bool isSubscribed, // Рекламная рассылка
  required bool isCorectEmail, // Подтверждение email
  required int role, // Роль пользователя
}) async {
  final url = 'http://${Configuration.ip_adress}:${Configuration.port}/register';

  try {
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['email'] = email
      ..fields['password'] = password
      ..fields['name'] = name
      ..fields['firstname'] = firstname
      ..fields['patranomic'] = patranomic
      ..fields['add'] = isSubscribed.toString()
      ..fields['isCorectEmail'] = isCorectEmail.toString()
      ..fields['role'] = role.toString();

    if (avatarPath != null) {
      request.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return true;
    } else {
      print("Error: ${response.body}");
      return false;
    }
  } catch (e) {
    print("Exception: $e");
    return false;
  }
}
Future<void> sendConfirmationEmail({
  required String email,
  required String firstname,
  required String name,
}) async {
  final Uri url = Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/send-confirmation-email'); // Укажите правильный адрес вашего API

  try {
    // Создание тела запроса
    final Map<String, String> requestBody = {
      'email': email,
      'firstname': firstname,
      'name': name,
    };

    // Отправка POST-запроса
    final http.Response response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    // Обработка ответа
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      print('Success: ${responseBody['message']}');
    } else {
      final errorBody = jsonDecode(response.body);
      print('Error: ${errorBody['error']}');
      throw Exception('Failed to send confirmation email: ${errorBody['error']}');
    }
  } catch (e) {
    print('An error occurred: $e');
    throw Exception('Failed to send confirmation email');
  }
}

static Future<Map<String, dynamic>?> loginUser(String email, String password) async {
  final url = "http://${Configuration.ip_adress}:${Configuration.port}/login";

  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: json.encode({
      "email": email,
      "password": password,
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    await saveLoginData(
      userId: data['id'],
      email: data['email'],
      token: data['token'],
      avatar: data['avatar'],
      surname: data['surname'],
      name: data['name'],
      emailConfirmation: data['emailConfirmation'],
    );
    return data;
  } else {
    print("Error: ${response.body}");
    return null;
  }
}


static Future<void> saveLoginData({
  required int userId,
  required String email,
  required String token,
  String? avatar,
  required String surname,
  required String name,
  required bool emailConfirmation,
}) async {
  final storage = FlutterSecureStorage();
  await storage.write(key: "userId", value: userId.toString());
  await storage.write(key: "email", value: email);
  await storage.write(key: "token", value: token);
  await storage.write(key: "avatar", value: avatar ?? '');
  await storage.write(key: "surname", value: surname);
  await storage.write(key: "name", value: name);
  await storage.write(key: "emailConfirmation", value: emailConfirmation.toString());
}

Future<Map<String, dynamic>> getLoginData() async {
  final storage = FlutterSecureStorage();

  try {
    final userId = await storage.read(key: "userId");
    final email = await storage.read(key: "email");
    final token = await storage.read(key: "token");
    final avatar = await storage.read(key: "avatar");
    final surname = await storage.read(key: "surname");
    final name = await storage.read(key: "name");
    final emailConfirmation = await storage.read(key: "emailConfirmation");

    return {
      "userId": userId != null ? int.tryParse(userId) : null,
      "email": email ?? '',
      "token": token ?? '',
      "avatar": avatar ?? '',
      "surname": surname ?? '',
      "name": name ?? '',
      "emailConfirmation": emailConfirmation ?? 'false',
    };
  } catch (e) {
    print("Ошибка получения данных: $e");
    return {};
  }
}

Future<bool> resetPassword(String email) async {
  final url = "http://${Configuration.ip_adress}:${Configuration.port}/reset-password";

  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: json.encode({"email": email}),
  );

  if (response.statusCode == 200) {
    return true; // На почту отправлено письмо
  } else {
    print("Error: ${response.body}");
    return false;
  }
}

Future<bool> addToCart(int? productId, int? sizeId, int userId, int? productSizeId) async {
  final url = Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/addToCart'); // Замените на ваш адрес сервера
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'productId': productId,
        'sizeId': sizeId,
        'userId': userId,
        'productSizeId': productSizeId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('Товар успешно добавлен в корзину');
        return true;
      } else {
        print('Ошибка: ${data['message']}');
        return false;
      }
    } else {
      print('Ошибка сервера: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Ошибка при отправке запроса: $e');
    return false;
  }
}
Future<List<dynamic>> fetchCart({
  int? product_size,
  required int userId,
  int? productID,
  int? sizeID,
}) async {
  try {
    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/cart',
    );

    final Map<String, dynamic> body = {
      if (product_size != null) 'product_size': product_size,
      'userId': userId,
      if (productID != null) 'productID': productID,
      if (sizeID != null) 'sizeID': sizeID,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cart: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading cart: $e');
    return [];
  }
}

Future<List<dynamic>> deleteCart({
  int? product_sizeID,
  int? productID,
  int? sizeID,
  required int userID,
}) async {
  print("Deleting product: product_sizeID=$product_sizeID, productID=$productID, sizeID=$sizeID, userID=$userID");

  if (userID == 0) {
    final currentCart = await getCartData();
    currentCart.removeWhere((item) => item['ТоварРазмерID'] == productID);
    await saveCartToStorage(currentCart);
    return [];
  } else {
    try {
      final Map<String, dynamic> body = {
        'userID': userID,
        if (product_sizeID != null) 'product_sizeID': product_sizeID,
        if (productID != null && sizeID != null) ...{
          'productID': productID,
          'sizeID': sizeID,
        }
      };

      final uri = Uri.http('${Configuration.ip_adress}:${Configuration.port}', '/delete-cart');

      final response = await http.delete(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        } else {
          throw Exception('Server error: ${jsonResponse['error']}');
        }
      } else {
        throw Exception('Failed to DELETE cart: ${response.statusCode}');
      }
    } catch (e) {
      print('Error DELETE cart: $e');
      return [];
    }
  }
}


Future<List<dynamic>> updateCart({
  int? product_sizeID,
  int? productID,
  int? sizeID,
  required bool plus,
  required int userID,
}) async {
  try {
    final Map<String, dynamic> body = {
      'plus': plus.toString(),
      'userID': userID,
      if (product_sizeID != null) 'product_sizeID': product_sizeID,
      if (productID != null && sizeID != null) ...{
        'productID': productID,
        'sizeID': sizeID,
      }
    };

    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/update-cart',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      } else {
        throw Exception('Server error: ${jsonResponse['error']}');
      }
    } else {
      throw Exception('Failed to update cart: ${response.statusCode}');
    }
  } catch (e) {
    print('Error updating cart: $e');
    return [];
  }
}

 Future<void> fetchAndSaveCartData(int productID) async {
  final String url = 'http://${Configuration.ip_adress}:${Configuration.port}/cart';

  try {
    // Формируем URL с параметрами
    final uri = Uri.parse('$url?productID=$productID');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('data: ${data[0]}');
      if (data.isNotEmpty) {
        final cartItem = data[0]; // Первый элемент массива

        // Сохраняем данные в локальной памяти
        await storage.write(key: "ТоварРазмерID", value: cartItem['ТоварРазмерID']?.toString());
        await storage.write(key: "ТоварID", value: cartItem['ТоварID']?.toString());
        await storage.write(key: "Название", value: cartItem['Название'] ?? '');
        await storage.write(key: "Цена", value: cartItem['Цена']?.toString());
        await storage.write(key: "КодЦвета", value: cartItem['КодЦвета'] ?? '');
        await storage.write(key: "Цвет", value: cartItem['Цвет'] ?? '');
        await storage.write(key: "Размер", value: cartItem['Размер'] ?? '');
        await storage.write(key: "Количество", value: cartItem['Количество']?.toString());

        print('data:  ${data}');
      } else {
        print("Сервер вернул пустой массив.");
      }
    } else {
      print("Ошибка сервера: ${response.statusCode}");
    }
  } catch (error) {
    print("Ошибка запроса: $error");
  }
}


Future<List<dynamic>> getCartData() async {
  final cart = await _loadCartFromStorage();
  return cart ?? [];
}

Future<void> addToCart_login_false(dynamic item) async {
  final currentCart = await getCartData();
  currentCart.add(item);
  await saveCartToStorage(currentCart);
}

Future<void> saveCartToStorage(List<dynamic> cartData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedData = jsonEncode(cartData);
      await prefs.setString('cart_data', encodedData);
      print('Cart data saved to storage');
    } catch (e) {
      print('Error saving cart data: $e');
    }
  }

Future<List<dynamic>?> _loadCartFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final cartString = prefs.getString('cart_data');
  if (cartString != null) {
    return jsonDecode(cartString) as List<dynamic>;
  }
  print((cartString));
  return null;
}


Future<Map<String, dynamic>?> fetchProduct(String article) async {
  final String url = 'http://${Configuration.ip_adress}:${Configuration.port}/product?article=$article';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      if (data.isEmpty) {
        print('Продукт с указанным артиклем не найден.');
        return null;
      }

      // Форматируем данные для удобной работы
      final Map<String, dynamic> product = {
        'id': data[0]['ТоварID'],
        'name': data[0]['Название'],
        'article': data[0]['Артикул'],
        'categoryId': data[0]['КатегорияID'],
        'category': data[0]['Категория'],
        'subcategory': data[0]['Подкатегория'],
        'brand': data[0]['Бренд'],
        'genderId': data[0]['ГендрID'],
        'gender': data[0]['Гендр'],
        'price': data[0]['Цена'],
        'description': data[0]['Описание'],
        'collectionId': data[0]['КоллекцияID'],
        'storeId': data[0]['МагазинID'],
        'dateAdded': data[0]['ДатаДобавления'],
        'colors': <Map<String, dynamic>>[],
        'hashtags': <Map<String, dynamic>>[],
        'obraz': data[0]['ОбразID'],
      };

      for (final item in data) {
        // Проверяем наличие цвета
        if (item['Цвет'] == null || item['КодЦвета'] == null) {
          print('Пропущен элемент из-за отсутствия данных о цвете: $item');
          continue;
        }

        // Найти или добавить цвет
        final colorIndex = product['colors'].indexWhere((existingColor) =>
            existingColor['name'] == item['Цвет'] &&
            existingColor['code'] == item['КодЦвета']);

        if (colorIndex == -1) {
          // Добавить новый цвет
          product['colors'].add({
            'name': item['Цвет'],
            'code': item['КодЦвета'],
            'sizes': <Map<String, dynamic>>[],
          });
        }

        // Добавить размер к соответствующему цвету
        final color = product['colors'].firstWhere((existingColor) =>
            existingColor['name'] == item['Цвет'] &&
            existingColor['code'] == item['КодЦвета']);

        if (item['Размер'] != null && item['РазмерID'] != null) {
          final size = {
            'id': item['РазмерID'],
            'value': item['Размер'],
          };

          if (!color['sizes'].any((existingSize) =>
              existingSize['id'] == size['id'] &&
              existingSize['value'] == size['value'])) {
            color['sizes'].add(size);
          }
        } else {
          print('Пропущен элемент из-за отсутствия данных о размере: $item');
        }

        // Добавляем уникальные хэштеги
        if (item['Хештег'] != null) {
          final hashtag = {
            'id': item['ХештегID'],
            'name': item['Хештег'],
          };
          if (!product['hashtags'].any((existingHashtag) =>
              existingHashtag['id'] == hashtag['id'] &&
              existingHashtag['name'] == hashtag['name'])) {
            product['hashtags'].add(hashtag);
          }
        }
      }

      return product;
    } else {
      print('Ошибка сервера: ${response.statusCode}');
      return null;
    }
  } catch (error) {
    print('Ошибка запроса: $error');
    return null;
  }
}
Future<List<Map<String, dynamic>>> fetchProductSizesByColorCode(
  String article, String colorCode) async {
  colorCode = colorCode.replaceAll('#', '');
  final String baseUrl = 'http://${Configuration.ip_adress}:${Configuration.port}';
  final String endpoint = '/sizesByColor';
  final String url = '$baseUrl$endpoint?article=$article&colorCode=$colorCode';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData == null || jsonData.isEmpty) {
        print('Нет доступных размеров для артикула $article и кода цвета $colorCode.');
        return [];
      }

      return List<Map<String, dynamic>>.from(jsonData);
    } else {
      print('Ошибка ${response.statusCode}: ${response.body}');
      throw Exception('Ошибка загрузки размеров: ${response.statusCode}');
    }
  } catch (error, stackTrace) {
    print('Ошибка при получении размеров: $error\n$stackTrace');
    throw Exception('Ошибка при получении размеров: $error');
  }
}

Future<List<Map<String, dynamic>>> fetchCategories({
  double? minPrice,
  double? maxPrice,
  bool isAdd = false,
  List<String>? colorNames,
  List<String>? brand,
  List<String>? tags,
  List<String>? gender,
}) async {
  final url = Uri(
    scheme: 'http',
    host: Configuration.ip_adress,
    port: Configuration.port,
    path: '/categories',
    queryParameters: {
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (isAdd) 'isAdd': isAdd.toString(),
      if (colorNames?.isNotEmpty ?? false) 'colors': colorNames!.join(','),
      if (brand?.isNotEmpty ?? false) 'brands': brand!.join(','),
      if (tags?.isNotEmpty ?? false) 'tags': tags!.join(','),
      if (gender != null && gender.isNotEmpty) 'gender': gender,
    },
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    print('Categor:');
    for (var item in data.cast<Map<String, dynamic>>()) {
  print(item['ПутьФото']);
}
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to fetch categories');
  }
}

Future<List<Map<String, dynamic>>> fetchBrand() async {
  final String baseUrl = 'http://${Configuration.ip_adress}:${Configuration.port}';
  final String endpoint = '/brand';
  final String url = '$baseUrl$endpoint';

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData == null || jsonData.isEmpty) {
        print('Нет доступных брендов.');
        return [];
      }

      return List<Map<String, dynamic>>.from(jsonData);
    } else {
      print('Ошибка ${response.statusCode}: ${response.body}');
      throw Exception('Ошибка загрузки брендов: ${response.statusCode}');
    }
  } catch (error, stackTrace) {
    print('Ошибка при получении брендов: $error\n$stackTrace');
    throw Exception('Ошибка при получении брендов: $error');
  }
}

Future<List<Map<String, dynamic>>> fetchTags({
  double? minPrice,
  double? maxPrice,
  List<String>? category,
  List<String>? brand,
  List<String>? colors,
  List<String>? gender,
}) async {
  final url = Uri(
    scheme: 'http',
    host: Configuration.ip_adress,
    port: Configuration.port,
    path: '/tags',
    queryParameters: {
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (category?.isNotEmpty ?? false) 'categories': category!.join(','),
      if (brand?.isNotEmpty ?? false) 'brands': brand!.join(','),
      if (colors?.isNotEmpty ?? false) 'tags': colors!.join(','), // 💡 tags — это цвета
      if (gender?.isNotEmpty ?? false) 'gender': gender,
    },
  );

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as List;
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    print('Error fetching tags: $e');
    return [];
  }
}


Future<List<Map<String, dynamic>>> fetchGender({
  double? minPrice,
  double? maxPrice,
  List<String>? category,
  List<String>? brand,
  List<String>? colors,
  List<String>? tags,
}) async {
  final url = Uri(
    scheme: 'http',
    host: Configuration.ip_adress,
    port: Configuration.port,
    path: '/gender',
    queryParameters: {
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (category?.isNotEmpty ?? false) 'categories': category!.join(','),
      if (brand?.isNotEmpty ?? false) 'brands': brand!.join(','),
      if (colors?.isNotEmpty ?? false) 'colors': colors!.join(','),
      if (tags?.isNotEmpty ?? false) 'tags': tags!.join(','),
    },
  );

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as List;
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return List<Map<String, dynamic>>.from(data);
    } else {
      print('Server error: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Error fetching gender: $e');
    return [];
  }
}


Future<List<Map<String, dynamic>>> fetchColors({
  double? minPrice,
  double? maxPrice,
  List<String>? category,
  List<String>? brand,
  List<String>? tags,
  List<String>? gender,
}) async {
  
  print(category);
  final url = Uri(
    scheme: 'http',
    host: Configuration.ip_adress,
    port: Configuration.port,
    path: '/colors',
    queryParameters: {
      if (minPrice != null) 'minPrice': minPrice.toString(),
      if (maxPrice != null) 'maxPrice': maxPrice.toString(),
      if (category?.isNotEmpty ?? false) 'categories': category!.join(','),
      if (brand?.isNotEmpty ?? false) 'brands': brand!.join(','),
      if (tags?.isNotEmpty ?? false) 'tags': tags!.join(','),
      if (gender != null) 'gender': gender,
    },
  );

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body) as List;
    return List<Map<String, dynamic>>.from(data);
  } catch (e) {
    print('Error fetching colors: $e');
    return [];
  }
}
Future<Map<String, dynamic>> fetchPriceRange({
  List<String>? colors,
  List<String>? categories,
  List<String>? brands,
  List<String>? genders,
  List<String>? tags,
}) async {
  final queryParams = <String, String>{};

  if (colors != null && colors.isNotEmpty) {
    queryParams['colors'] = colors.join(',');
  }
  if (categories != null && categories.isNotEmpty) {
    queryParams['categories'] = categories.join(',');
  }
  if (brands != null && brands.isNotEmpty) {
    queryParams['brands'] = brands.join(',');
  }
  if (genders != null && genders.isNotEmpty) {
    queryParams['genders'] = genders.join(',');
  }
  if (tags != null && tags.isNotEmpty) {
    queryParams['tags'] = tags.join(',');
  }

  final url = Uri(
    scheme: 'http',
    host: Configuration.ip_adress,
    port: Configuration.port,
    path: '/price-range',
    queryParameters: queryParams,
  );

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10));
    final data = jsonDecode(response.body);
    return Map<String, dynamic>.from(data);
  } catch (e) {
    print('Error fetching price range: $e');
    return {'minPrice': 0, 'maxPrice': 0};
  }
}
Future<List<Map<String, dynamic>>> fetchShop(int productId) async {
  final String baseUrl = 'http://${Configuration.ip_adress}:${Configuration.port}'; // Замените на адрес вашего сервера
  final String endpoint = '/shop';

  try {
    final Uri url = Uri.parse('$baseUrl$endpoint');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.cast<Map<String, dynamic>>();
     
    } else {
      throw Exception('Failed to fetch shop: ${response.statusCode}');
    }
  } catch (error) {
    // Обрабатываем ошибки
    print('Error fetching shop: $error');
    throw Exception('Error fetching shop: $error');
  }
}

Future<dynamic> fetchPromoCode({
  String? promoCode,
  int? userId,
}) async {
  try {
    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/check-promo',
      {
        if (promoCode != null) 'promoCode': promoCode,
        if (userId != null) 'userId': userId.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Не удалось загрузить промокод: ${response.statusCode}');
    }
  } catch (e) {
    print('Ошибка при загрузке промокода: $e');
    return null;
  }
}

Future<bool> createOrder({
  required String orderNumber,
  required int userId,
  required double sum,
  required DateTime orderPreparationDate,
  required List<Map<String, dynamic>> items,
  int? promoId,
}) async {
  final url = Uri.parse(
    'http://${Configuration.ip_adress}:${Configuration.port}/add-order',
  );

  // Создаём JSON-объект тела запроса
  final formattedDate = orderPreparationDate.toIso8601String();
  final Map<String, dynamic> requestBody = {
    'order_number': orderNumber,
    'user_id': userId,
    'sum': sum,
    'promo_id': promoId,
    'orderPreparationDate': formattedDate,
    'items': items, // <-- список товаров с количеством
  };

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('Заказ успешно оформлен');
        return true;
      } else {
        print('Ошибка: ${data['message']}');
        return false;
      }
    } else {
      print('Ошибка сервера: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    print('Ошибка при отправке запроса: $e');
    return false;
  }
}
Future<List<Map<String, dynamic>>> fetchOrders(String orderNumber,) async {
  final String baseUrl = 'http://${Configuration.ip_adress}:${Configuration.port}'; // Замените на адрес вашего сервера
  final String endpoint = '/orders';

  try {
    final Uri url = Uri.parse('$baseUrl$endpoint?order_number=$orderNumber');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      return jsonData.cast<Map<String, dynamic>>();
     
    } else {
      throw Exception('Failed to fetch order: ${response.statusCode}');
    }
  } catch (error) {
    // Обрабатываем ошибки
    print('Error fetching order: $error');
    throw Exception('Error fetching order: $error');
  }
}


}


// Future<List<Map<String, dynamic>>> getCartData() async {
//   final storage = FlutterSecureStorage();

//   try {
//     // Считывание данных из хранилища
//     final cartId = await storage.read(key: "ТоварРазмерID");
//     final productId = await storage.read(key: "ТоварID");
//     final name = await storage.read(key: "Название");
//     final price = await storage.read(key: "Цена");
//     final colorCode = await storage.read(key: "КодЦвета");
//     final color = await storage.read(key: "Цвет");
//     final globalSize = await storage.read(key: "Международный");
//     final ruSize = await storage.read(key: "Российский");
//     final count = await storage.read(key: "Количество");

//     // Преобразование данных в список карт (Map)
//     final cartData = [
//       {
//         'ТоварРазмерID': cartId != null ? int.tryParse(cartId) : null,
//         'ТоварID': productId != null ? int.tryParse(productId) : null,
//         'Название': name ?? '',
//         'Цена': price != null ? int.tryParse(price) : null,
//         'КодЦвета': colorCode ?? '',
//         'Цвет': color ?? '',
//         'Международный': globalSize ?? '',
//         'Российский': ruSize != null ? int.tryParse(ruSize) : null,
//         'Количество': count != null ? int.tryParse(count) : null,
//       }
//     ];

//     // Фильтрация, чтобы исключить некорректные данные (например, если ключи равны null)
//     return cartData.where((item) {
//       return item['ТоварРазмерID'] != null &&
//           item['ТоварID'] != null &&
//           item['Название'] != null &&
//           item['Цена'] != null;
//     }).toList();
//   } catch (e) {
//     print("Ошибка получения данных: $e");
//     return [];
//   }
// }
