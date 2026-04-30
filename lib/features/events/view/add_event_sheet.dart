import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../controller/events_provider.dart';
import '../model/activity.dart';
import '../model/day_event.dart';

/// 弹一个 modal bottom sheet 让用户选时间 + 活动 + 备注，确认后写入。
///
/// 时间可选范围：当前小时 ~ 23:00（当日整点）；默认 = 下一个整点，超过 22 时默认 = 23 时。
Future<void> showAddEventSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const Padding(
      padding: EdgeInsets.only(top: 8),
      child: _AddEventForm(),
    ),
  );
}

class _AddEventForm extends ConsumerStatefulWidget {
  const _AddEventForm();

  @override
  ConsumerState<_AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends ConsumerState<_AddEventForm> {
  late int _hour; // 选中的小时 0~23
  Activity _activity = Activity.casual;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // 默认下一个整点；过了 22 时则锁到 23 时。
    _hour = now.hour >= 22 ? 23 : now.hour + 1;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  List<int> get _allowedHours {
    final minH = DateTime.now().hour;
    return [for (int h = minH; h <= 23; h++) h];
  }

  void _save() {
    final now = DateTime.now();
    final startAt = DateTime(now.year, now.month, now.day, _hour);
    ref.read(eventsProvider.notifier).add(
          DayEvent(
            id: DayEvent.newId(),
            activity: _activity,
            startAt: startAt,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          ),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '添加今日安排',
            style: AppTypography.bodyLg.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _Label('时间'),
          const SizedBox(height: 8),
          _HourPicker(
            allowedHours: _allowedHours,
            value: _hour,
            onChanged: (h) => setState(() => _hour = h),
          ),
          const SizedBox(height: 20),
          _Label('活动'),
          const SizedBox(height: 8),
          _ActivityChips(
            value: _activity,
            onChanged: (a) => setState(() => _activity = a),
          ),
          const SizedBox(height: 20),
          _Label('备注（可选）'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: '例如：公司团建',
              filled: true,
              fillColor: AppColors.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelCaps.copyWith(
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}

class _HourPicker extends StatelessWidget {
  const _HourPicker({
    required this.allowedHours,
    required this.value,
    required this.onChanged,
  });

  final List<int> allowedHours;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<int>(
        value: allowedHours.contains(value) ? value : allowedHours.first,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: [
          for (final h in allowedHours)
            DropdownMenuItem(
              value: h,
              child: Text('${h.toString().padLeft(2, '0')}:00'),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}

class _ActivityChips extends StatelessWidget {
  const _ActivityChips({required this.value, required this.onChanged});

  final Activity value;
  final ValueChanged<Activity> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in Activity.values)
          ChoiceChip(
            label: Text('${a.emoji} ${a.label}'),
            selected: value == a,
            onSelected: (_) => onChanged(a),
            selectedColor: AppColors.primaryFixed,
            labelStyle: AppTypography.bodyMd.copyWith(
              fontSize: 14,
              color: value == a ? AppColors.onPrimaryFixed : AppColors.onSurface,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: value == a
                    ? AppColors.primaryContainer
                    : AppColors.outlineVariant,
              ),
            ),
          ),
      ],
    );
  }
}
