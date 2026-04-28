import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'interceptors/error_interceptor.dart';
import 'interceptors/log_interceptor.dart';

/// 全局 [Dio] 实例。具体 baseUrl / headers 由各 feature 的 repository
/// 通过 BaseOptions 覆盖，或在 provider override 中按需替换。
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AppErrorInterceptor(),
    AppLogInterceptor(),
  ]);

  return dio;
});
