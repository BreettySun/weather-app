import 'package:flutter/foundation.dart';

/// 穿搭推荐——4 个固定品类 + 2 段提示。
@immutable
class OutfitRecommendation {
  const OutfitRecommendation({
    required this.top,
    required this.bottom,
    required this.jacket,
    required this.shoes,
    required this.tip,
    required this.accessory,
    required this.accessoryEmoji,
  });

  /// 上衣
  final String top;

  /// 下装
  final String bottom;

  /// 外套
  final String jacket;

  /// 鞋履
  final String shoes;

  /// 黄底大字提示，如"早晚温差较大，建议带外套"
  final String tip;

  /// 灰底胶囊里的随身携带项主体文本，如"折叠雨伞（傍晚有阵雨）"
  final String accessory;

  /// 配合 [accessory] 显示的 emoji，如 "💼"
  final String accessoryEmoji;
}
