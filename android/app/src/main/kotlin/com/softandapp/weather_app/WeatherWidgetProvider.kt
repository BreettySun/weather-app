package com.softandapp.weather_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * 天气 + 穿搭桌面小组件。
 *
 * 数据由 Flutter 侧通过 home_widget 写入到 SharedPreferences；
 * 这里只负责把已存的字符串渲染到 RemoteViews 并响应系统的更新回调。
 */
class WeatherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            renderWidget(context, appWidgetManager, id)
        }
    }

    private fun renderWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
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
        views.setTextViewText(
            R.id.widget_temp_range,
            "$high / $low · 体感 " + prefs.getString("widget.feelsLike", "--")
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

        // 点击小组件 → 打开 App 主界面
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
        if (launchIntent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }

        manager.updateAppWidget(widgetId, views)
    }

    companion object {
        /** Flutter 侧调用 [HomeWidget.updateWidget] 时会广播 ACTION_APPWIDGET_UPDATE，
         *  这里提供一个手动批量刷新的辅助，便于其它入口（如 BroadcastReceiver）复用。*/
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, WeatherWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val intent = Intent(context, WeatherWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }
    }
}
