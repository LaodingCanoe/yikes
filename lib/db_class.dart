import 'dart:convert';
import 'package:http/http.dart' as http;
import 'configuration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseHelper {
  
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

  Future<List<Map<String, dynamic>>> fetchCategories(String endpoint) async {
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
          return data.map((item) => {
            'ПутьФото': item['ПутьФото'],
            'Название': item['Название']
          }).toList();
        } else {
          throw Exception('Unexpected data format');
        }
      } else {
        throw Exception('Failed to fetch categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
static Future<List<dynamic>> fetchProducts({
  int? gendrCode,
  int? categoryId,
  String? hashtag,
  int maxItems = 1000,
}) async {
  try {
    // Формируем URL с учетом переданных параметров
    final queryParameters = {
      if (gendrCode != null) 'gendrCode': gendrCode.toString(),
      if (categoryId != null) 'categoryId': categoryId.toString(),
      if (hashtag != null) 'hashtag': hashtag,
    };

    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/products',
      queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> fetchedProducts = json.decode(response.body);
      return fetchedProducts.take(maxItems).toList();
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading products: $e');
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

Future<bool> addToCart(int productId, int sizeId, int userId) async {
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
  int? productID,
  required int userId,
}) async {
  try {
    // Формируем URL с учетом переданных параметров
    final queryParameters = {
      if (productID != null) 'productID': productID.toString(),
       'userId': userId.toString(),
    };

    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/cart',
      queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> fetchCart = json.decode(response.body);
      return fetchCart.toList();
    } else {
      throw Exception('Failed to load cart: ${response.statusCode}');
    }
  } catch (e) {
    print('Error loading cart: $e');
    return [];
  }
}

Future<List<dynamic>> deleteCart({
  required int productID,
  required int userID,
}) async {
  print(productID); print(userID);
  try {
    final queryParameters = {
      'productID': productID.toString(),
      'userID': userID.toString(),
    };

    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/delete-cart',
      queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
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

Future<List<dynamic>> updateCart({
  required int productID,
  required bool plus,
  required int userID,
}) async {
  print(productID); print(userID);
  try {
    final queryParameters = {
      'productID': productID.toString(),
      'plus': plus.toString(),
      'userID': userID.toString(),
    };

    final uri = Uri.http(
      '${Configuration.ip_adress}:${Configuration.port}',
      '/update-cart',
      queryParameters,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        return jsonResponse['data'];
      } else {
        throw Exception('Server error: ${jsonResponse['error']}');
      }
    } else {
      throw Exception('Failed to update cart: ${response.statusCode}');
    }
  } catch (e) {
    print('Error update cart: $e');
    return [];
  }
}


}
