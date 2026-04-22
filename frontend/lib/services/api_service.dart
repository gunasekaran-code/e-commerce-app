import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl = 'https://e-commerce-app-spee.onrender.com/api';
  
  // Enable debug mode to see detailed logs
  static const bool debugMode = true;
  
  // Helper method to log debug info
  static void _log(String message) {
    if (debugMode) {
      print('🔵 [API] $message');
    }
  }
  
  // Helper method to log errors
  static void _logError(String message) {
    if (debugMode) {
      print('🔴 [API ERROR] $message');
    }
  }

  // Ping server to wake it up (useful for Render free tier)
  static Future<bool> pingServer() async {
    try {
      _log('Pinging server to wake it up...');
      final response = await http
          .get(Uri.parse(baseUrl.replaceAll('/api', '')))
          .timeout(const Duration(seconds: 30));
      _log('Ping response: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 404;
    } catch (e) {
      _logError('Ping failed: $e');
      return false;
    }
  }

  // ============= USER APIs =============

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      _log('Attempting login to: $baseUrl/login/');
      _log('Email: $email');
      
      final requestBody = jsonEncode({'email': email, 'password': password});
      _log('Request body: $requestBody');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/login/'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30)); // Increased timeout

      _log('Response status: ${response.statusCode}');
      _log('Response headers: ${response.headers}');
      _log('Response body: ${response.body}');

      // Handle empty response body
      if (response.body.isEmpty) {
        _logError('Empty response body received');
        return {
          'success': false,
          'error': 'Server returned empty response. Status: ${response.statusCode}',
        };
      }

      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 200) {
          _log('Login successful');
          return {'success': true, 'data': data};
        } else {
          _logError('Login failed with status: ${response.statusCode}');
          return {
            'success': false,
            'error': data['error'] ?? data['detail'] ?? 'Login failed. Status: ${response.statusCode}',
          };
        }
      } catch (jsonError) {
        _logError('JSON parsing error: $jsonError');
        _logError('Raw response: ${response.body}');
        return {
          'success': false,
          'error': 'Server error. Status: ${response.statusCode}\n${response.body}',
        };
      }
    } on TimeoutException catch (e) {
      _logError('Request timeout: $e');
      return {
        'success': false,
        'error': 'Request timed out. The server might be starting up. Please try again.',
      };
    } catch (e) {
      _logError('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: $e\nPlease check your connection.',
      };
    }
  }

  // Login with automatic server wake-up
  static Future<Map<String, dynamic>> loginUserWithWakeUp({
    required String email,
    required String password,
  }) async {
    _log('Attempting to wake up server before login...');
    await pingServer();
    await Future.delayed(Duration(seconds: 2)); // Give server time to start
    return loginUser(email: email, password: password);
  }

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      _log('Attempting registration to: $baseUrl/users/create/');
      
      final requestBody = jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
      });
      _log('Request body: $requestBody');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/create/'),
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      _log('Response status: ${response.statusCode}');
      _log('Response body: ${response.body}');

      if (response.body.isEmpty) {
        _logError('Empty response body received');
        return {
          'success': false,
          'error': 'Server returned empty response. Status: ${response.statusCode}',
        };
      }

      try {
        final data = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          _log('Registration successful');
          return {'success': true, 'data': data};
        } else {
          _logError('Registration failed with status: ${response.statusCode}');
          return {
            'success': false,
            'error': data,
          };
        }
      } catch (jsonError) {
        _logError('JSON parsing error: $jsonError');
        return {
          'success': false,
          'error': 'Server error: ${response.body}',
        };
      }
    } on TimeoutException catch (e) {
      _logError('Request timeout: $e');
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
      };
    } catch (e) {
      _logError('Network error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  // ============= PRODUCT APIs =============

  static Future<List<Product>> getProducts({String? category}) async {
    try {
      String url = '$baseUrl/products/';
      if (category != null && category.isNotEmpty) url += '?category=$category';

      _log('Fetching products from: $url');
      final response = await http.get(Uri.parse(url));
      
      _log('Products response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        _log('Retrieved ${data.length} products');
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        _logError('Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      _logError('Error fetching products: $e');
    }
    return [];
  }

  static Future<List<Product>> getAllProductsAdmin() async {
    try {
      _log('Fetching all admin products');
      final response = await http.get(Uri.parse('$baseUrl/admin/products/'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
    } catch (e) {
      _logError('Error fetching admin products: $e');
    }
    return [];
  }

  static Future<Product?> getProductDetail(int id) async {
    try {
      _log('Fetching product detail for ID: $id');
      final response = await http.get(Uri.parse('$baseUrl/products/$id/'));
      
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      } else {
        _logError('Failed to fetch product detail: ${response.statusCode}');
      }
    } catch (e) {
      _logError('Error fetching product detail: $e');
    }
    return null;
  }

  static Future<bool> softDeleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/products/soft-delete/$id/'),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error soft deleting product: $e');
      return false;
    }
  }

  static Future<bool> restoreProduct(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/products/restore/$id/'),
      );
      return response.statusCode == 200;
    } catch (e) {
      _logError('Error restoring product: $e');
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
      _log('Creating product: $name');
      
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
        _log('Image attached: ${imageFile.name}');
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      _log('Create product response: ${response.statusCode}');
      _log('Response data: $responseData');
      
      if (response.statusCode == 201) {
        try {
          final data = jsonDecode(responseData);
          return {'success': true, 'data': data};
        } catch (e) {
          return {'success': true, 'data': responseData};
        }
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseData'};
      }
    } catch (e) {
      _logError('Error creating product: $e');
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
      _log('Updating product ID: $id');
      
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
      
      _log('Update product response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(responseData);
          return {'success': true, 'data': data};
        } catch (e) {
          return {'success': true, 'data': responseData};
        }
      } else {
        return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseData'};
      }
    } catch (e) {
      _logError('Error updating product: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  static Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
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
    } catch (e) {
      _logError('Error adding to cart: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getCart(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/cart/$userId/'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      _logError('Error fetching cart: $e');
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
    } catch (e) {
      _logError('Error updating cart item: $e');
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
    } catch (e) {
      _logError('Error removing from cart: $e');
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
    } catch (e) {
      _logError('Error fetching wishlist: $e');
    }
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
    } catch (e) {
      _logError('Error adding to wishlist: $e');
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
    } catch (e) {
      _logError('Error removing from wishlist: $e');
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
    } catch (e) {
      _logError('Error checking wishlist: $e');
    }
    return false;
  }

  static Future<double> getExchangeRate() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rates']['INR'] ?? 83.0;
      }
    } catch (e) {
      _logError('Error fetching exchange rate: $e');
    }
    return 83.0;
  }
}

// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import '../models/product_model.dart';

// class ApiService {
//   // static const String baseUrl = 'http://127.0.0.1:8000/api';     // mobile
//   // static const String baseUrl = 'http://10.0.2.2:8000/api';      // chrome
//   // static const String baseUrl = 'http://192.168.1.11/api';         // wifi network 
//   // static const String baseUrl = 'http://192.168.1.11:8000/api'; // Added :8000
//   static const String baseUrl = 'https://e-commerce-app-spee.onrender.com/api';    // Render API baseUrl


//   // ============= USER APIs =============

//   static Future<Map<String, dynamic>> loginUser({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/login/'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({'email': email, 'password': password}),
//           )
//           .timeout(const Duration(seconds: 10));

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return {'success': true, 'data': data};
//       } else {
//         return {
//           'success': false,
//           'error': data['error'] ?? 'Login failed. Please try again.',
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'error': 'Network error. Please check your connection.',
//       };
//     }
//   }

//   static Future<Map<String, dynamic>> registerUser({
//     required String fullName,
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await http
//           .post(
//             Uri.parse('$baseUrl/users/create/'),
//             headers: {'Content-Type': 'application/json'},
//             body: jsonEncode({
//               'full_name': fullName,
//               'email': email,
//               'password': password,
//             }),
//           )
//           .timeout(const Duration(seconds: 10));

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 201) {
//         return {'success': true, 'data': data};
//       } else {
//         return {
//           'success': false,
//           'error': data,
//         };
//       }
//     } catch (e) {
//       return {
//         'success': false,
//         'error': 'Network error. Please check your connection.',
//       };
//     }
//   }

//   // ============= PRODUCT APIs =============

//   static Future<List<Product>> getProducts({String? category}) async {
//     try {
//       String url = '$baseUrl/products/';
//       if (category != null && category.isNotEmpty) url += '?category=$category';

//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         List<dynamic> data = jsonDecode(response.body);
//         return data.map((json) => Product.fromJson(json)).toList();
//       }
//     } catch (_) {}
//     return [];
//   }

//   static Future<List<Product>> getAllProductsAdmin() async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/admin/products/'));
//       if (response.statusCode == 200) {
//         List<dynamic> data = jsonDecode(response.body);
//         return data.map((json) => Product.fromJson(json)).toList();
//       }
//     } catch (_) {}
//     return [];
//   }

//   static Future<Product?> getProductDetail(int id) async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/products/$id/'));
//       if (response.statusCode == 200) {
//         return Product.fromJson(jsonDecode(response.body));
//       }
//     } catch (_) {}
//     return null;
//   }

//   static Future<bool> softDeleteProduct(int id) async {
//     try {
//       final response = await http.delete(
//         Uri.parse('$baseUrl/admin/products/soft-delete/$id/'),
//       );
//       return response.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> restoreProduct(int id) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/admin/products/restore/$id/'),
//       );
//       return response.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<Map<String, dynamic>> createProduct({
//     required String name,
//     required String description,
//     required double price,
//     required String category,
//     XFile? imageFile,
//     required int stock,
//     double rating = 0.0,
//     int? skuId,
//   }) async {
//     try {
//       var request = http.MultipartRequest(
//         'POST',
//         Uri.parse('$baseUrl/admin/products/create/'),
//       );

//       // Add text fields
//       request.fields['name'] = name;
//       request.fields['description'] = description;
//       request.fields['price'] = price.toString();
//       request.fields['category'] = category;
//       request.fields['stock'] = stock.toString();
//       request.fields['rating'] = rating.toString();
//       if (skuId != null) {
//         request.fields['sku_id'] = skuId.toString();
//       }

//       // Add image file if selected
//       if (imageFile != null) {
//         final bytes = await imageFile.readAsBytes();
//         request.files.add(http.MultipartFile.fromBytes(
//           'image',
//           bytes,
//           filename: imageFile.name,
//         ));
//       }

//       final response = await request.send();
//       final responseData = await response.stream.bytesToString();
      
//       if (response.statusCode == 201) {
//         try {
//           final data = jsonDecode(responseData);
//           return {'success': true, 'data': data};
//         } catch (e) {
//           return {'success': true, 'data': responseData}; // Return raw data if JSON parsing fails
//         }
//       } else {
//         return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseData'};
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e'};
//     }
//   }

//   static Future<Map<String, dynamic>> updateProduct({
//     required int id,
//     required String name,
//     required String description,
//     required double price,
//     required String category,
//     XFile? imageFile,
//     required int stock,
//     double rating = 0.0,
//     int? skuId,
//   }) async {
//     try {
//       var request = http.MultipartRequest(
//         'PUT',
//         Uri.parse('$baseUrl/admin/products/update/$id/'),
//       );

//       // Add text fields
//       request.fields['name'] = name;
//       request.fields['description'] = description;
//       request.fields['price'] = price.toString();
//       request.fields['category'] = category;
//       request.fields['stock'] = stock.toString();
//       request.fields['rating'] = rating.toString();
//       if (skuId != null) {
//         request.fields['sku_id'] = skuId.toString();
//       }

//       // Add image file if selected
//       if (imageFile != null) {
//         final bytes = await imageFile.readAsBytes();
//         request.files.add(http.MultipartFile.fromBytes(
//           'image',
//           bytes,
//           filename: imageFile.name,
//         ));
//       }

//       final response = await request.send();
//       final responseData = await response.stream.bytesToString();
      
//       if (response.statusCode == 200) {
//         try {
//           final data = jsonDecode(responseData);
//           return {'success': true, 'data': data};
//         } catch (e) {
//           return {'success': true, 'data': responseData}; // Return raw data if JSON parsing fails
//         }
//       } else {
//         return {'success': false, 'error': 'HTTP ${response.statusCode}: $responseData'};
//       }
//     } catch (e) {
//       return {'success': false, 'error': 'Network error: $e'};
//     }
//   }

//   static Future<bool> addToCart({
//     required int userId,
//     required int productId,
//     int quantity = 1,
//   }) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/cart/add/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         "user_id": userId,
//         "product_id": productId,
//         "quantity": quantity,
//       }),
//     );

//     return response.statusCode == 200;
//   }

//   static Future<List<dynamic>> getCart(int userId) async {
//     final response = await http.get(Uri.parse('$baseUrl/cart/$userId/'));

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body);
//     }

//     return [];
//   }

//   static Future<bool> updateCartItem({
//     required int userId,
//     required int productId,
//     required int quantity,
//   }) async {
//     try {
//       final response = await http.put(
//         Uri.parse('$baseUrl/cart/update/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "user_id": userId,
//           "product_id": productId,
//           "quantity": quantity,
//         }),
//       );
//       return response.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> removeFromCart({
//     required int userId,
//     required int productId,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/cart/remove/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "user_id": userId,
//           "product_id": productId,
//         }),
//       );
//       return response.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   // ============= WISHLIST APIs =============

//   static Future<List<dynamic>> getWishlist(int userId) async {
//     try {
//       final response = await http.get(Uri.parse('$baseUrl/wishlist/$userId/'));
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       }
//     } catch (_) {}
//     return [];
//   }

//   static Future<bool> addToWishlist({
//     required int userId,
//     required int productId,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/wishlist/add/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "user_id": userId,
//           "product_id": productId,
//         }),
//       );
//       return response.statusCode == 200 || response.statusCode == 201;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> removeFromWishlist({
//     required int userId,
//     required int productId,
//   }) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/wishlist/remove/'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           "user_id": userId,
//           "product_id": productId,
//         }),
//       );
//       return response.statusCode == 200;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> isProductInWishlist({
//     required int userId,
//     required int productId,
//   }) async {
//     try {
//       final response = await http.get(
//         Uri.parse('$baseUrl/wishlist/check/$userId/$productId/'),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['is_in_wishlist'] ?? false;
//       }
//     } catch (_) {}
//     return false;
//   }

//   static Future<double> getExchangeRate() async {
//     try {
//       final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'));
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return data['rates']['INR'] ?? 83.0; // Default to 83 if not found
//       }
//     } catch (_) {}
//     return 83.0; // Default exchange rate
//   }
  
// }
