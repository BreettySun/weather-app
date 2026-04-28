import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controller/forecast_provider.dart';
import '../controller/location_provider.dart';
import '../model/daily_forecast.dart';
import '../model/weather_condition.dart';
import '../model/weather_forecast.dart';

/// 天气主页：当前为最简骨架，仅验证「定位 → 取数 → 渲染」链路。
///
/// 后续可在此基础上接入 DESIGN.md 设计的大温度 + 穿搭卡片 + 7 日预报。
class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider);
    final location = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(location?.name ?? '穿什么'),
      ),
      body: forecastAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(forecastProvider),
        ),
        data: (forecast) => _ForecastView(forecast: forecast),
      ),
    );
  }
}

class _ForecastView extends StatelessWidget {
  const _ForecastView({required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context) {
    final c = forecast.current;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${c.temperatureC.round()}°',
            style: AppTypography.display.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _conditionLabel(c.condition),
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _MetaRow(label: '体感', value: '${c.apparentTemperatureC.round()}°'),
          _MetaRow(label: '湿度', value: '${c.humidityPct}%'),
          _MetaRow(label: '风速', value: '${c.windSpeedKmh.round()} km/h'),
          _MetaRow(label: '降水', value: '${c.precipitationMm} mm'),
          const SizedBox(height: 32),
          Text('未来 ${forecast.daily.length} 天', style: AppTypography.headlineH2),
          const SizedBox(height: 16),
          for (final day in forecast.daily) _DailyRow(day: day),
        ],
      ),
    );
  }

  static String _conditionLabel(WeatherCondition c) {
    return switch (c) {
      WeatherCondition.clear => '晴',
      WeatherCondition.mainlyClear => '晴间多云',
      WeatherCondition.partlyCloudy => '局部多云',
      WeatherCondition.overcast => '阴',
      WeatherCondition.fog => '雾',
      WeatherCondition.drizzle => '毛毛雨',
      WeatherCondition.rain => '雨',
      WeatherCondition.freezingRain => '冻雨',
      WeatherCondition.snow => '雪',
      WeatherCondition.snowGrains => '雪粒',
      WeatherCondition.showers => '阵雨',
      WeatherCondition.snowShowers => '阵雪',
      WeatherCondition.thunderstorm => '雷暴',
      WeatherCondition.unknown => '—',
    };
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.day});

  final DailyForecast day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '${day.date.month}/${day.date.day}',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _ForecastView._conditionLabel(day.condition),
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            ),
          ),
          Text(
            '${day.tempMinC.round()}° / ${day.tempMaxC.round()}°',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
          ),
        ],
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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
