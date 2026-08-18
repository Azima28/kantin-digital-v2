import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    int statusCode, {
    T Function(dynamic)? dataParser,
  }) {
    final rawData = json['data'];
    T? parsedData;
    if (rawData != null && dataParser != null) {
      parsedData = dataParser(rawData);
    } else if (rawData != null && rawData is T) {
      parsedData = rawData;
    }

    return ApiResponse<T>(
      success: json['success'] == true || (statusCode >= 200 && statusCode < 300 && json['success'] != false),
      message: json['message'] as String?,
      data: parsedData,
      error: json['error'],
      statusCode: statusCode,
    );
  }
}

class ApiClient {
  final String baseUrl;
  String? _authToken;
  void Function(String newToken)? onTokenRenewed;

  ApiClient({
    String? baseUrl,
  }) : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'BACKEND_API_URL',
              defaultValue: 'http://127.0.0.1:8000/api/v1',
            );

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  String? get authToken => _authToken;

  void _checkRenewedToken(http.Response response) {
    final renewed = response.headers['x-renewed-token'];
    if (renewed != null && renewed.isNotEmpty && renewed != _authToken) {
      _authToken = renewed;
      onTokenRenewed?.call(renewed);
    }
  }

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    String cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    String cleanPath = path.startsWith('/') ? path : '/$path';
    String fullUrl = '$cleanBase$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final filteredParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          filteredParams[key] = value.toString();
        }
      });
      return Uri.parse(fullUrl).replace(queryParameters: filteredParams);
    }
    return Uri.parse(fullUrl);
  }

  Map<String, dynamic> _safeParseJson(http.Response response) {
    _checkRenewedToken(response);
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': decoded,
      };
    } catch (_) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.body.isNotEmpty ? response.body : null,
      };
    }
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .get(uri, headers: _buildHeaders())
          .timeout(const Duration(seconds: 15));

      final jsonBody = _safeParseJson(response);
      return ApiResponse.fromJson(jsonBody, response.statusCode, dataParser: dataParser);
    } catch (e) {
      debugPrint('[ApiClient GET Error] $path: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi ke backend gagal: $e',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .post(
            uri,
            headers: _buildHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      final jsonBody = _safeParseJson(response);
      return ApiResponse.fromJson(jsonBody, response.statusCode, dataParser: dataParser);
    } catch (e) {
      debugPrint('[ApiClient POST Error] $path: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi ke backend gagal: $e',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .put(
            uri,
            headers: _buildHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      final jsonBody = _safeParseJson(response);
      return ApiResponse.fromJson(jsonBody, response.statusCode, dataParser: dataParser);
    } catch (e) {
      debugPrint('[ApiClient PUT Error] $path: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi ke backend gagal: $e',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .patch(
            uri,
            headers: _buildHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      final jsonBody = _safeParseJson(response);
      return ApiResponse.fromJson(jsonBody, response.statusCode, dataParser: dataParser);
    } catch (e) {
      debugPrint('[ApiClient PATCH Error] $path: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi ke backend gagal: $e',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? dataParser,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final response = await http
          .delete(
            uri,
            headers: _buildHeaders(),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      final jsonBody = _safeParseJson(response);
      return ApiResponse.fromJson(jsonBody, response.statusCode, dataParser: dataParser);
    } catch (e) {
      debugPrint('[ApiClient DELETE Error] $path: $e');
      return ApiResponse<T>(
        success: false,
        message: 'Koneksi ke backend gagal: $e',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> uploadImage(
    String path,
    Uint8List bytes,
    String filename, {
    String fieldName = 'image',
  }) async {
    try {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);

      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      final jsonBody = _safeParseJson(response);
      return ApiResponse.fromJson(jsonBody, response.statusCode);
    } catch (e) {
      debugPrint('[ApiClient Upload Error] $path: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Gagal mengunggah gambar: $e',
        error: e.toString(),
        statusCode: 500,
      );
    }
  }
}
