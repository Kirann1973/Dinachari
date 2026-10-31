package com.kiran.dinachari.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.kiran.dinachari.MainActivity
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Colors from the approved mockups: white cards on dark, orange accent. */
private object WidgetColors {
    val background = Color(0xFF121212)
    val card = Color(0xFFFFFFFF)
    val accent = Color(0xFFFF7A1A)
    val text = Color(0xFF1A1A1A)
    val muted = Color(0xFF8A8A8A)
    val unchecked = Color(0xFFE6E6E6)
}

/** One habit as written by the Flutter app (see lib/services/widget_sync.dart). */
private data class WidgetHabit(
    val id: Int,
    val name: String,
    val emoji: String,
    val done: Boolean,
    val streak: Int,
)

private data class TodaySummary(val done: Int, val total: Int, val habits: List<WidgetHabit>)

private fun parseSummary(json: String?): TodaySummary {
    if (json.isNullOrBlank()) return TodaySummary(0, 0, emptyList())
    return try {
        val root = JSONObject(json)
        // Data written on an earlier day: nothing is ticked yet today.
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val isToday = root.optString("day") == today
        val array = root.optJSONArray("habits")
        val habits = buildList {
            if (array != null) {
                for (i in 0 until array.length()) {
                    val h = array.getJSONObject(i)
                    add(
                        WidgetHabit(
                            id = h.getInt("id"),
                            name = h.optString("name"),
                            emoji = h.optString("emoji", "✅"),
                            done = isToday && h.optBoolean("done"),
                            streak = h.optInt("streak"),
                        )
                    )
                }
            }
        }
        TodaySummary(habits.count { it.done }, habits.size, habits)
    } catch (e: Exception) {
        TodaySummary(0, 0, emptyList())
    }
}

class DinachariWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            Content(context, parseSummary(prefs.getString(DATA_KEY, null)))
        }
    }

    @Composable
    private fun Content(context: Context, summary: TodaySummary) {
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(WidgetColors.background)
                .cornerRadius(20.dp)
                .padding(12.dp),
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(start = 4.dp, end = 4.dp, bottom = 8.dp)
                    .clickable(actionStartActivity<MainActivity>(context)),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Today",
                    style = TextStyle(
                        color = ColorProvider(Color.White),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    modifier = GlanceModifier.defaultWeight(),
                )
                Text(
                    text = "${summary.done}/${summary.total}",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.accent),
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
            }

            if (summary.habits.isEmpty()) {
                Box(
                    modifier = GlanceModifier
                        .fillMaxSize()
                        .clickable(actionStartActivity<MainActivity>(context)),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        text = "Open Dinachari to add habits",
                        style = TextStyle(color = ColorProvider(Color(0xB3FFFFFF)), fontSize = 13.sp),
                    )
                }
            } else {
                LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                    items(summary.habits, itemId = { it.id.toLong() }) { habit ->
                        Column {
                            HabitRow(habit)
                            Spacer(GlanceModifier.height(6.dp))
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun HabitRow(habit: WidgetHabit) {
        Row(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(WidgetColors.card)
                .cornerRadius(14.dp)
                .padding(horizontal = 12.dp, vertical = 10.dp)
                .clickable(
                    actionRunCallback<ToggleHabitAction>(
                        actionParametersOf(ToggleHabitAction.habitIdKey to habit.id)
                    )
                ),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(text = habit.emoji, style = TextStyle(fontSize = 18.sp))
            Spacer(GlanceModifier.width(10.dp))
            Column(modifier = GlanceModifier.defaultWeight()) {
                Text(
                    text = habit.name,
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.text),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium,
                    ),
                )
                if (habit.streak > 0) {
                    Text(
                        text = "🔥 ${habit.streak}",
                        style = TextStyle(color = ColorProvider(WidgetColors.muted), fontSize = 11.sp),
                    )
                }
            }
            Box(
                modifier = GlanceModifier
                    .size(26.dp)
                    .background(if (habit.done) WidgetColors.accent else WidgetColors.unchecked)
                    .cornerRadius(13.dp),
                contentAlignment = Alignment.Center,
            ) {
                if (habit.done) {
                    Text(
                        text = "✓",
                        style = TextStyle(
                            color = ColorProvider(Color.White),
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold,
                        ),
                    )
                }
            }
        }
    }

    companion object {
        /** Must match WidgetSync.dataKey in Dart. */
        const val DATA_KEY = "today_json"
    }
}

/**
 * Tapping a habit hands the toggle to Dart (lib/services/widget_actions.dart),
 * which updates the database and pushes fresh data back to the widget.
 */
class ToggleHabitAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val id = parameters[habitIdKey] ?: return
        HomeWidgetBackgroundIntent
            .getBroadcast(context, Uri.parse("dinachari://toggle?id=$id"))
            .send()
    }

    companion object {
        val habitIdKey = ActionParameters.Key<Int>("habitId")
    }
}
