import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'configuration.dart';


Future<List<String>> _fetchImages(String endpoint) async {
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
Future<List<String>> _fetchProductImages(int productId) async {
   try {
    final response = await http.get(
      Uri.parse('http://${Configuration.ip_adress}:${Configuration.port}/productImages?productId=$productId'),
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
  Future<List<Map<String, dynamic>>> _fetchCategories(String endpoint) async {
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

  