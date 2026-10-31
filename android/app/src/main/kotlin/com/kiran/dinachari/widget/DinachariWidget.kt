package com.kiran.dinachari.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.item
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.background
import androidx.glance.LocalSize
import androidx.glance.currentState
import androidx.glance.layout.ContentScale
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
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

/** Colors from the approved mockup: white card, orange accent, navy ink. */
private object WidgetColors {
    val card = Color(0xFFFFFFFF)
    val ink = Color(0xFF151821)
    val muted = Color(0xFF4B5263)
    val line = Color(0xFFD5D9E2)
}

/** Keys shared with lib/services/widget_sync.dart. */
internal object WidgetKeys {
    const val DATA = "today_json"
    const val PENDING = "pending_json"
}

/** One habit as the widget sees it, already moved to today. */
internal data class WidgetHabit(
    val id: Int,
    val name: String,
    val icon: String,
    val color: Int,
    val isCount: Boolean,
    val target: Int,
    val unit: String,
    val value: Int,
    val streakBefore: Int,
) {
    val done get() = value >= target
    val streak get() = if (done) streakBefore + 1 else streakBefore

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("name", name)
        .put("icon", icon)
        .put("color", color)
        .put("kind", if (isCount) "count" else "check")
        .put("target", target)
        .put("unit", unit)
        .put("value", value)
        .put("streakBefore", streakBefore)
}

internal object WidgetData {
    private fun dayFormat() = SimpleDateFormat("yyyy-MM-dd", Locale.US)

    fun today(): String = dayFormat().format(Date())

    private fun daysBetween(from: String, to: String): Long = try {
        val f = dayFormat()
        val a = f.parse(from)!!.time
        val b = f.parse(to)!!.time
        TimeUnit.MILLISECONDS.toDays(b - a + TimeUnit.HOURS.toMillis(12))
    } catch (e: Exception) {
        Long.MAX_VALUE
    }

    /**
     * Reads the habits the app saved and moves them to [today]: if the data is
     * from an earlier day, nothing is done yet today and streaks carry over.
     */
    fun load(json: String?, today: String = today()): List<WidgetHabit> {
        if (json.isNullOrBlank()) return emptyList()
        return try {
            val root = JSONObject(json)
            val diff = daysBetween(root.optString("day"), today)
            val array = root.optJSONArray("habits") ?: JSONArray()
            (0 until array.length()).map { i ->
                val h = array.getJSONObject(i)
                val target = h.optInt("target", 1).coerceAtLeast(1)
                // Older app versions wrote "done" and "streak" instead.
                var value = h.optInt("value", if (h.optBoolean("done")) target else 0)
                var streakBefore = h.optInt("streakBefore", h.optInt("streak"))
                if (diff != 0L) {
                    streakBefore = if (diff == 1L && value >= target) streakBefore + 1 else 0
                    value = 0
                }
                WidgetHabit(
                    id = h.getInt("id"),
                    name = h.optString("name"),
                    icon = h.optString("icon"),
                    color = h.optInt("color", 0xFFF97316.toInt()),
                    isCount = h.optString("kind") == "count",
                    target = target,
                    unit = h.optString("unit"),
                    value = value,
                    streakBefore = streakBefore,
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** Keys of the pictures (week graph, heatmap, plant) shown under the habits. */
    fun imageKeys(json: String?): List<String> = try {
        val array = JSONObject(json ?: "{}").optJSONArray("images") ?: JSONArray()
        (0 until array.length()).map { array.getString(it) }
    } catch (e: Exception) {
        emptyList()
    }

    fun save(
        habits: List<WidgetHabit>,
        today: String = today(),
        images: List<String> = emptyList(),
    ): String =
        JSONObject()
            .put("day", today)
            .put("images", JSONArray().apply { images.forEach { put(it) } })
            .put("habits", JSONArray().apply { habits.forEach { put(it.toJson()) } })
            .toString()

    /** The value a tap moves a habit to: tick/untick, or +1 wrapping to 0. */
    fun nextValue(h: WidgetHabit): Int = when {
        !h.isCount -> if (h.done) 0 else h.target
        h.value >= h.target -> 0
        else -> h.value + 1
    }
}

private fun tint(color: Int, amount: Float = 0.12f): Color {
    val c = Color(color)
    return Color(
        red = 1f - (1f - c.red) * amount,
        green = 1f - (1f - c.green) * amount,
        blue = 1f - (1f - c.blue) * amount,
    )
}

private fun deep(color: Int): Color {
    val c = Color(color)
    return Color(red = c.red * 0.7f, green = c.green * 0.7f, blue = c.blue * 0.7f)
}

class DinachariWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    /** Exact size, so the pictures can be scaled to the widget's width. */
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            val json = prefs.getString(WidgetKeys.DATA, null)
            val habits = WidgetData.load(json)
            val icons = habits.associate { h ->
                h.icon to prefs.getString(h.icon, null)?.let { BitmapFactory.decodeFile(it) }
            }
            // Pictures from an earlier day would be stale, so only show today's.
            val fresh = try {
                JSONObject(json ?: "{}").optString("day") == WidgetData.today()
            } catch (e: Exception) {
                false
            }
            val images = if (!fresh) emptyList() else WidgetData.imageKeys(json).mapNotNull { key ->
                prefs.getString(key, null)?.let { BitmapFactory.decodeFile(it) }
            }
            Content(context, habits, icons, images)
        }
    }

    @Composable
    private fun Content(
        context: Context,
        habits: List<WidgetHabit>,
        icons: Map<String, Bitmap?>,
        images: List<Bitmap>,
    ) {
        val width = LocalSize.current.width - 28.dp
        Column(
            modifier = GlanceModifier
                .fillMaxSize()
                .background(WidgetColors.card)
                .cornerRadius(24.dp)
                .padding(14.dp),
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .padding(start = 2.dp, end = 2.dp, bottom = 10.dp)
                    .clickable(actionStartActivity<MainActivity>(context)),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = "Today",
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.ink),
                        fontSize = 17.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                    modifier = GlanceModifier.defaultWeight(),
                )
                Text(
                    text = "${habits.count { it.done }} of ${habits.size} done",
                    style = TextStyle(color = ColorProvider(WidgetColors.muted), fontSize = 13.sp),
                )
            }

            // Everything below the title scrolls: habits, then the week graph,
            // the heatmap and the plant.
            LazyColumn(modifier = GlanceModifier.fillMaxSize()) {
                if (habits.isEmpty()) {
                    item {
                        Box(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .padding(vertical = 16.dp)
                                .clickable(actionStartActivity<MainActivity>(context)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text(
                                text = "Nothing due today. Open Dinachari to add habits.",
                                style = TextStyle(color = ColorProvider(WidgetColors.muted), fontSize = 13.sp),
                            )
                        }
                    }
                }
                items(habits.chunked(2)) { pair ->
                    Column(modifier = GlanceModifier.fillMaxWidth().padding(bottom = 8.dp)) {
                        Row(modifier = GlanceModifier.fillMaxWidth()) {
                            Pill(pair[0], icons[pair[0].icon], GlanceModifier.defaultWeight())
                            Spacer(GlanceModifier.width(8.dp))
                            if (pair.size > 1) {
                                Pill(pair[1], icons[pair[1].icon], GlanceModifier.defaultWeight())
                            } else {
                                Spacer(GlanceModifier.defaultWeight())
                            }
                        }
                    }
                }
                items(images) { bitmap ->
                    Image(
                        provider = ImageProvider(bitmap),
                        contentDescription = null,
                        contentScale = ContentScale.Fit,
                        modifier = GlanceModifier
                            .fillMaxWidth()
                            .height(width * bitmap.height.toFloat() / bitmap.width.toFloat())
                            .padding(top = 4.dp)
                            .clickable(actionStartActivity<MainActivity>(context)),
                    )
                }
            }
        }
    }

    /** A habit button like the mockup's "Today" widget: border, tint when done. */
    @Composable
    private fun Pill(habit: WidgetHabit, icon: Bitmap?, modifier: GlanceModifier) {
        Box(
            modifier = modifier
                .height(46.dp)
                .background(if (habit.done) Color(habit.color) else WidgetColors.line)
                .cornerRadius(14.dp)
                .padding(1.5.dp)
                .clickable(
                    actionRunCallback<ToggleHabitAction>(
                        actionParametersOf(ToggleHabitAction.habitIdKey to habit.id)
                    )
                ),
        ) {
            Row(
                modifier = GlanceModifier
                    .fillMaxSize()
                    .background(if (habit.done) tint(habit.color) else WidgetColors.card)
                    .cornerRadius(13.dp)
                    .padding(horizontal = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (icon != null) {
                    Image(
                        provider = ImageProvider(icon),
                        contentDescription = null,
                        modifier = GlanceModifier.size(18.dp),
                    )
                    Spacer(GlanceModifier.width(8.dp))
                }
                Text(
                    text = habit.name,
                    maxLines = 1,
                    style = TextStyle(
                        color = ColorProvider(WidgetColors.ink),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium,
                    ),
                    modifier = GlanceModifier.defaultWeight(),
                )
                Text(
                    text = when {
                        habit.isCount -> "${habit.value}/${habit.target}"
                        habit.done -> "✓"
                        else -> ""
                    },
                    style = TextStyle(
                        color = ColorProvider(deep(habit.color)),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
            }
        }
    }
}

/**
 * Tapping a habit updates the widget right away, without starting Flutter:
 * it rewrites today's data and queues the change. The app applies the queue
 * to its database the next time it opens (WidgetSync.applyPending).
 */
class ToggleHabitAction : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val id = parameters[habitIdKey] ?: return
        val prefs = HomeWidgetPlugin.getData(context)
        val today = WidgetData.today()
        val habits = WidgetData.load(prefs.getString(WidgetKeys.DATA, null), today)
        val habit = habits.firstOrNull { it.id == id } ?: return
        val value = WidgetData.nextValue(habit)
        val updated = habits.map { if (it.id == id) it.copy(value = value) else it }

        val pending = try {
            JSONArray(prefs.getString(WidgetKeys.PENDING, null) ?: "[]")
        } catch (e: Exception) {
            JSONArray()
        }
        pending.put(JSONObject().put("id", id).put("day", today).put("value", value))

        prefs.edit()
            .putString(
                WidgetKeys.DATA,
                WidgetData.save(updated, today, WidgetData.imageKeys(prefs.getString(WidgetKeys.DATA, null))),
            )
            .putString(WidgetKeys.PENDING, pending.toString())
            .commit()

        refreshAll(context)
    }

    companion object {
        val habitIdKey = ActionParameters.Key<Int>("habitId")

        suspend fun refreshAll(context: Context) {
            val widget = DinachariWidget()
            GlanceAppWidgetManager(context)
                .getGlanceIds(DinachariWidget::class.java)
                .forEach { glanceId ->
                    updateAppWidgetState(context, HomeWidgetGlanceStateDefinition(), glanceId) { it }
                    widget.update(context, glanceId)
                }
        }
    }
}
