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
