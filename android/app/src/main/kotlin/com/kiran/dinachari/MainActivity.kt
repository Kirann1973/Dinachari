package com.kiran.dinachari

import android.app.Activity
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter app, plus the "dinachari/sounds" channel used by the
 * habit editor: pick any notification sound on the phone, and play previews.
 */
class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null
    private var playing: Ringtone? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dinachari/sounds")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> pick(call.argument<String>("current"), result)
                    "play" -> {
                        play(call.argument<String>("sound") ?: "default")
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Turns a stored sound value into a playable Uri. */
    private fun uriFor(sound: String): Uri? = when {
        sound.startsWith("raw:") ->
            Uri.parse("android.resource://$packageName/raw/${sound.removePrefix("raw:")}")
        sound.startsWith("uri:") ->
            Uri.parse(sound.removePrefix("uri:").substringBeforeLast('|'))
        sound == "default" ->
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        else -> null
    }

    private fun pick(current: String?, result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_NOTIFICATION)
            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Reminder sound")
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, false)
            if (current != null && current.startsWith("uri:")) {
                putExtra(RingtoneManager.EXTRA_RINGTONE_EXISTING_URI, uriFor(current))
            }
        }
        try {
            startActivityForResult(intent, PICK_SOUND)
        } catch (e: Exception) {
            pendingPick = null
            result.error("unavailable", "No sound picker on this phone", null)
        }
    }

    @Deprecated("Uses the classic activity result API, fine for a single picker.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_SOUND) return
        val result = pendingPick ?: return
        pendingPick = null
        @Suppress("DEPRECATION")
        val uri: Uri? = if (resultCode == Activity.RESULT_OK) {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        } else {
            null
        }
        if (uri == null) {
            result.success(null)
            return
        }
        val title = try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this)
        } catch (e: Exception) {
            null
        } ?: "Phone sound"
        result.success(mapOf("uri" to uri.toString(), "title" to title))
    }

    private fun play(sound: String) {
        playing?.stop()
        val uri = uriFor(sound) ?: return
        playing = try {
            RingtoneManager.getRingtone(this, uri)?.apply {
                audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                play()
            }
        } catch (e: Exception) {
            null
        }
    }

    override fun onDestroy() {
        playing?.stop()
        super.onDestroy()
    }

    companion object {
        private const val PICK_SOUND = 4107
    }
}
