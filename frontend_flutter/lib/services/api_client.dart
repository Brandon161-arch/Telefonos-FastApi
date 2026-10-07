import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/catalog.dart';
import '../models/phone.dart';
import '../models/store_review.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );
  static const String _tokenKey = 'electrophone_token';
  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authenticated) {
      final token = (await SharedPreferences.getInstance()).getString(_tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body is Map<String, dynamic>
          ? (body['detail'] as String? ?? 'Error de conexión con la tienda')
          : 'Error de conexión con la tienda';
      throw ApiException(message, statusCode: response.statusCode);
    }
    return body;
  }

  Future<Map<String, dynamic>> _getMap(String path,
      {Map<String, String>? query}) async {
    final response = await _client.get(_uri(path, query), headers: await _headers());
    return _decode(response) as Map<String, dynamic>;
  }

  Future<List<Phone>> getPhones({
    int skip = 0,
    int limit = 12,
    String? search,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    int? ramGb,
    int? storageGb,
    bool? is5g,
    String sortBy = 'created_at',
  }) async {
    final query = <String, String>{
      'skip': '$skip',
      'limit': '$limit',
      'sort_by': sortBy,
    };
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (brandId != null) query['brand_id'] = '$brandId';
    if (minPrice != null) query['min_price'] = '$minPrice';
    if (maxPrice != null) query['max_price'] = '$maxPrice';
    if (ramGb != null) query['ram_gb'] = '$ramGb';
    if (storageGb != null) query['storage_gb'] = '$storageGb';
    if (is5g != null) query['is_5g'] = '$is5g';
    final data = await _getMap('/phones', query: query);
    return (data['data'] as List<dynamic>)
        .map((item) => Phone.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> getPhoneCount({
    String? search,
    int? brandId,
    double? minPrice,
    double? maxPrice,
    int? ramGb,
    int? storageGb,
    bool? is5g,
  }) async {
    final query = <String, String>{'skip': '0', 'limit': '1'};
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (brandId != null) query['brand_id'] = '$brandId';
    if (minPrice != null) query['min_price'] = '$minPrice';
    if (maxPrice != null) query['max_price'] = '$maxPrice';
    if (ramGb != null) query['ram_gb'] = '$ramGb';
    if (storageGb != null) query['storage_gb'] = '$storageGb';
    if (is5g != null) query['is_5g'] = '$is5g';
    final data = await _getMap('/phones', query: query);
    return (data['total'] as num).toInt();
  }

  Future<Phone> getPhone(String slug) async {
    final response = await _client.get(_uri('/phones/${Uri.encodeComponent(slug)}'));
    return Phone.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<List<StoreReview>> getReviews(int phoneId) async {
    final data = await _getMap('/phones/$phoneId/reviews');
    return (data['data'] as List<dynamic>)
        .map((item) => StoreReview.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addReview(int phoneId, {required int rating, required String comment}) async {
    final response = await _client.post(
      _uri('/phones/$phoneId/reviews'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    _decode(response);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(
      _uri('/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(response) as Map<String, dynamic>;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['access_token'] as String);
    await prefs.setString('electrophone_user', jsonEncode(data['user']));
    return data;
  }

  Future<void> register(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _uri('/auth/register'),
      headers: await _headers(),
      body: jsonEncode(payload),
    );
    _decode(response);
  }

  Future<void> verifyEmail(String token) async {
    final response = await _client.get(_uri('/auth/verify-email', {'token': token}));
    _decode(response);
  }

  Future<void> resendVerification(String email) async {
    final response = await _client.post(
      _uri('/auth/resend-verification'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );
    _decode(response);
  }

  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final response = await _client.get(
      _uri('/orders/my-orders'),
      headers: await _headers(authenticated: true),
    );
    return (_decode(response) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _uri('/orders'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(payload),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<List<Brand>> getBrands() async {
    final response = await _client.get(_uri('/brands'));
    return (_decode(response) as List<dynamic>)
        .map((item) => Brand.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> trackOrder(String orderNumber) async {
    final response = await _client.get(_uri('/orders/track/${Uri.encodeComponent(orderNumber)}'));
    return _decode(response) as Map<String, dynamic>;
  }

  Future<List<OrderSummary>> getAdminOrders() async {
    final response = await _client.get(_uri('/orders'), headers: await _headers(authenticated: true));
    return (_decode(response) as List<dynamic>)
        .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> changeOrderStatus(int orderId, String status) async {
    final response = await _client.patch(
      _uri('/orders/$orderId/status'),
      headers: await _headers(authenticated: true),
      body: jsonEncode({'status': status}),
    );
    _decode(response);
  }

  Future<AdminMetrics> getAdminMetrics() async {
    final response = await _client.get(_uri('/admin/metrics'), headers: await _headers(authenticated: true));
    return AdminMetrics.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<Phone> createPhone(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _uri('/phones'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(payload),
    );
    return Phone.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<Phone> updatePhone(int phoneId, Map<String, dynamic> payload) async {
    final response = await _client.put(
      _uri('/phones/$phoneId'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(payload),
    );
    return Phone.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<void> deletePhone(int phoneId) async {
    final response = await _client.delete(
      _uri('/phones/$phoneId'),
      headers: await _headers(authenticated: true),
    );
    _decode(response);
  }

  Future<Brand> createBrand(Map<String, dynamic> payload) async {
    final response = await _client.post(
      _uri('/brands'),
      headers: await _headers(authenticated: true),
      body: jsonEncode(payload),
    );
    return Brand.fromJson(_decode(response) as Map<String, dynamic>);
  }

  Future<void> deleteBrand(int brandId) async {
    final response = await _client.delete(
      _uri('/brands/$brandId'),
      headers: await _headers(authenticated: true),
    );
    _decode(response);
  }

  Future<List<Phone>> getFavorites() async {
    final response = await _client.get(_uri('/favorites'), headers: await _headers(authenticated: true));
    return (_decode(response) as List<dynamic>)
        .map((item) => Phone.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(int phoneId) async {
    final response = await _client.post(
      _uri('/favorites/$phoneId'),
      headers: await _headers(authenticated: true),
    );
    _decode(response);
  }

  Future<void> removeFavorite(int phoneId) async {
    final response = await _client.delete(
      _uri('/favorites/$phoneId'),
      headers: await _headers(authenticated: true),
    );
    _decode(response);
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) async {
    final response = await _client.post(
      _uri('/coupons/validate'),
      headers: await _headers(),
      body: jsonEncode({'code': code, 'subtotal': subtotal}),
    );
    return _decode(response) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('electrophone_user');
  }

  Future<String?> getToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<Map<String, dynamic>?> getSavedUser() async {
    final json = (await SharedPreferences.getInstance()).getString('electrophone_user');
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
