import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ============= USER APIs =============

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Login failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your connection.',
      };
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/create/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'full_name': fullName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false};
    } catch (_) {
      return {'success': false};
    }
  }

  // ============= PRODUCT APIs =============

  static Future<List<Product>> getProducts({String? category}) async {
    try {
      String url = '$baseUrl/products/';
      if (category != null && category.isNotEmpty) url += '?category=$category';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Product>> getAllProductsAdmin() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/admin/products/'));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Product?> getProductDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id/'));
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> softDeleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/soft-delete/$id/'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> restoreProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products/restore/$id/'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    XFile? imageFile,
    required int stock,
    double rating = 0.0,
    int? skuId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/products/create/'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      request.fields['stock'] = stock.toString();
      request.fields['rating'] = rating.toString();
      if (skuId != null) {
        request.fields['sku_id'] = skuId.toString();
      }

      // Add image file if selected
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(responseData);
          return {'success': true, 'data': data};
        } catch (e) {
          return {'success': true, 'data': responseData}; // Return raw data if JSON parsing fails
        }
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseData'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String name,
    required String description,
    required double price,
    required String category,
    XFile? imageFile,
    required int stock,
    double rating = 0.0,
    int? skuId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/admin/products/update/$id/'),
      );

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['category'] = category;
      request.fields['stock'] = stock.toString();
      request.fields['rating'] = rating.toString();
      if (skuId != null) {
        request.fields['sku_id'] = skuId.toString();
      }

      // Add image file if selected
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseData);
          return {'success': true, 'data': data};
        } catch (e) {
          return {'success': true, 'data': responseData}; // Return raw data if JSON parsing fails
        }
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseData'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/add/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": userId,
        "product_id": productId,
        "quantity": quantity,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getCart(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/cart/$userId/'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return [];
  }

  static Future<bool> updateCartItem({
    required int userId,
    required int productId,
    required int quantity,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/update/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "product_id": productId,
          "quantity": quantity,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeFromCart({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cart/remove/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "product_id": productId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ============= WISHLIST APIs =============

  static Future<List<dynamic>> getWishlist(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/wishlist/$userId/'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> addToWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/add/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "product_id": productId,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeFromWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlist/remove/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "user_id": userId,
          "product_id": productId,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isProductInWishlist({
    required int userId,
    required int productId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlist/check/$userId/$productId/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['is_in_wishlist'] ?? false;
      }
    } catch (_) {}
    return false;
  }

  static Future<double> getExchangeRate() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rates']['INR'] ?? 83.0; // Default to 83 if not found
      }
    } catch (_) {}
    return 83.0; // Default exchange rate
  }
  
}
