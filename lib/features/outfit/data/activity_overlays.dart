import '../../events/model/activity.dart';
import '../model/temperature_bracket.dart';

/// 活动维度的 overlay——四层 cascade 的最外层（base ← style ← gender ← activity）。
///
/// 设计约束：
/// - 每条 overlay 仅覆盖该活动强相关的项，其余字段为 null（保留前一层值）。
/// - activity overlay **不依赖** style 的内容——独立查表。
/// - tip / accessory 不被 activity 改变（见 outfit_provider 注释）。
/// - 雨天兜底（防水短靴）位于最外层，会压过这里的运动鞋 / 徒步鞋等——安全 > 风格。
typedef ActivityOverlay = ({
  String? top,
  String? bottom,
  String? jacket,
  String? shoes,
});

/// commute / casual 不在表里——表示"不覆盖，沿用上一层"。
const Map<Activity, Map<TemperatureBracket, ActivityOverlay>> activityOverlays = {
  Activity.exercise: {
    TemperatureBracket.severeCold: (
      top: '保暖速干衣',
      bottom: '紧身保暖裤',
      jacket: '运动外套',
      shoes: '跑鞋',
    ),
    TemperatureBracket.cold: (
      top: '抓绒长袖',
      bottom: '运动长裤',
      jacket: '运动外套',
      shoes: '跑鞋',
    ),
    TemperatureBracket.cool: (
      top: '速干长袖',
      bottom: '运动长裤',
      jacket: null,
      shoes: '跑鞋',
    ),
    TemperatureBracket.mild: (
      top: '速干 T 恤',
      bottom: '运动短裤',
      jacket: null,
      shoes: '跑鞋',
    ),
    TemperatureBracket.warm: (
      top: '速干 T 恤',
      bottom: '运动短裤',
      jacket: null,
      shoes: '跑鞋',
    ),
    TemperatureBracket.hot: (
      top: '速干背心',
      bottom: '运动短裤',
      jacket: null,
      shoes: '跑鞋',
    ),
  },
  Activity.outing: {
    TemperatureBracket.severeCold: (
      top: null,
      bottom: null,
      jacket: '冲锋衣',
      shoes: '徒步鞋',
    ),
    TemperatureBracket.cold: (
      top: null,
      bottom: null,
      jacket: '冲锋衣',
      shoes: '徒步鞋',
    ),
    TemperatureBracket.cool: (
      top: null,
      bottom: null,
      jacket: '防风外套',
      shoes: '徒步鞋',
    ),
    TemperatureBracket.mild: (
      top: null,
      bottom: null,
      jacket: '防风外套',
      shoes: '徒步鞋',
    ),
    TemperatureBracket.warm: (
      top: null,
      bottom: null,
      jacket: null,
      shoes: '徒步鞋',
    ),
    TemperatureBracket.hot: (
      top: null,
      bottom: null,
      jacket: null,
      shoes: '徒步凉鞋',
    ),
  },
  Activity.date: {
    TemperatureBracket.severeCold: (
      top: null,
      bottom: null,
      jacket: '羊毛大衣',
      shoes: '切尔西靴',
    ),
    TemperatureBracket.cold: (
      top: null,
      bottom: null,
      jacket: '羊毛大衣',
      shoes: '切尔西靴',
    ),
    TemperatureBracket.cool: (
      top: null,
      bottom: null,
      jacket: '风衣',
      shoes: '乐福鞋',
    ),
    TemperatureBracket.mild: (
      top: null,
      bottom: null,
      jacket: '风衣',
      shoes: '乐福鞋',
    ),
    TemperatureBracket.warm: (
      top: null,
      bottom: null,
      jacket: null,
      shoes: '乐福鞋',
    ),
    TemperatureBracket.hot: (
      top: null,
      bottom: null,
      jacket: null,
      shoes: '乐福鞋',
    ),
  },
  Activity.formal: {
    TemperatureBracket.severeCold: (
      top: '高领衬衫',
      bottom: '西装长裤',
      jacket: '长款大衣',
      shoes: '商务皮靴',
    ),
    TemperatureBracket.cold: (
      top: '正装衬衫',
      bottom: '西装长裤',
      jacket: '加厚大衣',
      shoes: '商务皮鞋',
    ),
    TemperatureBracket.cool: (
      top: '正装衬衫',
      bottom: '西装长裤',
      jacket: '西装外套',
      shoes: '商务皮鞋',
    ),
    TemperatureBracket.mild: (
      top: '正装衬衫',
      bottom: '西装长裤',
      jacket: '薄西装',
      shoes: '商务皮鞋',
    ),
    TemperatureBracket.warm: (
      top: '短袖衬衫',
      bottom: '西装长裤',
      jacket: null,
      shoes: '商务皮鞋',
    ),
    TemperatureBracket.hot: (
      top: '短袖衬衫',
      bottom: '亚麻西裤',
      jacket: null,
      shoes: '乐福鞋',
    ),
  },
};
