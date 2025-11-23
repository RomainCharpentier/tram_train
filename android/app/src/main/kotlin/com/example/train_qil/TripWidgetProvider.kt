package com.example.train_qil

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class TripWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("title", "Prochain départ")
                val description = widgetData.getString("description", "Aucun trajet")
                val time = widgetData.getString("time", "--:--")
                val status = widgetData.getString("status", "")

                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_trip_description, description)
                setTextViewText(R.id.widget_time, time)
                setTextViewText(R.id.widget_status, status)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
