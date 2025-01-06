import 'dart:convert';
import 'package:http/http.dart' as http;
import 'configuration.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  int? gendrCode = null,
  int? categoryId = null,
  int maxItems = 10,
}) async {
  try {
    // Формируем URL с учетом переданных параметров
    final queryParameters = {
      if (gendrCode != null) 'gendrCode': gendrCode.toString(),
      if (categoryId != null) 'categoryId': categoryId.toString(),
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


  Future<bool> registerUser(String email, String password, String username) async {
  final url = 'http://${Configuration.ip_adress}:${Configuration.port}/register'; // Замените на ваш URL

  final response = await http.post(
    Uri.parse(url),
    headers: {"Content-Type": "application/json"},
    body: json.encode({
      "email": email,
      "password": password,
      "username": username,
    }),
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    print("Error: ${response.body}");
    return false;
  }
}


Future<Map<String, String>> getLoginData() async {
  final storage = FlutterSecureStorage();
  final token = await storage.read(key: "token") ?? '';
  final email = await storage.read(key: "email") ?? '';
  return {"token": token, "email": email};
}

Future<bool> loginUser(String email, String password) async {
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
    await saveLoginData(data['token'], email); // Сохраняем токен и email
    return true;
  } else {
    print("Error: ${response.body}");
    return false;
  }
}



Future<void> saveLoginData(String token, String email) async {
  final storage = FlutterSecureStorage();
  await storage.write(key: "token", value: token);
  await storage.write(key: "email", value: email);
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

}
