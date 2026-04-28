/// 应用统一异常基类。
///
/// 各层（网络 / 存储 / 定位 / 业务）应抛出 [AppException] 的子类，
/// 以便 UI 层统一处理与展示。
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// 网络相关异常（连接、超时、HTTP 状态码、解析失败等）。
final class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    this.statusCode,
    super.cause,
    super.stackTrace,
  });

  final int? statusCode;
}

/// 本地存储相关异常。
final class StorageException extends AppException {
  const StorageException(super.message, {super.cause, super.stackTrace});
}

/// 定位 / 权限相关异常。
final class LocationException extends AppException {
  const LocationException(super.message, {super.cause, super.stackTrace});
}

/// 业务逻辑异常（参数校验、状态非法等）。
final class BusinessException extends AppException {
  const BusinessException(super.message, {super.cause, super.stackTrace});
}

/// 未预期的未知异常兜底。
final class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
