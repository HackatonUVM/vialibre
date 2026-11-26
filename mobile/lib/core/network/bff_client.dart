import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../auth/auth_service.dart';
import '../config/env.dart';

class BffException implements Exception {
  BffException(this.message, {this.statusCode, this.code = 'HTTP_ERROR'});

  final String message;
  final int? statusCode;
  final String code;

  @override
  String toString() => statusCode != null ? '$message ($statusCode)' : message;
}

/// Cliente HTTP hacia el Backend for Frontend (`bff/` en Next.js) con Bearer JWT
/// y manejo uniforme del formato `{ error: { code, message } }`.
class BffClient {
  BffClient(this._authService, {http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final AuthService _authService;
  final http.Client _http;

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) {
    return _request(
      'POST',
      path,
      body: body,
      requireAuth: requireAuth,
      timeout: const Duration(seconds: 45),
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool requireAuth = true,
  }) {
    return _request('GET', path, requireAuth: requireAuth);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) {
    return _request('PUT', path, body: body, requireAuth: requireAuth);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    bool requireAuth = true,
  }) {
    return _request('DELETE', path, requireAuth: requireAuth);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requireAuth = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (requireAuth && _authService.currentAccessToken == null) {
      await _authService.ensureSession();
    }

    final token = _authService.currentAccessToken;
    final uri = Uri.parse('${Env.bffBaseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    late final http.Response response;
    switch (method) {
      case 'GET':
        response = await _http.get(uri, headers: headers).timeout(timeout);
        break;
      case 'PUT':
        response = await _http
            .put(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(timeout);
        break;
      case 'DELETE':
        response = await _http.delete(uri, headers: headers).timeout(timeout);
        break;
      default:
        response = await _http
            .post(uri, headers: headers, body: jsonEncode(body ?? const {}))
            .timeout(timeout);
    }

    final decodedText = utf8.decode(response.bodyBytes);
    final dynamic decoded =
        decodedText.isNotEmpty ? jsonDecode(decodedText) : <String, dynamic>{};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (decoded is Map<String, dynamic> && decoded['error'] is Map) {
        final err = Map<String, dynamic>.from(decoded['error'] as Map);
        throw BffException(
          (err['message'] as String?) ?? 'Error en el servidor.',
          statusCode: response.statusCode,
          code: (err['code'] as String?) ?? 'HTTP_ERROR',
        );
      }
      throw BffException(
        'Error al conectar con el servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw BffException('Respuesta inesperada del servidor.');
  }
}

final bffClientProvider = Provider<BffClient>(
  (ref) => BffClient(ref.read(authServiceProvider)),
);
