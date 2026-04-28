import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../outfit/controller/outfit_provider.dart';
import '../../outfit/model/outfit_recommendation.dart';
import '../controller/forecast_provider.dart';
import '../controller/location_provider.dart';
import '../model/current_weather.dart';
import '../model/daily_forecast.dart';
import '../model/geo_location.dart';
import '../model/weather_condition.dart';
import '../model/weather_forecast.dart';
import '../model/wind_utils.dart';

/// 天气主页（已按 Figma 1:37 设计实现）。
class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider);
    final location = ref.watch(selectedLocationProvider);
    final outfit = ref.watch(outfitRecommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _LocationBar(location: location),
            Expanded(
              child: forecastAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(forecastProvider),
                ),
                data: (forecast) => _MainContent(
                  forecast: forecast,
                  outfit: outfit,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

/// 顶部定位栏：浅灰底，左侧 pin + 城市名，右侧设置按钮。
class _LocationBar extends StatelessWidget {
  const _LocationBar({this.location});

  final GeoLocation? location;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(location);
    return Container(
      width: double.infinity,
      color: AppColors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/home/location_pin.svg',
            width: 16,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.onSurface,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onSurface,
                height: 28 / 18,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: 进入设置页
              },
              icon: SvgPicture.asset(
                'assets/icons/home/settings.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _displayName(GeoLocation? loc) {
    if (loc == null) return '当前位置';
    final name = loc.name;
    final admin = loc.admin1;
    if (admin != null && admin.isNotEmpty && admin != name) {
      return '$name · $admin';
    }
    return name;
  }
}

class _MainContent extends StatelessWidget {
  const _MainContent({required this.forecast, required this.outfit});

  final WeatherForecast forecast;
  final OutfitRecommendation? outfit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeatherCard(forecast: forecast),
          const SizedBox(height: 24),
          _OutfitSection(outfit: outfit),
          const SizedBox(height: 24),
          const _ActionButtons(),
        ],
      ),
    );
  }
}

/// 天气卡：渐变蓝底，含温度/条件、3 个数据 chip、3 日小预报。
class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.forecast});

  final WeatherForecast forecast;

  @override
  Widget build(BuildContext context) {
    final c = forecast.current;
    final daily = forecast.daily;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          // 136.37deg ≈ 自左上到右下
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
          _WeatherHeader(current: c),
          const SizedBox(height: 16),
          _WeatherChipsRow(current: c),
          const SizedBox(height: 16),
          _WeatherDivider(),
          const SizedBox(height: 16),
          _ThreeDayMini(daily: daily),
        ],
      ),
    );
  }
}

class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader({required this.current});

  final CurrentWeather current;

  @override
  Widget build(BuildContext context) {
    final tempStyle = AppTypography.bodyMd.copyWith(
      color: AppColors.onSecondaryFixed,
      fontWeight: FontWeight.w400,
      height: 16 / 16,
    );
    final conditionStyle = AppTypography.bodyMd.copyWith(
      color: AppColors.onSecondaryFixedVariant,
      height: 24 / 16,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${current.temperatureC.round()}°C', style: tempStyle),
              const SizedBox(height: 8),
              Text(
                weatherConditionLabel(current.condition),
                style: conditionStyle,
              ),
            ],
          ),
        ),
        SvgPicture.asset(
          'assets/icons/weather/big.svg',
          width: 63,
          height: 58.5,
        ),
      ],
    );
  }
}

class _WeatherChipsRow extends StatelessWidget {
  const _WeatherChipsRow({required this.current});

  final CurrentWeather current;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      '体感 ${current.apparentTemperatureC.round()}°C',
      '湿度 ${current.humidityPct}%',
      '${windDirectionToChinese(current.windDirectionDeg)}风 '
          '${windSpeedKmhToBeaufort(current.windSpeedKmh)}级',
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _WeatherChip(label: chips[i]),
        ],
      ],
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        label,
        style: AppTypography.labelCaps.copyWith(
          letterSpacing: 0,
          color: AppColors.onSecondaryFixed,
          height: 16 / 12,
        ),
      ),
    );
  }
}

class _WeatherDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _ThreeDayMini extends StatelessWidget {
  const _ThreeDayMini({required this.daily});

  final List<DailyForecast> daily;

  @override
  Widget build(BuildContext context) {
    final labels = ['今天', '明天', '后天'];
    final items = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final day = i < daily.length ? daily[i] : null;
      items.add(Expanded(child: _ThreeDayCell(label: labels[i], day: day)));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
}

class _ThreeDayCell extends StatelessWidget {
  const _ThreeDayCell({required this.label, required this.day});

  final String label;
  final DailyForecast? day;

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSecondaryFixedVariant,
            height: 24 / 16,
          ),
        ),
        const SizedBox(height: 4),
        SvgPicture.asset(
          _smallWeatherIcon(day?.condition),
          width: 22,
          height: 22,
        ),
        const SizedBox(height: 4),
        Text(
          day == null
              ? '—/—°'
              : '${day.tempMinC.round()}/${day.tempMaxC.round()}°',
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSecondaryFixed,
            fontWeight: FontWeight.w700,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }
}

String _smallWeatherIcon(WeatherCondition? c) {
  return switch (c) {
    WeatherCondition.clear ||
    WeatherCondition.mainlyClear =>
      'assets/icons/weather/small_clear.svg',
    WeatherCondition.partlyCloudy =>
      'assets/icons/weather/small_partly_cloudy.svg',
    _ => 'assets/icons/weather/small_cloudy.svg',
  };
}

/// 穿搭推荐区：标题 + 卡片（4 品类 / 大字提示 / 随身携带）。
class _OutfitSection extends StatelessWidget {
  const _OutfitSection({required this.outfit});

  final OutfitRecommendation? outfit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(
              'assets/icons/home/outfit_heading.svg',
              width: 18,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '今日穿搭建议',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurface,
                height: 24 / 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (outfit == null)
          const _OutfitPlaceholder()
        else
          _OutfitCard(outfit: outfit!),
      ],
    );
  }
}

class _OutfitPlaceholder extends StatelessWidget {
  const _OutfitPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      child: Text(
        '正在为你生成今日穿搭建议…',
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.outfit});

  final OutfitRecommendation outfit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OutfitItem(
                  iconAsset: 'assets/icons/outfit/top.svg',
                  category: '上衣',
                  name: outfit.top,
                ),
              ),
              Expanded(
                child: _OutfitItem(
                  iconAsset: 'assets/icons/outfit/bottom.svg',
                  category: '下装',
                  name: outfit.bottom,
                ),
              ),
              Expanded(
                child: _OutfitItem(
                  iconAsset: 'assets/icons/outfit/jacket.svg',
                  category: '外套',
                  name: outfit.jacket,
                ),
              ),
              Expanded(
                child: _OutfitItem(
                  iconAsset: 'assets/icons/outfit/shoes.svg',
                  category: '鞋履',
                  name: outfit.shoes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _OutfitTip(text: outfit.tip),
          const SizedBox(height: 16),
          _AccessoryPill(emoji: outfit.accessoryEmoji, label: outfit.accessory),
        ],
      ),
    );
  }
}

class _OutfitItem extends StatelessWidget {
  const _OutfitItem({
    required this.iconAsset,
    required this.category,
    required this.name,
  });

  final String iconAsset;
  final String category;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                AppColors.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$category：',
          textAlign: TextAlign.center,
          style: AppTypography.labelCaps.copyWith(
            letterSpacing: 0,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 15 / 12,
          ),
        ),
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppTypography.labelCaps.copyWith(
            letterSpacing: 0,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            height: 15 / 12,
          ),
        ),
      ],
    );
  }
}

class _OutfitTip extends StatelessWidget {
  const _OutfitTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE16D).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SvgPicture.asset(
              'assets/icons/home/alert.svg',
              width: 15.645,
              height: 12.437,
              colorFilter: const ColorFilter.mode(
                AppColors.onTertiaryContainer,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMd.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.onTertiaryContainer,
                height: 20 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessoryPill extends StatelessWidget {
  const _AccessoryPill({required this.emoji, required this.label});

  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 18, height: 28 / 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelCaps.copyWith(
                letterSpacing: 0,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 16 / 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: _OutlineButton(
              label: '查看详情',
              onPressed: () {
                // TODO: 详情页
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _FilledButton(
              label: '生成穿搭卡片 ✨',
              onPressed: () {
                // TODO: 生成卡片
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: const BorderSide(color: AppColors.surfaceContainerHigh, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: AppTypography.button.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 24 / 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            spreadRadius: -1,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: -2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(32),
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Center(
              child: Text(
                label,
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                  height: 24 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('天气', 'assets/icons/nav/weather.svg', true),
      ('穿搭', 'assets/icons/nav/outfit.svg', false),
      ('社区', 'assets/icons/nav/community.svg', false),
      ('我的', 'assets/icons/nav/profile.svg', false),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 9, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final item in items)
                _NavItem(label: item.$1, asset: item.$2, active: item.$3),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.asset,
    required this.active,
  });

  final String label;
  final String asset;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          asset,
          width: 22,
          height: 16,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelCaps.copyWith(
            letterSpacing: 0,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
            height: 15 / 10,
          ),
        ),
      ],
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
