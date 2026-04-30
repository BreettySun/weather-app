# 场景细化推荐（时间 × 活动）设计

- **日期**：2026-04-30
- **目标**：让"穿什么"从"一天一套通用建议"升级为"按时间段 + 活动场景"的细化推荐，使用户在真实日程下都能拿到贴合的天气与穿搭。
- **形态决策**：采用 Hybrid（C 方案）——默认卡保留并默认零操作，事件机制按需添加。
- **不在范围内**：通知 / 推送、Apple Watch / WearOS 等生态扩展、个人衣橱图片上传——这些是后续独立项目。

---

## 1. 用户故事

| # | 故事 | 现状 | 目标 |
|---|------|------|------|
| US-1 | 普通工作日，早上打开 app，看一眼推荐就走 | 看到一张通用卡 | 仍然看到一张卡，但内部按"工作日 = 通勤"的兜底活动算 |
| US-2 | 知道下午要爬山，希望提前看那个时段的天气和穿搭 | 没有方式表达 | 在首页加一条"下午爬山 / 14:00"的事件，事件卡显示 14:00 的天气与登山推荐 |
| US-3 | 早晚温差大（25°C 转 12°C），想看晚上需要带什么 | tip 里只有一行文字提示 | 首页有 24 小时滚动条，可以滚到晚上看具体温度；事件机制也允许手动加一个晚上的安排 |
| US-4 | 周末懒得想，希望默认就是"休闲" | 风格固定，跟工作日一样 | 兜底活动周末自动切到 casual |

---

## 2. 数据模型

### 2.1 `Activity` 枚举（新）

> `lib/features/events/model/activity.dart`

```dart
enum Activity {
  commute('通勤'),
  exercise('健身'),
  outing('出游'),
  date('约会'),
  formal('正式'),
  casual('休闲');

  const Activity(this.label);
  final String label;
}
```

- 6 项，固定枚举（不允许自由文本，避免 catalog 维度爆炸）。
- `casual` 用作未指定时的兜底。

### 2.2 `HourlyForecast`（新）

> `lib/features/weather/model/hourly_forecast.dart`

```dart
class HourlyForecast {
  final DateTime time;
  final double temperatureC;
  final double apparentTemperatureC;
  final WeatherCondition condition;
  final int precipitationProbabilityPct;
  final double windSpeedKmh;
}
```

- 由 Open-Meteo `/v1/forecast` 的 `hourly` 段解析；同样有 `fromCacheJson` / `toCacheJson` 与 `fromJson`（网络）解耦。
- 接入到 `WeatherForecast.hourly: List<HourlyForecast>`。

### 2.3 `DayEvent`（新）

> `lib/features/events/model/day_event.dart`

```dart
class DayEvent {
  final String id;            // uuid v4
  final Activity activity;
  final DateTime startAt;     // 当天的某个整点（小时精度即可）
  final String? note;         // 可选备注，"公司团建" 之类
}
```

- 不引入持续时间——爬山 2 小时这种细节当前推荐不依赖区间，仅按起始时间取小时预报即可。
- 仅"今日"——隔天自动清空（见持久化）。

### 2.4 持久化

- key：`day_events.v1`
- payload（同一天内的多个事件）：

```json
{
  "date": "2026-04-30",
  "events": [{"id": "...", "activity": "outing", "startAt": "2026-04-30T14:00:00Z", "note": "爬山"}]
}
```

- 冷启动 / 回到前台时校对 `date != today` → 清空（用户上次开 app 是昨天的事件，今天已无意义）。
- 缓存 key 规律沿用全局——版本号后缀。`forecast_cache` 同步 bump 到 `v2`，因为模型加了 `hourly`。

---

## 3. 推荐器扩展

### 3.1 当前

```dart
recommendOutfit(CurrentWeather c, DailyForecast? today, UserPreferences prefs)
```

- 三层叠加：`base ← style ← gender`
- 输入只有"当前 + 当日聚合"

### 3.2 升级后

```dart
recommendOutfit({
  required CurrentWeather current,        // 仍然驱动 tip / accessory（基于客观信号）
  required DailyForecast? today,
  HourlyForecast? targetHour,             // 用于"事件时间"的体感与降水
  required Activity activity,
  required UserPreferences prefs,
})
```

- 体感来源选择：`targetHour?.apparentTemperatureC ?? current.apparentTemperatureC`——事件指定的小时优先；默认卡仍用 `current`。
- 叠加链改为四层：**`base ← style ← gender ← activity`**
  - `activity` 仅覆盖它强相关的项，其余沿用上一层（例：`exercise` 覆盖 `shoes='运动鞋'` + `jacket=null`，但保留 style 的上衣/下装；`formal` 覆盖全部 4 项为正装组合）。
- 雨天兜底（防水短靴）压在最外层，跨越所有覆盖。
- tip / accessory 的 cascade 仍用原始 `feels`（与 sensitivity / activity 无关），见 CLAUDE.md "Outfit recommender" 一节，避免怕冷的人在 30°C 看到冷的提示。

### 3.3 Activity overlay 数据（草案）

| Activity | 覆盖项 | 例（mild bracket 15-22°C） |
|----------|--------|--------|
| commute  | （不覆盖） | 走 style/gender 的默认 |
| exercise | top, bottom, jacket=null, shoes='运动鞋' | 速干 T 恤 / 运动短裤 / — / 运动鞋 |
| outing   | jacket='防风外套', shoes='徒步鞋' | 长袖上衣 / 速干长裤 / 防风外套 / 徒步鞋 |
| date     | jacket='风衣', shoes='乐福鞋' | 上衣保持 / 下装保持 / 风衣 / 乐福鞋 |
| formal   | 覆盖全部 4 项为正装 | 衬衫 / 西裤 或 连衣裙 / 西装外套 / 商务皮鞋 |
| casual   | （不覆盖） | 走 style/gender 的默认 |

约束：

- activity overlay 不依赖前一层（style）的内容——四层 cascade 的每一层都是独立查表。
- tip 与 accessory 仍由"客观信号"驱动（feels / pop / delta / UV），**不**因 activity 改变。"记得补水"这类文案如有需要，作为事件卡上的静态副标题独立展示，不进 tip cascade。
- 雨天兜底（`shoes='防水短靴'`）位于最外层，会**压过** exercise 的 `运动鞋`、outing 的 `徒步鞋` 等——安全 > 风格。

具体每档每活动的内容写在 `lib/features/outfit/data/activity_overlays.dart`，结构对齐 `_styleOverlays`。

---

## 4. 缓存与网络

### 4.1 网络

`open_meteo_repository.dart` 的 `fetchForecast` 在原有 `current` + `daily` 基础上增加 `hourly` 段：

```
hourly=temperature_2m,apparent_temperature,weather_code,precipitation_probability,wind_speed_10m
```

只取 `forecast_days` 范围内的小时（默认 7×24=168 条）。

### 4.2 缓存

`forecast_cache.v1` → `forecast_cache.v2`：

- v1 旧值在升级首次启动时检测到 key 不匹配，直接返回 null（按"无缓存"走网络），不做迁移——payload 结构变了，不值得写迁移逻辑。
- v2 payload 增加 `hourly` 数组。

### 4.3 forecastProvider 行为

不变——仍是 `StreamProvider`，先 yield cache（如有），再 yield 网络结果。新增的 `hourly` 字段对调用端透明。

---

## 5. UI

### 5.1 首页布局（自上而下）

```
┌────────────────────────────────┐
│ 天气 hero（蓝渐变卡）           │  保持现状
│  - 城市 · 温度 · 体感          │
│  - condition + 详情 chips      │
├────────────────────────────────┤
│ 24 小时滚动条（新）              │  ← 新增组件
│  [00 18° ☀] [01 17° ☀] ...    │
├────────────────────────────────┤
│ 默认推荐卡（保持）                │
│  - 兜底活动 chip "工作日 · 通勤" │  ← 顶部新增小 chip
│  - 4 件单品                     │
│  - tip 黄底胶囊                 │
│  - 配饰胶囊                     │
│  - 查看详情 / 生成穿搭卡片       │
├────────────────────────────────┤
│ 今日安排（新）                   │
│  + 添加专门安排  按钮            │
│  ─ 14:00 🥾 出游（爬山）─ 18°C  │
│      防风外套 / 徒步鞋 ...       │
│  ─ 19:00 🍷 约会 ─ 16°C        │
│      衬衫 / 风衣 / 乐福鞋 ...    │
└────────────────────────────────┘
```

无事件时只显示"+ 添加专门安排"入口（不显示空标题，避免 0 状态突兀）。

### 5.2 兜底活动规则

- 周一 ~ 周五 → `commute`
- 周六 / 周日 → `casual`
- chip 上显示"工作日 · 通勤"或"周末 · 休闲"，副作用：让用户知道当前是哪种兜底，从而想到"哦今天我有别的安排"。

### 5.3 24 小时滚动条

- 横向 `ListView`，每格 ~64dp 宽：小时（"14"）、天气 emoji / 图标、温度（圆整）。
- 当前小时高亮（描边 + 加粗）。
- 滚动只是浏览，**不**改变下方默认卡内容（避免 picker 心智混入主线）。
- 数据源：`forecast.hourly`，截到从当前小时开始的未来 24h。

### 5.4 添加事件（modal bottom sheet）

```
┌─────────────────────────────┐
│  添加今日安排                │
│                             │
│  时间   [ 14:00  ▼ ]        │  小时滑块或 dropdown，整点
│                             │
│  活动   [通勤][健身][出游]    │  chip 单选
│        [约会][正式][休闲]    │
│                             │
│  备注   [____________]      │  可选
│                             │
│      [ 取消 ]    [ 保存 ]   │
└─────────────────────────────┘
```

- 时间可选范围：当前小时 ~ 23:00（仅当日整点）；默认 = 下一个整点，超过 22:00 时默认 = 23:00。
- 活动默认 = casual。
- 保存 → 写入 events 列表 → 关闭 sheet → 首页事件卡区域出现新卡。

### 5.5 事件卡

- 视觉系列：与默认卡同色系但更紧凑（高度约默认卡的 1/2），保持 surfaceContainer 风格区隔。
- 折叠态：时间 + 活动 emoji + 标签 + 该时刻温度 + 一行单品摘要（"防风外套 · 徒步鞋"）。
- 展开态：完整 4 件 + tip + 配饰，与默认卡一致结构。
- 操作：点击切换折叠/展开；左滑（Dismissible）删除；长按展示菜单（编辑 / 删除）——MVP 只做"左滑删除"。
- 时间到点后不主动隐藏；当 startAt 已过去 1 小时以上，文字降到 onSurfaceVariant 表示"已过"，仍可滑掉。

---

## 6. 文件改动清单

### 新增

```
lib/features/events/
  model/
    activity.dart
    day_event.dart
  controller/
    events_provider.dart           # StateNotifier<List<DayEvent>> + 持久化
  view/
    add_event_sheet.dart
    event_card.dart
  data/
    activity_overlays.dart

lib/features/weather/model/
  hourly_forecast.dart

lib/features/weather/view/
  hourly_strip.dart                # 24h 滚动条组件
```

### 修改

```
lib/features/weather/repository/open_meteo_repository.dart   # 加 hourly 请求
lib/features/weather/repository/forecast_cache.dart          # bump v2
lib/features/weather/model/weather_forecast.dart             # +hourly 字段 + cache v2
lib/features/outfit/controller/outfit_provider.dart          # 接收 activity / targetHour
lib/features/outfit/data/outfit_catalog.dart                 # 引入 activity overlay
lib/features/weather/view/weather_home_page.dart             # 加小时条 + 事件区
```

---

## 7. 测试

### 单测

- `HourlyForecast` 网络 JSON / 缓存 JSON 双向 round-trip
- `DayEvent` JSON round-trip
- `events_provider`：跨日清空（昨天的事件冷启动后消失）
- `recommendOutfit` 增加 activity 维度的覆盖测试：
  - exercise 覆盖 shoes 与 jacket=null，保留 style 的上衣
  - formal 覆盖全部 4 项
  - 雨天 + exercise → shoes 仍是防水短靴（雨天兜底 > activity overlay）
  - targetHour 给定时，使用 hourly 体感选择 bracket（举例：当前 25°C 但事件 19:00 = 12°C → 选 cold bracket）
- `forecast_cache` v1 → v2 升级：v1 payload 在新版本读出 null（不抛、不崩）

### Widget 测试

- 首页 0 事件状态：只看到"+ 添加专门安排"入口
- 添加流程：点 + → sheet 出现 → 选 14:00 + outing → 保存 → 卡片出现并显示 14:00
- 左滑删除事件：卡片消失 + 持久化清掉
- 工作日兜底 chip 显示"工作日 · 通勤"；模拟周六 → "周末 · 休闲"
- 24 小时条渲染至少 24 个格子；当前小时高亮

---

## 8. 风险与开放问题

| 项 | 备注 |
|----|------|
| Open-Meteo 时区 | hourly 时间应按用户位置时区显示；当前 daily 用 `timezone=auto`，hourly 沿用即可，UI 显示用本地时间 |
| 事件展开/折叠状态 | 仅在内存；下次冷启动全部折叠（简单优先） |
| 事件超过当天范围 | 不允许选明天——本期只做"今日"，避免引入日期选择器 |
| 默认卡的 chip 是否可点 | MVP **不可点**——只是状态指示。点击=改活动会让用户混淆"为什么我点了变了"。要改活动应通过加事件 |
| 事件时间小时级是否够用 | 是。Open-Meteo 也只给小时粒度，且半小时级颗粒度对穿搭推荐没有意义 |
| 一天最多几个事件 | 不设硬上限；UI 自然滚动 |

---

## 9. 实施分期（供后续 implementation plan 参考）

| 阶段 | 内容 | 可独立交付 |
|------|------|----|
| P1 | hourly 字段 + 模型 + 仓库请求 + 缓存 v2 迁移 | ✅ 不影响现有 UI |
| P2 | Activity 模型 + activity_overlays 数据 + recommender 扩展（含单测） | ✅ 推荐函数被升级，UI 仍旧 |
| P3 | 24 小时滚动条（首页加上即可） | ✅ 可发版 |
| P4 | events_provider + 持久化（无 UI） | ✅ 内部 ready |
| P5 | add_event_sheet + event_card + 首页事件区接入 | ✅ 完整功能上线 |
| P6 | 默认卡兜底活动 chip + 兜底逻辑（最后做避免初期混淆） | ✅ 最终态 |

每阶段独立可合并、可发版，不会有"半成品"中间态。
