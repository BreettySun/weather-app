/// 用户当天的活动场景——影响穿搭推荐的第四层 overlay。
///
/// 6 项固定枚举（不允许自由文本，避免 catalog 维度爆炸）。
/// `casual` 用作未指定时的兜底。
enum Activity {
  commute('通勤', '🧳'),
  exercise('健身', '🏃'),
  outing('出游', '🥾'),
  date('约会', '🍷'),
  formal('正式', '🤵'),
  casual('休闲', '☕');

  const Activity(this.label, this.emoji);

  final String label;
  final String emoji;
}

/// 默认卡的"兜底活动"——周一~周五 = commute，周六/周日 = casual。
///
/// 仅作为默认推荐的 activity 输入；用户实际的不同安排走事件机制（不修改默认卡）。
Activity defaultActivityForDate(DateTime date) {
  final w = date.weekday;
  if (w == DateTime.saturday || w == DateTime.sunday) {
    return Activity.casual;
  }
  return Activity.commute;
}

/// 与 [defaultActivityForDate] 配套——给 chip 显示的中文上下文标签。
/// 例："工作日 · 通勤" / "周末 · 休闲"。
String defaultActivityContextLabel(DateTime date) {
  final activity = defaultActivityForDate(date);
  final dayLabel = activity == Activity.casual ? '周末' : '工作日';
  return '$dayLabel · ${activity.label}';
}
