import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// The promo host currently presents an expired certificate. Trust is relaxed
/// only for that host, so the other cabinet calls still verify TLS normally.
void allowExpiredPromoCertificate(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.badCertificateCallback = (certificate, host, port) {
        return host == 'api-forexcopy.contentdatapro.com';
      };
      return client;
    },
  );
}
