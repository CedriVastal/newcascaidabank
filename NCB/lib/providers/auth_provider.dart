// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  // ========= State =========
  String? _token;
  String? _username;

  final String baseUrl = 'https://beetle-driven-flea.ngrok-free.app';

  // ========= Getters =========
  String? get token => _token;
  String? get username => _username;

  // ========= Auth =========
  Future<void> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      _token = data['access_token'] as String?;
      _username = username;
      notifyListeners();
    } else {
      throw Exception('Login failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> register(String username, String password) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    );

    if (res.statusCode == 200) {
      // Registration succeeded. You can auto-login or keep it simple:
      _username = username;
      notifyListeners();
    } else {
      throw Exception('Registration failed: ${res.statusCode} ${res.body}');
    }
  }

  // ========= Balance =========
  Future<int> fetchBalance(String username) async {
    if (_token == null) throw Exception('Not authenticated');
    final res = await http.get(
      Uri.parse('$baseUrl/players/balance/$username'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      return (data['balance'] as num).toInt();
    } else {
      throw Exception('Failed to fetch balance: ${res.statusCode} ${res.body}');
    }
  }

  // ========= Transfer =========
  Future<Map<String, dynamic>> transfer({
    required String toUsername,
    required int amount,
    String? description,
  }) async {
    if (_token == null) throw Exception("Not authenticated");

    final res = await http.post(
      Uri.parse('$baseUrl/transactions/transfer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({
        'to_username': toUsername,
        'amount': amount,
        'description': description,
      }),
    );

    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Transfer failed: ${res.statusCode} ${res.body}');
    }
  }

  // ========= Username Autocomplete =========
  Future<List<String>> searchUsers(String query) async {
    if (_token == null || query.isEmpty) return [];
    final res = await http.get(
      Uri.parse('$baseUrl/auth/users?q=${Uri.encodeQueryComponent(query)}'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> results = data['results'] ?? [];
      return results.cast<String>();
    } else {
      // Return empty list on error; log if needed
      return [];
    }
  }

  // ========= Utility =========
  void logout() {
    _token = null;
    _username = null;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> fetchTransactions(String username, {int limit = 50}) async {
    if (_token == null) throw Exception('Not authenticated');
    final res = await http.get(
      Uri.parse('$baseUrl/transactions/history/$username?limit=$limit'),
      headers: {'Authorization': 'Bearer $_token'},
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final List<dynamic> items = data['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch history: ${res.statusCode} ${res.body}');
    }
  }
  Future<List<Map<String, dynamic>>> fetchShopItems() async {
  if (_token == null) throw Exception('Not authenticated');
  final res = await http.get(
    Uri.parse('$baseUrl/shop/items'),
    headers: {'Authorization': 'Bearer $_token'},
  );
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    // expecting a list of items with: id, name, price, description, category, stock
    final List<dynamic> items = data as List<dynamic>;
    return items.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load items: ${res.statusCode} ${res.body}');
  }
}

// Purchase an item (requires backend POST /transactions/purchase)
  Future<Map<String, dynamic>> purchaseItem({required int itemId}) async {
    if (_token == null) throw Exception('Not authenticated');
    final res = await http.post(
      Uri.parse('$baseUrl/shop/purchase'), // <-- was /transactions/purchase
     headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      },
      body: jsonEncode({'item_id': itemId}),
    );
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Purchase failed: ${res.statusCode} ${res.body}');
    }
  }
}