import 'dart:ui';

/// 6 档体感温度区间——共享给 outfit_provider 推荐器和 wardrobe_page 参考表。
///
/// 区间为半开区间 `[low, high)`；最低档 `low == double.negativeInfinity`，
/// 最高档 `high == double.infinity`。所有阈值都是 °C（API 原始单位），
/// 显示层按偏好换算。
enum TemperatureBracket {
  severeCold('严寒', double.negativeInfinity, 0, Color(0xFF5B8CFF)),
  cold('寒冷', 0, 8, Color(0xFFA4C9FF)),
  cool('凉爽', 8, 15, Color(0xFF7BC5A0)),
  mild('温和', 15, 22, Color(0xFFFFD66B)),
  warm('温暖', 22, 28, Color(0xFFFFA94D)),
  hot('炎热', 28, double.infinity, Color(0xFFFF7777));

  const TemperatureBracket(this.label, this.low, this.high, this.accent);

  final String label;
  final double low;
  final double high;
  final Color accent;

  bool contains(double feelsC) => feelsC >= low && feelsC < high;

  /// 没有命中（NaN/边界异常等）时回落到温和档——保证调用方拿到非空结果。
  static TemperatureBracket forFeels(double feelsC) {
    for (final b in values) {
      if (b.contains(feelsC)) return b;
    }
    return TemperatureBracket.mild;
  }
}
