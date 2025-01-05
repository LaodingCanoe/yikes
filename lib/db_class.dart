import 'dart:convert';
import 'package:http/http.dart' as http;
import 'configuration.dart';

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

  static Future<List<dynamic>> fetchProducts(int gendrCode, {int maxItems = 10}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://${Configuration.ip_adress}:${Configuration.port}/products?gendrCode=$gendrCode',
        ),
      );

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
}
