import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 启动引导页：根据 Figma 设计实现。
///
/// 结构：
///  - 顶部 397dp 高的人物 / 云朵插画 + 暖色调渐变蒙版
///  - 底部白色面板（顶部圆角 48dp，向上重叠 48dp）：标题 + 副标题 + 主次按钮 + 隐私说明
///  - 右上方半透明胶囊形天气提示
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    this.onUseLocation,
    this.onManualCity,
    this.weatherChipText = '24°C',
  });

  final VoidCallback? onUseLocation;
  final VoidCallback? onManualCity;
  final String weatherChipText;

  static const double _heroHeight = 397;
  static const double _sheetOverlap = 48;
  static const double _safeMargin = 20;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroHeight,
            child: _HeroSection(),
          ),
          Positioned(
            top: _heroHeight - _sheetOverlap,
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomSheet(
              onUseLocation: onUseLocation,
              onManualCity: onManualCity,
            ),
          ),
          Positioned(
            top: topInset + _safeMargin,
            right: _safeMargin,
            child: _WeatherChip(text: weatherChipText),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/onboarding/hero.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x80FFF7ED), // rgba(255,247,237,0.5)
                  Color(0x00FFF7ED),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({this.onUseLocation, this.onManualCity});

  final VoidCallback? onUseLocation;
  final VoidCallback? onManualCity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.vertical(top: Radius.circular(48)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _Heading(),
                      _ActionsBlock(
                        onUseLocation: onUseLocation,
                        onManualCity: onManualCity,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SizedBox(
              width: 348,
              child: Text(
                '每天出门前，让我帮你搭配',
                textAlign: TextAlign.center,
                style: AppTypography.headlineH1.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 270,
            child: Text(
              '根据实时天气，推荐今日最佳穿搭',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsBlock extends StatelessWidget {
  const _ActionsBlock({this.onUseLocation, this.onManualCity});

  final VoidCallback? onUseLocation;
  final VoidCallback? onManualCity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 48),
      child: Column(
        children: [
          _PrimaryButton(
            label: '开启定位，获取天气',
            iconAsset: 'assets/icons/onboarding_location.svg',
            onPressed: onUseLocation,
          ),
          const SizedBox(height: 16),
          _SecondaryButton(
            label: '手动输入城市',
            iconAsset: 'assets/icons/onboarding_city.svg',
            onPressed: onManualCity,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 302,
            child: Text(
              '我们仅使用位置获取天气，不追踪您的行动轨迹',
              textAlign: TextAlign.center,
              style: AppTypography.labelCaps.copyWith(
                fontWeight: FontWeight.w500,
                height: 19.5 / 12,
                letterSpacing: 0.6,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.iconAsset,
    this.onPressed,
  });

  final String label;
  final String iconAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9999),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: -3,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.primaryContainer.withValues(alpha: 0.2),
            blurRadius: 6,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primaryContainer,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  iconAsset,
                  width: 18,
                  height: 18,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppTypography.button.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.iconAsset,
    this.onPressed,
  });

  final String label;
  final String iconAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 18,
                height: 19,
                colorFilter: const ColorFilter.mode(
                  AppColors.onSurfaceVariant,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.button.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  const _WeatherChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(21, 13, 21, 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/icons/onboarding_sun.svg',
                width: 16.5,
                height: 16.5,
                colorFilter: const ColorFilter.mode(
                  AppColors.primary,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
