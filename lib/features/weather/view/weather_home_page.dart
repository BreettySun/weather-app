import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/friendly_message.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/units.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/scrollable_fill.dart';
import '../../events/controller/events_provider.dart';
import '../../events/view/add_event_sheet.dart';
import '../../events/view/event_card.dart';
import '../../outfit/controller/outfit_provider.dart';
import '../../outfit/model/outfit_recommendation.dart';
import '../../settings/controller/preferences_provider.dart';
import '../controller/forecast_provider.dart';
import '../controller/location_provider.dart';
import '../model/current_weather.dart';
import '../model/daily_forecast.dart';
import '../model/geo_location.dart';
import '../model/weather_condition.dart';
import '../model/weather_forecast.dart';
import '../model/wind_utils.dart';
import 'hourly_strip.dart';

/// 天气主页（已按 Figma 1:37 设计实现）。
class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastProvider);
    final location = ref.watch(selectedLocationProvider);
    final outfit = ref.watch(outfitRecommendationProvider);
    final tempUnit = ref.watch(
      userPreferencesProvider.select((p) => p.temperatureUnit),
    );
    final windUnit = ref.watch(
      userPreferencesProvider.select((p) => p.windSpeedUnit),
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refresh(ref),
          color: AppColors.primaryContainer,
          // skipLoadingOnRefresh 默认 true——下拉刷新时仍展示旧数据，
          // 顶部菊花覆盖在内容之上，避免视图跳变。
          child: forecastAsync.when(
            loading: () => const _LoadingView(),
            error: (e, _) => _ErrorView(
              message: friendlyErrorMessage(e),
              onRetry: () => ref.invalidate(forecastProvider),
            ),
            data: (forecast) => _MainContent(
              forecast: forecast,
              location: location,
              outfit: outfit,
              tempUnit: tempUnit,
              windUnit: windUnit,
            ),
          ),
        ),
      ),
    );
  }

  /// 下拉刷新：重跑 [forecastProvider] 并等待新数据落地，
  /// 让 [RefreshIndicator] 的菊花在请求完成后再收起。
  /// 失败时不抛——错误已被 [AsyncValue] 捕获，[_ErrorView] 会接管。
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

class _MainContent extends StatelessWidget {
  const _MainContent({
    required this.forecast,
    required this.location,
    required this.outfit,
    required this.tempUnit,
    required this.windUnit,
  });

  final WeatherForecast forecast;
  final GeoLocation? location;
  final OutfitRecommendation? outfit;
  final TemperatureUnit tempUnit;
  final WindSpeedUnit windUnit;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SingleChildScrollView(
      // 必须始终可滚动——RefreshIndicator 依赖 overscroll 触发。
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        30 + AppBottomNav.estimatedHeight + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WeatherCard(
            forecast: forecast,
            location: location,
            tempUnit: tempUnit,
            windUnit: windUnit,
          ),
          if (forecast.hourly.isNotEmpty) ...[
            const SizedBox(height: 16),
            // 负 padding 让滚动条与外层 20dp 内容对齐——条目自带 16dp 内 padding。
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: HourlyStrip(
                hourly: forecast.hourly,
                tempUnit: tempUnit,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _OutfitSection(outfit: outfit),
          const SizedBox(height: 24),
          const _ActionButtons(),
          const SizedBox(height: 24),
          const _EventsSection(),
        ],
      ),
    );
  }
}

/// 天气卡：渐变蓝底，含定位、温度/条件、3 个数据 chip、3 日小预报。
class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.forecast,
    required this.location,
    required this.tempUnit,
    required this.windUnit,
  });

  final WeatherForecast forecast;
  final GeoLocation? location;
  final TemperatureUnit tempUnit;
  final WindSpeedUnit windUnit;

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
          _CardLocation(location: location),
          const SizedBox(height: 16),
          _WeatherHeader(current: c, tempUnit: tempUnit),
          const SizedBox(height: 16),
          _WeatherChipsRow(
            current: c,
            tempUnit: tempUnit,
            windUnit: windUnit,
          ),
          const SizedBox(height: 16),
          _WeatherDivider(),
          const SizedBox(height: 16),
          _ThreeDayMini(daily: daily, tempUnit: tempUnit),
        ],
      ),
    );
  }
}

/// 卡片内顶部定位行——pin + 城市名，文字色与 [_WeatherHeader] 一致以融入蓝底。
class _CardLocation extends StatelessWidget {
  const _CardLocation({required this.location});

  final GeoLocation? location;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/icons/home/location_pin.svg',
          width: 14,
          height: 18,
          colorFilter: const ColorFilter.mode(
            AppColors.onSecondaryFixed,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _displayName(location),
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSecondaryFixed,
              fontWeight: FontWeight.w500,
              height: 24 / 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

class _WeatherHeader extends StatelessWidget {
  const _WeatherHeader({required this.current, required this.tempUnit});

  final CurrentWeather current;
  final TemperatureUnit tempUnit;

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
              Text(
                formatTemperature(current.temperatureC, tempUnit),
                style: tempStyle,
              ),
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
  const _WeatherChipsRow({
    required this.current,
    required this.tempUnit,
    required this.windUnit,
  });

  final CurrentWeather current;
  final TemperatureUnit tempUnit;
  final WindSpeedUnit windUnit;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      '体感 ${formatTemperature(current.apparentTemperatureC, tempUnit)}',
      '湿度 ${current.humidityPct}%',
      '${windDirectionToChinese(current.windDirectionDeg)}风 '
          '${formatWindSpeed(current.windSpeedKmh, windUnit)}',
    ];
    // 用 Wrap 而非 Row——单位切换可能让"12 km/h"比"3级"明显加宽，
    // 在窄屏（如 iPhone 13 mini 375px）会横向溢出；Wrap 自动换行更稳。
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [for (final c in chips) _WeatherChip(label: c)],
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
  const _ThreeDayMini({required this.daily, required this.tempUnit});

  final List<DailyForecast> daily;
  final TemperatureUnit tempUnit;

  @override
  Widget build(BuildContext context) {
    final labels = ['今天', '明天', '后天'];
    final items = <Widget>[];
    for (var i = 0; i < 3; i++) {
      final day = i < daily.length ? daily[i] : null;
      items.add(
        Expanded(
          child: _ThreeDayCell(label: labels[i], day: day, tempUnit: tempUnit),
        ),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: items);
  }
}

class _ThreeDayCell extends StatelessWidget {
  const _ThreeDayCell({
    required this.label,
    required this.day,
    required this.tempUnit,
  });

  final String label;
  final DailyForecast? day;
  final TemperatureUnit tempUnit;

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
              : '${formatTemperatureShort(day.tempMinC, tempUnit)}/'
                  '${formatTemperatureShort(day.tempMaxC, tempUnit)}',
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

/// "今日安排"区——0 事件时只显示加号入口，>0 事件时再加标题与列表。
class _EventsSection extends ConsumerWidget {
  const _EventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (events.isNotEmpty) ...[
          Text(
            '今日安排',
            style: AppTypography.bodyLg.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final e in events) ...[
            EventCard(event: e),
            const SizedBox(height: 10),
          ],
        ],
        const _AddEventButton(),
      ],
    );
  }
}

class _AddEventButton extends StatelessWidget {
  const _AddEventButton();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => showAddEventSheet(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.outlineVariant,
            style: BorderStyle.solid,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add,
              size: 18,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(width: 6),
            Text(
              '添加专门安排',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
              onPressed: () => context.go(Routes.forecast),
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
              '正在获取天气…',
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
