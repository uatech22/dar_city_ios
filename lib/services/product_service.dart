import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../models/category.dart';

class ProductService {
  static const String baseUrl = 'https://darcitybasketball.com/api';

  /// Fetch all products
  static Future<List<Product>> fetchProducts({
    String? category,
    String? search,
  }) async {
    final params = <String, String>{};

    if (category != null && category != 'all') {
      params['category'] = category;
    }

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }

    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: params);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return (body['data'] as List)
          .map((e) => Product.fromJson(e))
          .toList();
    } else {
      throw Exception('Failed to load products');
    }
  }


  /// Fetch all categories
  static Future<List<Category>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body)['data'];
      // The API returns a list of strings, so we map it directly.
      return body.map((name) => Category.fromJson(name)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }


  /// Fetch single product
  static Future<Product> fetchProductById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return Product.fromJson(body['data']);
    } else {
      throw Exception('Product not found');
    }
  }
}
