import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 简易请求日志拦截器。仅在 debug 模式下输出，避免生产泄露。
class AppLogInterceptor extends Interceptor {
  static const _tag = 'http';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '→ ${options.method} ${options.uri}',
        name: _tag,
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.uri}',
        name: _tag,
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '✗ ${err.requestOptions.method} ${err.requestOptions.uri} '
        '— ${err.type} ${err.response?.statusCode ?? ''}',
        name: _tag,
        error: err,
      );
    }
    handler.next(err);
  }
}
