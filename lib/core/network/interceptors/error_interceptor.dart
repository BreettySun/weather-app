import 'package:dio/dio.dart';

import '../../error/app_exception.dart';

/// 把 [DioException] 转换为应用统一的 [NetworkException]。
///
/// 通过 `handler.reject` 回传一个新的 [DioException]，其 [DioException.error]
/// 字段为转换后的 [NetworkException]，调用方可在 catch 处直接拿到。
class AppErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = _mapToAppException(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        stackTrace: err.stackTrace,
        message: exception.message,
      ),
    );
  }

  NetworkException _mapToAppException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('网络连接超时', cause: err, stackTrace: err.stackTrace);
      case DioExceptionType.connectionError:
        return NetworkException('网络连接失败', cause: err, stackTrace: err.stackTrace);
      case DioExceptionType.badCertificate:
        return NetworkException('证书校验失败', cause: err, stackTrace: err.stackTrace);
      case DioExceptionType.cancel:
        return NetworkException('请求已取消', cause: err, stackTrace: err.stackTrace);
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        return NetworkException(
          '服务异常 (${code ?? '?'})',
          statusCode: code,
          cause: err,
          stackTrace: err.stackTrace,
        );
      case DioExceptionType.unknown:
        return NetworkException(
          err.message ?? '未知网络错误',
          cause: err,
          stackTrace: err.stackTrace,
        );
    }
  }
}
