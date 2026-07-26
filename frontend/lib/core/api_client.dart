import 'dart:convert';

import 'package:http/http.dart' as http;

import '../modules/auth/domain/repositories/auth_repository.dart';

/// The one place in the app that talks to the backend over HTTP. Every
/// request carries the current Firebase ID token as a Bearer header —
/// callers never attach it themselves.
class ApiClient {
  ApiClient(this._authRepository, {http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl =
          baseUrl ??
          const String.fromEnvironment(
            'API_BASE_URL',
            defaultValue: 'http://localhost:3000',
          );

  final AuthRepository _authRepository;
  final http.Client _client;
  final String baseUrl;

  Future<http.Response> get(String path) async {
    return _client.get(Uri.parse('$baseUrl$path'), headers: await _headers());
  }

  Future<http.Response> post(String path, Object body) async {
    return _client.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, Object body) async {
    return _client.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> patch(String path, Object body) async {
    return _client.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
  }

  Future<Map<String, String>> _headers() async {
    final token = await _authRepository.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
