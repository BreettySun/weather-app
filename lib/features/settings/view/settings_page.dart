import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/units.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/frosted_app_bar.dart';
import '../../weather/controller/location_provider.dart';
import '../controller/preferences_provider.dart';
import '../model/user_preferences.dart';

/// 设置页（已按 Figma 1:358 设计实现）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final controller = ref.read(userPreferencesProvider.notifier);
    final location = ref.watch(selectedLocationProvider);

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLow,
      extendBody: true,
      appBar: buildFrostedAppBar(context, title: '设置'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          32,
          20,
          16 + AppBottomNav.estimatedHeight + bottomInset,
        ),
        children: [
          _SectionHeader('我的偏好'),
          const SizedBox(height: 8),
          _PreferencesCard(
            prefs: prefs,
            onGenderChanged: controller.setGender,
            onStyleTap: () => _showStylePicker(context, ref),
            onSensitivityChanged: controller.setThermalSensitivity,
          ),
          const SizedBox(height: 32),
          _SectionHeader('单位'),
          const SizedBox(height: 8),
          _UnitsCard(
            prefs: prefs,
            onTemperatureUnitChanged: controller.setTemperatureUnit,
            onWindSpeedUnitChanged: controller.setWindSpeedUnit,
          ),
          const SizedBox(height: 32),
          _SectionHeader('推送提醒'),
          const SizedBox(height: 8),
          _NotificationsCard(
            prefs: prefs,
            onDailyReminderChanged: controller.setDailyReminderEnabled,
            onReminderTimeTap: () => _showTimePicker(context, ref),
            onRainAlertChanged: controller.setRainAlertEnabled,
          ),
          const SizedBox(height: 32),
          _SectionHeader('城市管理'),
          const SizedBox(height: 8),
          _CitiesCard(currentCityName: location?.name ?? '当前位置'),
          const SizedBox(height: 32),
          _SectionHeader('关于'),
          const SizedBox(height: 8),
          const _AboutCard(),
          const SizedBox(height: 16),
          const _LogoutButton(),
        ],
      ),
    );
  }

  void _showStylePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in ClothingStyle.values)
              ListTile(
                title: Text(s.label, style: AppTypography.bodyMd),
                onTap: () {
                  ref.read(userPreferencesProvider.notifier).setStyle(s);
                  Navigator.of(sheet).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(userPreferencesProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: prefs.reminderHour,
        minute: prefs.reminderMinute,
      ),
    );
    if (picked != null) {
      ref
          .read(userPreferencesProvider.notifier)
          .setReminderTime(picked.hour, picked.minute);
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

/// 白色圆角卡片容器。
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// 卡片内一行：上下 padding 24/25，左右 16，可选下边线。
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.child,
    this.divider = true,
    this.onTap,
  });

  final Widget child;
  final bool divider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 25),
      decoration: BoxDecoration(
        border: divider
            ? const Border(
                bottom: BorderSide(color: AppColors.surfaceContainerHighest),
              )
            : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.prefs,
    required this.onGenderChanged,
    required this.onStyleTap,
    required this.onSensitivityChanged,
  });

  final UserPreferences prefs;
  final ValueChanged<GenderPreference> onGenderChanged;
  final VoidCallback onStyleTap;
  final ValueChanged<double> onSensitivityChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _SettingRow(
          child: Row(
            children: [
              _RowLabel('性别偏好'),
              const Spacer(),
              _GenderSegmented(value: prefs.gender, onChanged: onGenderChanged),
            ],
          ),
        ),
        _SettingRow(
          onTap: onStyleTap,
          child: Row(
            children: [
              _RowLabel('穿衣风格'),
              const Spacer(),
              _ChevronValue(text: prefs.style.label),
            ],
          ),
        ),
        _SettingRow(
          divider: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RowLabel('怕冷 / 怕热'),
              const SizedBox(height: 16),
              _ThermalSlider(
                value: prefs.thermalSensitivity,
                onChanged: onSensitivityChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitsCard extends StatelessWidget {
  const _UnitsCard({
    required this.prefs,
    required this.onTemperatureUnitChanged,
    required this.onWindSpeedUnitChanged,
  });

  final UserPreferences prefs;
  final ValueChanged<TemperatureUnit> onTemperatureUnitChanged;
  final ValueChanged<WindSpeedUnit> onWindSpeedUnitChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _SettingRow(
          child: Row(
            children: [
              _RowLabel('温度单位'),
              const Spacer(),
              _EnumSegmented<TemperatureUnit>(
                value: prefs.temperatureUnit,
                values: TemperatureUnit.values,
                labelOf: (u) => u.symbol,
                onChanged: onTemperatureUnitChanged,
              ),
            ],
          ),
        ),
        _SettingRow(
          divider: false,
          child: Row(
            children: [
              _RowLabel('风速单位'),
              const Spacer(),
              _EnumSegmented<WindSpeedUnit>(
                value: prefs.windSpeedUnit,
                values: WindSpeedUnit.values,
                labelOf: (u) => u.symbol,
                onChanged: onWindSpeedUnitChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationsCard extends StatelessWidget {
  const _NotificationsCard({
    required this.prefs,
    required this.onDailyReminderChanged,
    required this.onReminderTimeTap,
    required this.onRainAlertChanged,
  });

  final UserPreferences prefs;
  final ValueChanged<bool> onDailyReminderChanged;
  final VoidCallback onReminderTimeTap;
  final ValueChanged<bool> onRainAlertChanged;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _SettingRow(
          child: Row(
            children: [
              _RowLabel('每日穿搭提醒'),
              const Spacer(),
              _StyledSwitch(
                value: prefs.dailyReminderEnabled,
                onChanged: onDailyReminderChanged,
              ),
            ],
          ),
        ),
        _SettingRow(
          onTap: onReminderTimeTap,
          child: Row(
            children: [
              _RowLabel('提醒时间'),
              const Spacer(),
              _ChevronValue(text: prefs.reminderTimeLabel),
            ],
          ),
        ),
        _SettingRow(
          divider: false,
          child: Row(
            children: [
              _RowLabel('降雨预警推送'),
              const Spacer(),
              _StyledSwitch(
                value: prefs.rainAlertEnabled,
                onChanged: onRainAlertChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CitiesCard extends StatelessWidget {
  const _CitiesCard({required this.currentCityName});

  final String currentCityName;

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _SettingRow(
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/settings/pin.svg',
                width: 16,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryContainer,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$currentCityName（当前定位）',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurface,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
        ),
        _SettingRow(
          divider: false,
          onTap: () {
            // TODO: 接入手动添加城市页
          },
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/settings/plus.svg',
                width: 22,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryContainer,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '添加常用城市',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.primaryContainer,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      children: [
        _SettingRow(
          child: Row(
            children: [
              _RowLabel('当前版本'),
              const Spacer(),
              Text(
                'v1.0.0',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
        ),
        _SettingRow(
          onTap: () {
            // TODO: 用户反馈页
          },
          child: Row(
            children: [
              _RowLabel('用户反馈'),
              const Spacer(),
              _ChevronOnly(),
            ],
          ),
        ),
        _SettingRow(
          divider: false,
          onTap: () {
            // TODO: 隐私政策页
          },
          child: Row(
            children: [
              _RowLabel('隐私政策'),
              const Spacer(),
              _ChevronOnly(),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () {
          // TODO: 退出登录
        },
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              '退出登录',
              style: AppTypography.button.copyWith(
                color: AppColors.error,
                height: 24 / 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyMd.copyWith(
        color: AppColors.onSurface,
        height: 24 / 16,
      ),
    );
  }
}

class _ChevronValue extends StatelessWidget {
  const _ChevronValue({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: AppTypography.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
            height: 24 / 16,
          ),
        ),
        const SizedBox(width: 4),
        SvgPicture.asset(
          'assets/icons/settings/chevron_right.svg',
          width: 6.167,
          height: 10,
          colorFilter: const ColorFilter.mode(
            AppColors.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}

class _ChevronOnly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/settings/chevron_right_thin.svg',
      width: 7.4,
      height: 12,
      colorFilter: const ColorFilter.mode(
        AppColors.onSurfaceVariant,
        BlendMode.srcIn,
      ),
    );
  }
}

class _GenderSegmented extends StatelessWidget {
  const _GenderSegmented({required this.value, required this.onChanged});

  final GenderPreference value;
  final ValueChanged<GenderPreference> onChanged;

  @override
  Widget build(BuildContext context) {
    return _EnumSegmented<GenderPreference>(
      value: value,
      values: GenderPreference.values,
      labelOf: (g) => g.label,
      onChanged: onChanged,
    );
  }
}

/// 圆角胶囊里的多选段——给 [_GenderSegmented] 和单位段共用。
class _EnumSegmented<T extends Enum> extends StatelessWidget {
  const _EnumSegmented({
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(9999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _SegmentButton(
              label: labelOf(values[i]),
              selected: values[i] == value,
              onTap: () => onChanged(values[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(9999),
      child: InkWell(
        borderRadius: BorderRadius.circular(9999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                )
              : null,
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.onSurfaceVariant,
              height: 20 / 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _StyledSwitch extends StatelessWidget {
  const _StyledSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.85,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primaryContainer,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.surfaceContainerHighest,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ThermalSlider extends StatelessWidget {
  const _ThermalSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/icons/settings/snowflake.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
            AppColors.secondary,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _SliderTrack(
                value: value,
                width: constraints.maxWidth,
                onChanged: onChanged,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        SvgPicture.asset(
          'assets/icons/settings/sun.svg',
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
      ],
    );
  }
}

class _SliderTrack extends StatelessWidget {
  const _SliderTrack({
    required this.value,
    required this.width,
    required this.onChanged,
  });

  final double value;
  final double width;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    void update(double dx) {
      final clamped = dx.clamp(0.0, width);
      onChanged(clamped / width);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => update(d.localPosition.dx),
      onTapDown: (d) => update(d.localPosition.dx),
      child: SizedBox(
        height: 24,
        width: width,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Center(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 8,
                width: value * width,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            Positioned(
              left: (value * width - 12).clamp(0.0, width - 24),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

