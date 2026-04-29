import '../../settings/model/user_preferences.dart';
import '../model/outfit_pieces.dart';
import '../model/temperature_bracket.dart';

/// 解析单条穿搭——以 (温度档, 风格, 性别) 为键。
///
/// 解析顺序：[base] ← style 覆盖 ← gender 覆盖。
/// gender 后置，让性别相关的单品（如女款"半身裙"）压过通用风格的下装；
/// 同时也意味着 gender 表只列出值得替换的字段，其余字段空着即可。
OutfitPieces outfitPiecesFor({
  required TemperatureBracket bracket,
  required ClothingStyle style,
  required GenderPreference gender,
}) {
  var p = _baseByBracket[bracket]!;
  final styleOverlay = _styleOverlays[style]?[bracket];
  if (styleOverlay != null) p = _apply(p, styleOverlay);
  final genderOverlay = _genderOverlays[gender]?[bracket];
  if (genderOverlay != null) p = _apply(p, genderOverlay);
  return p;
}

/// 把体感温度按怕冷怕热敏感度做偏移：
/// - 0   = 怕冷 → 当成 -4°C 更冷 → 推荐更暖的档位
/// - 0.5 = 中性 → 不调整
/// - 1   = 怕热 → 当成 +4°C 更热 → 推荐更轻的档位
///
/// 默认值 0.4 → -0.8°C，仅在档位边界附近会触发跳档。
double adjustFeelsBySensitivity(double feelsC, double sensitivity) {
  // sensitivity 已被 UserPreferences 钳到 [0, 1]。
  return feelsC + (sensitivity - 0.5) * 8;
}

// 局部 record——只允许局部覆盖某几件，未指定字段保留 base。
typedef _Overlay = ({
  String? top,
  String? bottom,
  String? jacket,
  String? shoes,
});

OutfitPieces _apply(OutfitPieces base, _Overlay o) => OutfitPieces(
  top: o.top ?? base.top,
  bottom: o.bottom ?? base.bottom,
  jacket: o.jacket ?? base.jacket,
  shoes: o.shoes ?? base.shoes,
);

/// 通用基线（≈"casual + universal"）——其他维度从这里 diff。
const Map<TemperatureBracket, OutfitPieces> _baseByBracket = {
  TemperatureBracket.severeCold: OutfitPieces(
    top: '保暖打底衫',
    bottom: '加绒长裤',
    jacket: '羽绒服',
    shoes: '保暖短靴',
  ),
  TemperatureBracket.cold: OutfitPieces(
    top: '保暖打底衫',
    bottom: '加绒长裤',
    jacket: '加厚外套',
    shoes: '保暖短靴',
  ),
  TemperatureBracket.cool: OutfitPieces(
    top: '羊毛针织衫',
    bottom: '厚款长裤',
    jacket: '夹克 / 风衣',
    shoes: '运动鞋',
  ),
  TemperatureBracket.mild: OutfitPieces(
    top: '长袖衬衫',
    bottom: '休闲长裤',
    jacket: '薄风衣',
    shoes: '运动鞋',
  ),
  TemperatureBracket.warm: OutfitPieces(
    top: '薄长袖 / T恤',
    bottom: '九分裤',
    jacket: '无需外套',
    shoes: '帆布鞋',
  ),
  TemperatureBracket.hot: OutfitPieces(
    top: '冰丝短袖',
    bottom: '透气短裤',
    jacket: '无需外套',
    shoes: '帆布鞋',
  ),
};

/// 风格覆盖——business/sporty/street/vintage 整套替换；casual = base。
const Map<ClothingStyle, Map<TemperatureBracket, _Overlay>> _styleOverlays = {
  ClothingStyle.business: {
    TemperatureBracket.severeCold: (
      top: '高领打底衫',
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
      jacket: '无需外套',
      shoes: '商务皮鞋',
    ),
    TemperatureBracket.hot: (
      top: '短袖衬衫',
      bottom: '亚麻西裤',
      jacket: '无需外套',
      shoes: '乐福鞋',
    ),
  },
  ClothingStyle.sporty: {
    TemperatureBracket.severeCold: (
      top: '加厚卫衣',
      bottom: '加绒运动裤',
      jacket: '户外冲锋衣',
      shoes: '防水跑鞋',
    ),
    TemperatureBracket.cold: (
      top: '抓绒卫衣',
      bottom: '加绒运动裤',
      jacket: '冲锋衣',
      shoes: '跑鞋',
    ),
    TemperatureBracket.cool: (
      top: '运动长袖',
      bottom: '运动长裤',
      jacket: '运动外套',
      shoes: '跑鞋',
    ),
    TemperatureBracket.mild: (
      top: '速干 T 恤',
      bottom: '运动长裤',
      jacket: '运动外套',
      shoes: '跑鞋',
    ),
    TemperatureBracket.warm: (
      top: '速干 T 恤',
      bottom: '运动短裤',
      jacket: '无需外套',
      shoes: '跑鞋',
    ),
    TemperatureBracket.hot: (
      top: '速干背心',
      bottom: '运动短裤',
      jacket: '无需外套',
      shoes: '跑鞋',
    ),
  },
  ClothingStyle.street: {
    TemperatureBracket.severeCold: (
      top: '印花卫衣',
      bottom: '加绒工装裤',
      jacket: '机能棉服',
      shoes: '高帮板鞋',
    ),
    TemperatureBracket.cold: (
      top: '印花卫衣',
      bottom: '工装裤',
      jacket: '棒球外套',
      shoes: '高帮板鞋',
    ),
    TemperatureBracket.cool: (
      top: '印花卫衣',
      bottom: '工装裤',
      jacket: '牛仔外套',
      shoes: '板鞋',
    ),
    TemperatureBracket.mild: (
      top: '印花 Tee',
      bottom: '工装裤',
      jacket: '棒球外套',
      shoes: '板鞋',
    ),
    TemperatureBracket.warm: (
      top: '印花 Tee',
      bottom: '工装短裤',
      jacket: '无需外套',
      shoes: '板鞋',
    ),
    TemperatureBracket.hot: (
      top: '宽松背心 / Tee',
      bottom: '工装短裤',
      jacket: '无需外套',
      shoes: '板鞋',
    ),
  },
  ClothingStyle.vintage: {
    TemperatureBracket.severeCold: (
      top: '高领针织衫',
      bottom: '羊毛阔腿裤',
      jacket: '复古长大衣',
      shoes: '切尔西靴',
    ),
    TemperatureBracket.cold: (
      top: '复古衬衫',
      bottom: '高腰阔腿裤',
      jacket: '羊毛大衣',
      shoes: '切尔西靴',
    ),
    TemperatureBracket.cool: (
      top: '复古衬衫',
      bottom: '高腰阔腿裤',
      jacket: '复古风衣',
      shoes: '牛津鞋',
    ),
    TemperatureBracket.mild: (
      top: '复古衬衫',
      bottom: '高腰阔腿裤',
      jacket: '薄风衣',
      shoes: '乐福鞋',
    ),
    TemperatureBracket.warm: (
      top: '复古 POLO 衫',
      bottom: '阔腿短裤',
      jacket: '无需外套',
      shoes: '乐福鞋',
    ),
    TemperatureBracket.hot: (
      top: '复古印花衫',
      bottom: '阔腿短裤',
      jacket: '无需外套',
      shoes: '凉鞋',
    ),
  },
};

/// 性别覆盖——只在视觉上能区分性别的档位替换 1–2 件，避免不必要的"男士XX"前缀污染。
const Map<GenderPreference, Map<TemperatureBracket, _Overlay>> _genderOverlays =
    {
      GenderPreference.male: {
        TemperatureBracket.mild: (
          top: 'POLO 衫',
          bottom: null,
          jacket: null,
          shoes: null,
        ),
        TemperatureBracket.warm: (
          top: '短袖 T 恤',
          bottom: null,
          jacket: null,
          shoes: null,
        ),
      },
      GenderPreference.female: {
        TemperatureBracket.cool: (
          top: '针织开衫',
          bottom: null,
          jacket: null,
          shoes: null,
        ),
        TemperatureBracket.mild: (
          top: '针织开衫',
          bottom: '长裙 / 阔腿裤',
          jacket: null,
          shoes: null,
        ),
        TemperatureBracket.warm: (
          top: '雪纺短袖',
          bottom: '半身裙 / 九分裤',
          jacket: null,
          shoes: null,
        ),
        TemperatureBracket.hot: (
          top: '吊带 / 雪纺衫',
          bottom: '短裙',
          jacket: null,
          shoes: null,
        ),
      },
    };
