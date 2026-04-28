import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/geo_location.dart';

/// 当前选中的位置。引导页 / 城市搜索页负责写入；天气页 watch 它驱动取数。
///
/// 初始为 null —— 表示尚未授权 / 选择，UI 应停留在引导页。
final selectedLocationProvider = StateProvider<GeoLocation?>((ref) => null);
