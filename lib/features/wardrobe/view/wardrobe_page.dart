import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/error/friendly_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../outfit/controller/outfit_provider.dart';
import '../../outfit/model/outfit_recommendation.dart';
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
    // 体感温度——决定 [_BracketCard] 的高亮档位。无数据时为 null，参考表全部不高亮。
    final feels = asyncForecast.valueOrNull?.current.apparentTemperatureC;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      extendBody: true,
      appBar: const _WardrobeAppBar(),
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
              _TodayCard(outfit: outfit, feelsC: feels),
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
            for (var i = 0; i < _brackets.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _BracketCard(
                bracket: _brackets[i],
                highlight: feels != null && _brackets[i].contains(feels),
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

class _WardrobeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _WardrobeAppBar();

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
              '衣橱',
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
  const _TodayCard({required this.outfit, this.feelsC});

  final OutfitRecommendation outfit;
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
              '体感 ${feelsC!.round()}°',
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
  const _BracketCard({required this.bracket, required this.highlight});

  final _Bracket bracket;
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
                bracket.range,
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
              _Pill(label: '上衣 · ${bracket.top}'),
              _Pill(label: '下装 · ${bracket.bottom}'),
              _Pill(label: '外套 · ${bracket.jacket}'),
              _Pill(label: '鞋履 · ${bracket.shoes}'),
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

/// 温度区间——半开区间 [low, high)；最高档 [high == double.infinity]。
class _Bracket {
  const _Bracket({
    required this.label,
    required this.range,
    required this.low,
    required this.high,
    required this.accent,
    required this.top,
    required this.bottom,
    required this.jacket,
    required this.shoes,
  });

  final String label;
  final String range;
  final double low;
  final double high;
  final Color accent;
  final String top;
  final String bottom;
  final String jacket;
  final String shoes;

  bool contains(double feels) => feels >= low && feels < high;
}

/// 温度档划分——边界与 outfit_provider 的规则推导器对齐，
/// 调整后两边都需要更新。
const _brackets = <_Bracket>[
  _Bracket(
    label: '严寒',
    range: '< 0°',
    low: double.negativeInfinity,
    high: 0,
    accent: Color(0xFF5B8CFF),
    top: '保暖打底衫',
    bottom: '加绒长裤',
    jacket: '羽绒服',
    shoes: '保暖短靴',
  ),
  _Bracket(
    label: '寒冷',
    range: '0°–8°',
    low: 0,
    high: 8,
    accent: Color(0xFFA4C9FF),
    top: '保暖打底衫',
    bottom: '加绒长裤',
    jacket: '加厚外套',
    shoes: '保暖短靴',
  ),
  _Bracket(
    label: '凉爽',
    range: '8°–15°',
    low: 8,
    high: 15,
    accent: Color(0xFF7BC5A0),
    top: '羊毛针织衫',
    bottom: '厚款长裤',
    jacket: '夹克 / 风衣',
    shoes: '运动鞋',
  ),
  _Bracket(
    label: '温和',
    range: '15°–22°',
    low: 15,
    high: 22,
    accent: Color(0xFFFFD66B),
    top: '长袖衬衫',
    bottom: '休闲长裤',
    jacket: '薄风衣',
    shoes: '运动鞋',
  ),
  _Bracket(
    label: '温暖',
    range: '22°–28°',
    low: 22,
    high: 28,
    accent: Color(0xFFFFA94D),
    top: '薄长袖 / T恤',
    bottom: '九分裤',
    jacket: '无需外套',
    shoes: '帆布鞋',
  ),
  _Bracket(
    label: '炎热',
    range: '≥ 28°',
    low: 28,
    high: double.infinity,
    accent: Color(0xFFFF7777),
    top: '冰丝短袖',
    bottom: '透气短裤',
    jacket: '无需外套',
    shoes: '帆布鞋',
  ),
];
