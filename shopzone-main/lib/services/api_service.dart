import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/constants.dart';

class ApiService {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}));
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['error']);
    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> register(String email, String password, String name) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'full_name': name}));
    if (res.statusCode != 201) throw Exception(jsonDecode(res.body)['error']);
    final data = jsonDecode(res.body);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['token']);
    return data;
  }

  static Future<List<Product>> getProducts({int? categoryId, String? search, bool? featured, String? sort}) async {
    final params = <String, String>{};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (search != null) params['search'] = search;
    if (featured == true) params['featured'] = 'true';
    if (sort != null) params['sort'] = sort;
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load products');
    return (jsonDecode(res.body) as List).map((j) => Product.fromJson(j)).toList();
  }

  static Future<Product> getProduct(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/products/$id'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Product not found');
    return Product.fromJson(jsonDecode(res.body));
  }

  static Future<List<Category>> getCategories() async {
    final res = await http.get(Uri.parse('$baseUrl/products/meta/categories'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load categories');
    return (jsonDecode(res.body) as List).map((j) => Category.fromJson(j)).toList();
  }

  static Future<List<CartItem>> getCart() async {
    final res = await http.get(Uri.parse('$baseUrl/cart'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load cart');
    return (jsonDecode(res.body) as List).map((j) => CartItem.fromJson(j)).toList();
  }

  static Future<void> addToCart(String productId, {int quantity = 1}) async {
    final res = await http.post(Uri.parse('$baseUrl/cart'),
        headers: await _headers(),
        body: jsonEncode({'product_id': productId, 'quantity': quantity}));
    if (res.statusCode != 201) throw Exception('Failed to add to cart');
  }

  static Future<void> updateCartItem(int id, int quantity) async {
    await http.put(Uri.parse('$baseUrl/cart/$id'),
        headers: await _headers(), body: jsonEncode({'quantity': quantity}));
  }

  static Future<void> removeFromCart(int id) async {
    await http.delete(Uri.parse('$baseUrl/cart/$id'), headers: await _headers());
  }

  static Future<Map<String, dynamic>> placeOrder(String? addressId, String paymentMethod) async {
    final res = await http.post(Uri.parse('$baseUrl/orders'),
        headers: await _headers(),
        body: jsonEncode({'address_id': addressId, 'payment_method': paymentMethod}));
    if (res.statusCode != 201) throw Exception(jsonDecode(res.body)['error']);
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> getOrders() async {
    final res = await http.get(Uri.parse('$baseUrl/tracking'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load orders');
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/tracking/$orderId'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load tracking');
    return jsonDecode(res.body);
  }

  static Future<String> createPaymentIntent(String orderId) async {
    final res = await http.post(Uri.parse('$baseUrl/payments/create-payment-intent'),
        headers: await _headers(), body: jsonEncode({'order_id': orderId}));
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['error']);
    return jsonDecode(res.body)['clientSecret'];
  }

  static Future<void> confirmPayment(String orderId, String paymentIntentId) async {
    final res = await http.post(Uri.parse('$baseUrl/payments/confirm'),
        headers: await _headers(),
        body: jsonEncode({'order_id': orderId, 'payment_intent_id': paymentIntentId}));
    if (res.statusCode != 200) throw Exception(jsonDecode(res.body)['error']);
  }

  static Future<Map<String, dynamic>> getReviews(String productId, {String? sort}) async {
    final params = sort != null ? '?sort=$sort' : '';
    final res = await http.get(Uri.parse('$baseUrl/reviews/product/$productId$params'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load reviews');
    return jsonDecode(res.body);
  }

  static Future<void> addReview(String productId, int rating, String title, String comment) async {
    final res = await http.post(Uri.parse('$baseUrl/reviews'),
        headers: await _headers(),
        body: jsonEncode({'product_id': productId, 'rating': rating, 'title': title, 'comment': comment}));
    if (res.statusCode != 201) throw Exception(jsonDecode(res.body)['error']);
  }

  static Future<void> markHelpful(int reviewId) async {
    await http.post(Uri.parse('$baseUrl/reviews/$reviewId/helpful'), headers: await _headers());
  }

  static Future<List<dynamic>> getAddresses() async {
    final res = await http.get(Uri.parse('$baseUrl/addresses'), headers: await _headers());
    if (res.statusCode != 200) throw Exception('Failed to load addresses');
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> addAddress(Map<String, dynamic> address) async {
    final res = await http.post(Uri.parse('$baseUrl/addresses'),
        headers: await _headers(), body: jsonEncode(address));
    if (res.statusCode != 201) throw Exception(jsonDecode(res.body)['error']);
    return jsonDecode(res.body);
  }

  static Future<void> updateAddress(String id, Map<String, dynamic> address) async {
    await http.put(Uri.parse('$baseUrl/addresses/$id'),
        headers: await _headers(), body: jsonEncode(address));
  }

  static Future<void> deleteAddress(String id) async {
    await http.delete(Uri.parse('$baseUrl/addresses/$id'), headers: await _headers());
  }

  static Future<void> setDefaultAddress(String id) async {
    await http.patch(Uri.parse('$baseUrl/addresses/$id/default'), headers: await _headers());
  }

  static Future<void> registerDeviceToken(String token) async {
    await http.post(Uri.parse('$baseUrl/notifications/register-token'),
        headers: await _headers(), body: jsonEncode({'token': token}));
  }
}