import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import 'promo_certificate.dart';

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.raw,
    required this.data,
  });

  final int statusCode;
  final String raw;
  final Object? data;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 20),
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status < 600,
      ),
    );
    allowExpiredPromoCertificate(dio);
    return dio;
  }

  final Dio _dio;

  Future<ApiResponse> postJson(
    String url, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) {
    return _send(
      () => _dio.post<String>(
        url,
        data: body,
        options: Options(
          headers: {'Accept': 'application/json', ...?headers},
          contentType: Headers.jsonContentType,
        ),
      ),
    );
  }

  Future<ApiResponse> get(Uri uri, {Map<String, String>? headers}) {
    return _send(
      () => _dio.get<String>(
        uri.toString(),
        options: Options(headers: {'Accept': 'application/json', ...?headers}),
      ),
    );
  }

  Future<ApiResponse> postXml(
    String url, {
    required String body,
    required Map<String, String> headers,
  }) {
    return _send(
      () => _dio.post<String>(
        url,
        data: body,
        options: Options(
          headers: headers,
          contentType: 'text/xml; charset=utf-8',
          responseType: ResponseType.plain,
        ),
      ),
    );
  }

  Future<ApiResponse> _send(Future<Response<String>> Function() request) async {
    try {
      final response = await request();
      final raw = response.data ?? '';
      return ApiResponse(
        statusCode: response.statusCode ?? 0,
        raw: raw,
        data: decodeBody(raw),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

Object? decodeBody(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  try {
    return jsonDecode(text);
  } on FormatException {
    return text;
  }
}

AppException mapDioException(DioException error) {
  final cause = error.error;
  final offline =
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError ||
      cause is SocketException;
  if (offline) return const NetworkException();
  return const NetworkException(
    'The connection was interrupted. Check your network and try again.',
  );
}

bool responseDeniesAccess(ApiResponse response) {
  if (response.statusCode == 401 || response.statusCode == 403) return true;
  final text = response.raw.toLowerCase();
  return text.contains('access denied') || text.contains('unauthorized');
}

void throwIfRejected(ApiResponse response, {String? serverMessage}) {
  if (response.isSuccess) return;
  if (responseDeniesAccess(response)) throw const UnauthorizedException();
  throw ServerException(
    serverMessage ??
        'The service is temporarily unavailable. Please try again.',
  );
}
