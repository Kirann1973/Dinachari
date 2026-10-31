package com.kiran.dinachari.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/** Registered in AndroidManifest.xml; WidgetSync.androidWidget names this class. */
class DinachariWidgetReceiver : HomeWidgetGlanceWidgetReceiver<DinachariWidget>() {
    override val glanceAppWidget = DinachariWidget()
}
