// 天气 + 穿搭桌面小组件 —— iOS WidgetKit 实现。
//
// 此文件随仓库提供，但需要在 Xcode 里手动加成一个 Widget Extension target
// 才会真正参与编译，CLI 无法替你做这一步。一次性配置如下：
//
//   1. Xcode 打开 ios/Runner.xcworkspace
//   2. File → New → Target → Widget Extension，命名 "WeatherWidget"，
//      取消勾选 "Include Live Activity"，Bundle ID 一般用
//      com.softandapp.weather_app.WeatherWidget
//   3. 把 Xcode 自动生成的同名 swift 文件删掉，把这个 WeatherWidget.swift
//      和 Info.plist 加入到刚创建的 target（Target Membership 勾上）
//   4. Runner target 与 WeatherWidget target 都开启 App Groups 能力，
//      共用一个 group：group.com.softandapp.weather_app
//   5. 在 Flutter 入口（main.dart）里调用：
//          HomeWidget.setAppGroupId('group.com.softandapp.weather_app');
//      让 home_widget 把数据写到这个 App Group 里
//
// 数据由 Flutter 侧通过 home_widget 写入 App Group 的 UserDefaults，
// 字段名详见 lib/core/widget/home_widget_sync.dart。

import SwiftUI
import WidgetKit

private let kAppGroupId = "group.com.softandapp.weather_app"

struct WeatherEntry: TimelineEntry {
    let date: Date
    let location: String
    let tempNow: String
    let condition: String
    let tempHigh: String
    let tempLow: String
    let feelsLike: String
    let outfitTop: String
    let outfitBottom: String
    let outfitJacket: String
    let outfitShoes: String
    let tip: String
    let accessory: String
    let updatedAt: String
}

private extension WeatherEntry {
    static func load(_ date: Date = Date()) -> WeatherEntry {
        let defaults = UserDefaults(suiteName: kAppGroupId)
        func read(_ key: String, _ fallback: String = "--") -> String {
            defaults?.string(forKey: key) ?? fallback
        }
        return WeatherEntry(
            date: date,
            location: read("widget.location", "当前位置"),
            tempNow: read("widget.tempNow"),
            condition: read("widget.condition"),
            tempHigh: read("widget.tempHigh"),
            tempLow: read("widget.tempLow"),
            feelsLike: read("widget.feelsLike"),
            outfitTop: read("widget.outfitTop"),
            outfitBottom: read("widget.outfitBottom"),
            outfitJacket: read("widget.outfitJacket"),
            outfitShoes: read("widget.outfitShoes"),
            tip: read("widget.tip", "打开应用同步数据"),
            accessory: read("widget.accessory", ""),
            updatedAt: read("widget.updatedAt", "--:--")
        )
    }
}

struct WeatherProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherEntry { .load() }

    func getSnapshot(in context: Context, completion: @escaping (WeatherEntry) -> Void) {
        completion(.load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherEntry>) -> Void) {
        // 系统会在我们调用 WidgetCenter.shared.reloadAllTimelines() 时立即拉新；
        // 这里设置一个保底 30min 节奏即可。
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [.load()], policy: .after(next)))
    }
}

struct WeatherWidgetEntryView: View {
    var entry: WeatherEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.location).font(.caption).bold()
                Spacer()
                Text(entry.updatedAt).font(.caption2).opacity(0.8)
            }
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(entry.tempNow).font(.system(size: 34, weight: .bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.condition).font(.caption)
                    Text("\(entry.tempHigh) / \(entry.tempLow) · 体感 \(entry.feelsLike)")
                        .font(.caption2).opacity(0.85)
                }
            }
            Divider().background(Color.white.opacity(0.3))
            Text("今日穿搭").font(.caption).bold()
            Group {
                Text("上衣 · \(entry.outfitTop)")
                Text("下装 · \(entry.outfitBottom)")
                Text("外套 · \(entry.outfitJacket)")
                Text("鞋履 · \(entry.outfitShoes)")
            }
            .font(.caption)
            .lineLimit(1)
            Text(joinedTip(entry))
                .font(.caption2)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
        }
        .padding(16)
        .foregroundColor(.white)
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.23, green: 0.51, blue: 0.96),
                                            Color(red: 0.38, green: 0.65, blue: 0.98)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private func joinedTip(_ e: WeatherEntry) -> String {
        let tip = e.tip.trimmingCharacters(in: .whitespaces)
        let acc = e.accessory.trimmingCharacters(in: .whitespaces)
        if !tip.isEmpty && !acc.isEmpty { return "\(tip) · \(acc)" }
        if !tip.isEmpty { return tip }
        if !acc.isEmpty { return acc }
        return "打开应用同步数据"
    }
}

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("今日天气穿搭")
        .description("一眼看见今天的天气和穿搭建议。")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
