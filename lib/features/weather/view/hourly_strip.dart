import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/units.dart';
import '../model/hourly_forecast.dart';
import '../model/weather_condition.dart';

/// 横向 24 小时预报条——天气 hero 卡之下，仅供浏览，不联动其他卡片。
///
/// 数据源：`forecast.hourly`，截到从当前小时开始的未来 24 条。
/// 当前小时（与 `DateTime.now()` 同年/月/日/时）描边 + 加粗以高亮。
class HourlyStrip extends StatelessWidget {
  const HourlyStrip({
    super.key,
    required this.hourly,
    required this.tempUnit,
    @visibleForTesting this.now,
  });

  final List<HourlyForecast> hourly;
  final TemperatureUnit tempUnit;

  /// 测试注入"当前时间"——生产代码不要传。
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) return const SizedBox.shrink();

    final reference = now ?? DateTime.now();
    final cells = _selectNext24(hourly, reference);
    if (cells.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: cells.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final h = cells[i];
          final isCurrent = _sameHour(h.time, reference);
          return _HourCell(
            hour: h,
            tempUnit: tempUnit,
            highlighted: isCurrent,
          );
        },
      ),
    );
  }

  static List<HourlyForecast> _selectNext24(
    List<HourlyForecast> all,
    DateTime ref,
  ) {
    // 找到 ref 当前小时（year/month/day/hour 一致）的索引；
    // 若没有（数据起点已过），从 0 开始取前 24 条。
    final startIdx = all.indexWhere((h) =>
        h.time.year == ref.year &&
        h.time.month == ref.month &&
        h.time.day == ref.day &&
        h.time.hour == ref.hour);
    final from = startIdx < 0 ? 0 : startIdx;
    final end = (from + 24).clamp(0, all.length);
    return all.sublist(from, end);
  }

  static bool _sameHour(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day &&
      a.hour == b.hour;
}

class _HourCell extends StatelessWidget {
  const _HourCell({
    required this.hour,
    required this.tempUnit,
    required this.highlighted,
  });

  final HourlyForecast hour;
  final TemperatureUnit tempUnit;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final container = highlighted
        ? AppColors.primaryFixed
        : AppColors.surfaceContainerLow;
    final foreground = highlighted
        ? AppColors.onPrimaryFixed
        : AppColors.onSurface;
    final border = highlighted
        ? Border.all(color: AppColors.primaryContainer, width: 1.5)
        : null;
    // 用 mainAxisSize.min + spacers 避免 spaceBetween 在某些 DPR 下因
     // 行高累加 1~2px 浮动而溢出固定容器（曾报 RenderFlex overflow）。
    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(16),
        border: border,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${hour.time.hour.toString().padLeft(2, '0')}时',
            style: AppTypography.labelCaps.copyWith(
              color: foreground,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _emoji(hour.condition),
            style: const TextStyle(fontSize: 20, height: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            formatTemperatureShort(hour.temperatureC, tempUnit),
            style: AppTypography.bodyMd.copyWith(
              color: foreground,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
              fontSize: 14,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  static String _emoji(WeatherCondition c) => switch (c) {
        WeatherCondition.clear => '☀️',
        WeatherCondition.mainlyClear => '🌤',
        WeatherCondition.partlyCloudy => '⛅',
        WeatherCondition.overcast => '☁️',
        WeatherCondition.fog => '🌫',
        WeatherCondition.drizzle => '🌦',
        WeatherCondition.rain => '🌧',
        WeatherCondition.freezingRain => '🧊',
        WeatherCondition.snow => '❄️',
        WeatherCondition.snowGrains => '🌨',
        WeatherCondition.showers => '🌦',
        WeatherCondition.snowShowers => '🌨',
        WeatherCondition.thunderstorm => '⛈',
        WeatherCondition.unknown => '·',
      };
}
