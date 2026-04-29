import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/error/friendly_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/units.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../outfit/controller/outfit_provider.dart';
import '../../outfit/data/outfit_catalog.dart';
import '../../outfit/model/outfit_pieces.dart';
import '../../outfit/model/outfit_recommendation.dart';
import '../../outfit/model/temperature_bracket.dart';
import '../../settings/controller/preferences_provider.dart';
import '../../weather/controller/forecast_provider.dart';

/// 衣橱页：以"穿搭参考"为定位——展示今日推荐 + 6 档温度区间穿搭手册。
///
/// 数据失败时仍展示静态参考表，只是隐藏今日推荐卡——因为参考表本身不依赖网络。
class WardrobePage extends ConsumerWidget {
  const WardrobePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncForecast = ref.watch(forecastProvider);
    final outfit = ref.watch(outfitRecommendationProvider);
    final prefs = ref.watch(userPreferencesProvider);
    // 体感温度（°C，原始值）——决定 [_BracketCard] 的高亮档位。
    final feels = asyncForecast.valueOrNull?.current.apparentTemperatureC;
    // 高亮匹配用调整过的体感——与推荐器保持一致，否则会出现"卡片说穿厚的、
    // 但参考表却高亮温和档"的撕裂感。
    final adjustedFeels = feels == null
        ? null
        : adjustFeelsBySensitivity(feels, prefs.thermalSensitivity);

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      extendBody: true,
      appBar: buildFrostedAppBar(context, title: '衣橱'),
      body: RefreshIndicator(
        onRefresh: () => _refresh(ref),
        color: AppColors.primaryContainer,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + AppBottomNav.estimatedHeight + bottomInset,
          ),
          children: [
            if (outfit != null) ...[
              _SectionHeader('今日推荐'),
              const SizedBox(height: 8),
              _TodayCard(
                outfit: outfit,
                feelsC: feels,
                tempUnit: prefs.temperatureUnit,
              ),
              const SizedBox(height: 24),
            ] else if (asyncForecast.hasError) ...[
              _ErrorBanner(
                message: friendlyErrorMessage(asyncForecast.error!),
                onRetry: () => ref.invalidate(forecastProvider),
              ),
              const SizedBox(height: 24),
            ],
            _SectionHeader('温度参考'),
            const SizedBox(height: 8),
            for (var i = 0; i < TemperatureBracket.values.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Builder(
                builder: (_) {
                  final bracket = TemperatureBracket.values[i];
                  final pieces = outfitPiecesFor(
                    bracket: bracket,
                    style: prefs.style,
                    gender: prefs.gender,
                  );
                  return _BracketCard(
                    bracket: bracket,
                    pieces: pieces,
                    tempUnit: prefs.temperatureUnit,
                    highlight: adjustedFeels != null &&
                        bracket.contains(adjustedFeels),
                  );
                },
              ),
            ],
          ],
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
      // surfaces in AsyncValue.error → _ErrorBanner
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: AppTypography.bodyMd.copyWith(
          color: AppColors.onSurfaceVariant,
          height: 24 / 16,
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.outfit,
    required this.tempUnit,
    this.feelsC,
  });

  final OutfitRecommendation outfit;
  final TemperatureUnit tempUnit;
  final double? feelsC;

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (feelsC != null)
            Text(
              '体感 ${formatTemperatureShort(feelsC!, tempUnit)}',
              style: AppTypography.labelCaps.copyWith(
                letterSpacing: 0,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CategoryBlock(
                  iconAsset: 'assets/icons/outfit/top.svg',
                  category: '上衣',
                  name: outfit.top,
                ),
              ),
              Expanded(
                child: _CategoryBlock(
                  iconAsset: 'assets/icons/outfit/bottom.svg',
                  category: '下装',
                  name: outfit.bottom,
                ),
              ),
              Expanded(
                child: _CategoryBlock(
                  iconAsset: 'assets/icons/outfit/jacket.svg',
                  category: '外套',
                  name: outfit.jacket,
                ),
              ),
              Expanded(
                child: _CategoryBlock(
                  iconAsset: 'assets/icons/outfit/shoes.svg',
                  category: '鞋履',
                  name: outfit.shoes,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
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
          category,
          textAlign: TextAlign.center,
          style: AppTypography.labelCaps.copyWith(
            letterSpacing: 0,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          name,
          textAlign: TextAlign.center,
          style: AppTypography.labelCaps.copyWith(
            letterSpacing: 0,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$message\n下方参考仍可查看',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurface,
                height: 20 / 14,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryContainer,
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _BracketCard extends StatelessWidget {
  const _BracketCard({
    required this.bracket,
    required this.pieces,
    required this.tempUnit,
    required this.highlight,
  });

  final TemperatureBracket bracket;
  final OutfitPieces pieces;
  final TemperatureUnit tempUnit;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight
              ? AppColors.primaryContainer
              : AppColors.surfaceContainerHighest,
          width: highlight ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 24,
                decoration: BoxDecoration(
                  color: bracket.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                bracket.label,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                  height: 24 / 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _rangeLabel(bracket, tempUnit),
                style: AppTypography.labelCaps.copyWith(
                  letterSpacing: 0,
                  color: AppColors.onSurfaceVariant,
                  height: 16 / 12,
                ),
              ),
              const Spacer(),
              if (highlight)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 2,
                  ),
                  child: Text(
                    '当前',
                    style: AppTypography.labelCaps.copyWith(
                      letterSpacing: 0,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: '上衣 · ${pieces.top}'),
              _Pill(label: '下装 · ${pieces.bottom}'),
              _Pill(label: '外套 · ${pieces.jacket}'),
              _Pill(label: '鞋履 · ${pieces.shoes}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: AppTypography.labelCaps.copyWith(
          letterSpacing: 0,
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
        ),
      ),
    );
  }
}

/// 把档位的 °C 半开区间渲染成"< 0°"/"0°–8°"/"≥ 28°"等字串，按目标温度单位转换。
String _rangeLabel(TemperatureBracket b, TemperatureUnit unit) {
  if (b.low == double.negativeInfinity) {
    return '< ${formatTemperatureShort(b.high, unit)}';
  }
  if (b.high == double.infinity) {
    return '≥ ${formatTemperatureShort(b.low, unit)}';
  }
  return '${formatTemperatureShort(b.low, unit)}'
      '–${formatTemperatureShort(b.high, unit)}';
}
