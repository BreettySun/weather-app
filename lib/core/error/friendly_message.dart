import 'app_exception.dart';

/// 把后端 / 系统异常翻译成给用户看的中文文案——所有 [AsyncValue.error] 分支应共用此映射。
String friendlyErrorMessage(Object e) {
  if (e is NetworkException) {
    final code = e.statusCode;
    if (code != null) return '网络出错（$code），请稍后重试';
    return '网络连接失败，请检查网络后重试';
  }
  if (e is LocationException) return e.message;
  if (e is AppException) return e.message;
  // forecastProvider 在没有位置时抛 StateError——理论上路由 redirect 已拦住，
  // 这里仍兜底一句友好文案。
  if (e is StateError) return '尚未选择城市，请返回引导页';
  return '出了点问题，请稍后再试';
}
