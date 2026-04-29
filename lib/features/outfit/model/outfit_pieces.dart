import 'package:flutter/foundation.dart';

/// 已解析的 4 件穿搭——catalog 输出，由推荐器/参考表共用。
@immutable
class OutfitPieces {
  const OutfitPieces({
    required this.top,
    required this.bottom,
    required this.jacket,
    required this.shoes,
  });

  final String top;
  final String bottom;
  final String jacket;
  final String shoes;
}
