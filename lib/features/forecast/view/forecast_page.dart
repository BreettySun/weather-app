import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/error/friendly_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/scrollable_fill.dart';
import '../../weather/controller/forecast_provider.dart';
import '../../weather/controller/location_provider.dart';
import '../../weather/model/daily_forecast.dart';
import '../../weather/model/weather_condition.dart';
import '../../weather/model/wind_utils.dart';

/// 预报页：展示 [forecastProvider] 中 7 日 [DailyForecast] 列表。
///
/// 三态（loading / error / data）共用 [RefreshIndicator]——
/// 错误态也支持下拉重试，与天气主页保持一致。
class ForecastPage extends ConsumerWidget {
  const ForecastPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncForecast = ref.watch(forecastProvider);
    final location = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      extendBody: true,
      appBar: const _ForecastAppBar(),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        color: AppColors.primaryContainer,
        child: asyncForecast.when(
          loading: () => const _LoadingView(),
          error: (e, _) => _ErrorView(
            message: friendlyErrorMessage(e),
            onRetry: () => ref.invalidate(forecastProvider),
          ),
          data: (forecast) => _DailyList(
            daily: forecast.daily,
            cityName: location?.name,
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    // ignore: unused_result
    ref.refresh(forecastProvider);
    try {
      await ref.read(forecastProvider.future);
    } catch (_) {
      // swallow: surfaces in AsyncValue.error
    }
  }
}

/// 与设置页同款磨砂玻璃顶栏。
class _ForecastAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ForecastAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xCCFFFFFF),
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Center(
            child: Text(
              '未来 7 日',
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
                height: 28 / 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyList extends StatelessWidget {
  const _DailyList({required this.daily, this.cityName});

  final List<DailyForecast> daily;
  final String? cityName;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    if (daily.isEmpty) {
      return ScrollableFill(
        child: Center(
          child: Text(
            '暂无预报数据',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final tempRange = _summarize(daily);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        24 + AppBottomNav.estimatedHeight + bottomInset,
      ),
      children: [
        _SummaryCard(
          cityName: cityName,
          dayCount: daily.length,
          minC: tempRange.$1,
          maxC: tempRange.$2,
        ),
        const SizedBox(height: 16),
        _DailyCard(daily: daily),
      ],
    );
  }

  /// 计算所有日的全局最低 / 最高温——用于摘要卡。
  (double, double) _summarize(List<DailyForecast> days) {
    var min = days.first.tempMinC;
    var max = days.first.tempMaxC;
    for (final d in days.skip(1)) {
      if (d.tempMinC < min) min = d.tempMinC;
      if (d.tempMaxC > max) max = d.tempMaxC;
    }
    return (min, max);
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.cityName,
    required this.dayCount,
    required this.minC,
    required this.maxC,
  });

  final String? cityName;
  final int dayCount;
  final double minC;
  final double maxC;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFA4C9FF), Color(0xFFD4E3FF)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cityName ?? '当前位置',
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSecondaryFixedVariant,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '未来 $dayCount 日',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSecondaryFixed,
              fontWeight: FontWeight.w700,
              height: 28 / 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${minC.round()}° / ${maxC.round()}°',
            style: AppTypography.headlineH2.copyWith(
              color: AppColors.onSecondaryFixed,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '总体温度区间',
            style: AppTypography.labelCaps.copyWith(
              letterSpacing: 0,
              color: AppColors.onSecondaryFixedVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.daily});

  final List<DailyForecast> daily;

  @override
  Widget build(BuildContext context) {
    // 用全局极值标定温度条相对位置——所有行共用同一比例。
    var minC = daily.first.tempMinC;
    var maxC = daily.first.tempMaxC;
    for (final d in daily.skip(1)) {
      if (d.tempMinC < minC) minC = d.tempMinC;
      if (d.tempMaxC > maxC) maxC = d.tempMaxC;
    }

    final today = DateTime.now();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < daily.length; i++)
            _DailyRow(
              day: daily[i],
              today: today,
              globalMinC: minC,
              globalMaxC: maxC,
              isFirst: i == 0,
              divider: i < daily.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({
    required this.day,
    required this.today,
    required this.globalMinC,
    required this.globalMaxC,
    required this.isFirst,
    required this.divider,
  });

  final DailyForecast day;
  final DateTime today;
  final double globalMinC;
  final double globalMaxC;
  final bool isFirst;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        border: divider
            ? const Border(
                bottom: BorderSide(color: AppColors.surfaceContainerHighest),
              )
            : null,
      ),
      child: Row(
        children: [
          // 日期标签：今天 / 明天 / 后天 / 周X
          SizedBox(
            width: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dayLabel(day.date, today, isFirst: isFirst),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _dateLabel(day.date),
                  style: AppTypography.labelCaps.copyWith(
                    letterSpacing: 0,
                    color: AppColors.onSurfaceVariant,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            _smallWeatherIcon(day.condition),
            width: 28,
            height: 28,
          ),
          const SizedBox(width: 8),
          // 中段：天气状况 + 可选的降水概率 chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weatherConditionLabel(day.condition),
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    height: 20 / 16,
                  ),
                ),
                if (day.precipitationProbabilityPct > 0) ...[
                  const SizedBox(height: 4),
                  _PrecipChip(probability: day.precipitationProbabilityPct),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 右侧：温度区间 + 温度条（让用户感知一周的相对冷热）
          SizedBox(
            width: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${day.tempMinC.round()}° / ${day.tempMaxC.round()}°',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                  ),
                ),
                const SizedBox(height: 6),
                _TempBar(
                  minC: day.tempMinC,
                  maxC: day.tempMaxC,
                  globalMinC: globalMinC,
                  globalMaxC: globalMaxC,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _dayLabel(DateTime date, DateTime today, {required bool isFirst}) {
    if (isFirst) return '今天';
    final diff = DateTime(date.year, date.month, date.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff == 1) return '明天';
    if (diff == 2) return '后天';
    return _weekdayLabel(date.weekday);
  }

  static String _dateLabel(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$m/$d';
  }

  static String _weekdayLabel(int weekday) {
    // DateTime.weekday: Mon=1..Sun=7
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[(weekday - 1) % 7];
  }
}

String _smallWeatherIcon(WeatherCondition c) {
  return switch (c) {
    WeatherCondition.clear ||
    WeatherCondition.mainlyClear =>
      'assets/icons/weather/small_clear.svg',
    WeatherCondition.partlyCloudy =>
      'assets/icons/weather/small_partly_cloudy.svg',
    _ => 'assets/icons/weather/small_cloudy.svg',
  };
}

class _PrecipChip extends StatelessWidget {
  const _PrecipChip({required this.probability});

  final int probability;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        '降水 $probability%',
        style: AppTypography.labelCaps.copyWith(
          letterSpacing: 0,
          color: AppColors.primaryContainer,
          height: 16 / 12,
        ),
      ),
    );
  }
}

/// 一根可视化温度条：在全局 [globalMinC, globalMaxC] 范围内画出当日的 min→max 段。
class _TempBar extends StatelessWidget {
  const _TempBar({
    required this.minC,
    required this.maxC,
    required this.globalMinC,
    required this.globalMaxC,
  });

  final double minC;
  final double maxC;
  final double globalMinC;
  final double globalMaxC;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final span = (globalMaxC - globalMinC).abs();
        // 极端兜底：所有日同温——画满整条，避免除零。
        if (span < 0.5) {
          return _bar(constraints.maxWidth, 0, constraints.maxWidth);
        }
        final width = constraints.maxWidth;
        final left = ((minC - globalMinC) / span) * width;
        final right = ((maxC - globalMinC) / span) * width;
        return _bar(width, left, right.clamp(left + 6, width));
      },
    );
  }

  Widget _bar(double total, double left, double right) {
    return SizedBox(
      width: total,
      height: 6,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
          Positioned(
            left: left,
            right: total - right,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA4C9FF), Color(0xFFFFB8B8)],
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ScrollableFill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              '正在获取预报…',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ScrollableFill(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 56,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '下拉也可重新加载',
                style: AppTypography.labelCaps.copyWith(
                  letterSpacing: 0,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

