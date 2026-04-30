package com.softandapp.weather_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 天气 + 穿搭桌面小组件。
 *
 * 数据由 Flutter 侧通过 home_widget 写入到 SharedPreferences；
 * 这里只负责把已存的字符串渲染到 RemoteViews。
 */
class WeatherWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = try {
                buildViews(context, widgetData)
            } catch (t: Throwable) {
                Log.e("WeatherWidget", "render failed, falling back", t)
                fallbackViews(context)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun buildViews(context: Context, prefs: SharedPreferences): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.weather_widget)

        views.setTextViewText(
            R.id.widget_location,
            prefs.getString("widget.location", "当前位置")
        )
        views.setTextViewText(
            R.id.widget_updated_at,
            prefs.getString("widget.updatedAt", "--:--")
        )
        views.setTextViewText(
            R.id.widget_temp_now,
            prefs.getString("widget.tempNow", "--")
        )
        views.setTextViewText(
            R.id.widget_condition,
            prefs.getString("widget.condition", "--")
        )

        val high = prefs.getString("widget.tempHigh", "--")
        val low = prefs.getString("widget.tempLow", "--")
        val feels = prefs.getString("widget.feelsLike", "--")
        views.setTextViewText(
            R.id.widget_temp_range,
            "$high / $low · 体感 $feels"
        )

        views.setTextViewText(
            R.id.widget_outfit_top,
            "上衣 · " + prefs.getString("widget.outfitTop", "--")
        )
        views.setTextViewText(
            R.id.widget_outfit_bottom,
            "下装 · " + prefs.getString("widget.outfitBottom", "--")
        )
        views.setTextViewText(
            R.id.widget_outfit_jacket,
            "外套 · " + prefs.getString("widget.outfitJacket", "--")
        )
        views.setTextViewText(
            R.id.widget_outfit_shoes,
            "鞋履 · " + prefs.getString("widget.outfitShoes", "--")
        )

        val tip = prefs.getString("widget.tip", null)
        val accessory = prefs.getString("widget.accessory", null)
        views.setTextViewText(
            R.id.widget_tip,
            when {
                !tip.isNullOrBlank() && !accessory.isNullOrBlank() -> "$tip · $accessory"
                !tip.isNullOrBlank() -> tip
                !accessory.isNullOrBlank() -> accessory
                else -> "打开应用同步数据"
            }
        )

        // 点击小组件 → 打开 App
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pi)
        }
        return views
    }

    /** 任意异常都不应让小组件挂掉——退化成最小内容，至少能看到一行字。 */
    private fun fallbackViews(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.weather_widget)
        views.setTextViewText(R.id.widget_location, "穿什么")
        views.setTextViewText(R.id.widget_updated_at, "")
        views.setTextViewText(R.id.widget_temp_now, "--")
        views.setTextViewText(R.id.widget_condition, "暂无数据")
        views.setTextViewText(R.id.widget_temp_range, "")
        views.setTextViewText(R.id.widget_outfit_top, "上衣 · --")
        views.setTextViewText(R.id.widget_outfit_bottom, "下装 · --")
        views.setTextViewText(R.id.widget_outfit_jacket, "外套 · --")
        views.setTextViewText(R.id.widget_outfit_shoes, "鞋履 · --")
        views.setTextViewText(R.id.widget_tip, "打开应用同步数据")
        return views
    }
}
