import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/units/units.dart';
import '../../outfit/controller/outfit_provider.dart';
import '../../settings/controller/preferences_provider.dart';
import '../../weather/controller/forecast_provider.dart';
import '../../weather/model/hourly_forecast.dart';
import '../controller/events_provider.dart';
import '../model/day_event.dart';

/// 单条事件卡——折叠/展开 + 左滑删除。
///
/// 折叠态：时间 + 活动 emoji + 标签 + 该时刻温度 + 一行单品摘要。
/// 展开态：完整 4 件 + tip 胶囊。
class EventCard extends ConsumerStatefulWidget {
  const EventCard({super.key, required this.event});

  final DayEvent event;

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final forecast = ref.watch(forecastProvider).valueOrNull;
    final prefs = ref.watch(userPreferencesProvider);
    final tempUnit = prefs.temperatureUnit;

    final hourly = forecast == null
        ? null
        : _findHourly(forecast.hourly, widget.event.startAt);
    final today = forecast?.daily.isNotEmpty == true ? forecast!.daily.first : null;
    final outfit = forecast == null
        ? null
        : recommendOutfit(
            current: forecast.current,
            today: today,
            targetHour: hourly,
            activity: widget.event.activity,
            prefs: prefs,
          );

    final stale = DateTime.now().difference(widget.event.startAt).inHours >= 1;
    final fg = stale ? AppColors.onSurfaceVariant : AppColors.onSurface;

    return Dismissible(
      key: ValueKey(widget.event.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(eventsProvider.notifier).remove(widget.event.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.onErrorContainer),
      ),
      child: Material(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(event: widget.event, hourly: hourly, tempUnit: tempUnit, fg: fg),
                const SizedBox(height: 8),
                _Summary(outfit: outfit, expanded: _expanded, fg: fg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static HourlyForecast? _findHourly(
    List<HourlyForecast> hourly,
    DateTime startAt,
  ) {
    for (final h in hourly) {
      if (h.time.year == startAt.year &&
          h.time.month == startAt.month &&
          h.time.day == startAt.day &&
          h.time.hour == startAt.hour) {
        return h;
      }
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.event,
    required this.hourly,
    required this.tempUnit,
    required this.fg,
  });

  final DayEvent event;
  final HourlyForecast? hourly;
  final TemperatureUnit tempUnit;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final time = '${event.startAt.hour.toString().padLeft(2, '0')}:00';
    final temp = hourly == null
        ? '--'
        : formatTemperatureShort(hourly!.temperatureC, tempUnit);
    final note = event.note;
    return Row(
      children: [
        Text(
          time,
          style: AppTypography.bodyLg.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Text(event.activity.emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          event.activity.label,
          style: AppTypography.bodyMd.copyWith(color: fg),
        ),
        if (note != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '· $note',
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        const Spacer(),
        Text(
          temp,
          style: AppTypography.bodyLg.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.outfit,
    required this.expanded,
    required this.fg,
  });

  // 用 dynamic 是为了避免在 widget 内多耦合 OutfitRecommendation 的 import；
  // 实际类型见 outfit_provider 的 OutfitRecommendation。
  final dynamic outfit;
  final bool expanded;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    if (outfit == null) {
      return Text(
        '加载中…',
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
      );
    }
    if (!expanded) {
      // 折叠：只看 jacket / shoes 两件——最容易让用户感到"够用与否"
      final summary = '${outfit.jacket} · ${outfit.shoes}';
      return Text(
        summary,
        style: AppTypography.bodyMd.copyWith(color: fg, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line('上衣', outfit.top, fg),
        _Line('下装', outfit.bottom, fg),
        _Line('外套', outfit.jacket, fg),
        _Line('鞋履', outfit.shoes, fg),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tertiaryFixed,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            outfit.tip,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onTertiaryFixed,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, this.fg);
  final String label;
  final String value;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMd.copyWith(color: fg, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
