package com.recall.recall.gate

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.Settings
import android.telecom.TelecomManager
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The app lock's shared state: the user's settings, today's due count and the
 * decision logic, one copy per process. The accessibility service, the gate
 * screen and the settings screen all run in this process and all go through
 * here.
 *
 * The settings are stored as the JSON the Flutter side writes. The native side
 * reads only what it needs to decide (enabled, the apps, the free window);
 * everything else in it is the Flutter side's.
 */
object AppGate {
    private const val PREFS = "app_gate"
    private const val KEY_CONFIG = "config"
    private const val KEY_DUE_COUNT = "due_count"
    private const val KEY_DUE_DAY = "due_day"

    private var loaded = false
    private var configJson: String = "{}"
    private val state = GateState()
    lateinit var decider: GateDecider
        private set

    @Synchronized
    fun ensureLoaded(context: Context) {
        if (loaded) return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        configJson = prefs.getString(KEY_CONFIG, "{}") ?: "{}"
        state.dueCount = prefs.getInt(KEY_DUE_COUNT, -1)
        state.dueDay = prefs.getString(KEY_DUE_DAY, null)
        decider = GateDecider(parse(configJson, context), state)
        loaded = true
    }

    fun configJson(context: Context): String {
        ensureLoaded(context)
        return configJson
    }

    @Synchronized
    fun saveConfig(context: Context, json: String) {
        ensureLoaded(context)
        configJson = json
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY_CONFIG, json).apply()
        decider = GateDecider(parse(json, context), state)
    }

    @Synchronized
    fun setDue(context: Context, count: Int, day: String) {
        ensureLoaded(context)
        state.dueCount = count
        state.dueDay = day
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putInt(KEY_DUE_COUNT, count).putString(KEY_DUE_DAY, day).apply()
    }

    /** The local calendar day, in the same form the Flutter side writes. */
    fun today(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

    private fun parse(json: String, context: Context): GateConfig {
        return try {
            val o = JSONObject(json)
            val array = o.optJSONArray("packages") ?: JSONArray()
            val excluded = excludedPackages(context)
            val packages = (0 until array.length())
                .map { array.getString(it) }
                .filter { it !in excluded }
                .toSet()
            GateConfig(
                enabled = o.optBoolean("enabled", false),
                packages = packages,
                graceEnabled = o.optBoolean("graceEnabled", false),
                graceMinutes = o.optInt("graceMinutes", 5).coerceIn(1, 120),
            )
        } catch (e: Exception) {
            GateConfig()
        }
    }

    /**
     * Apps that are never gated, whatever the settings say: this app, the phone's
     * settings (a locked settings app could stop the user turning this off), the
     * dialer (calls, including emergency calls), and the home screen.
     */
    fun excludedPackages(context: Context): Set<String> {
        val pm = context.packageManager
        val out = mutableSetOf(context.packageName, "com.android.settings")
        pm.resolveActivity(Intent(Settings.ACTION_SETTINGS), 0)
            ?.activityInfo?.packageName?.let { out += it }
        try {
            val telecom = context.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            telecom.defaultDialerPackage?.let { out += it }
        } catch (_: Exception) {
        }
        out += homePackages(context)
        return out
    }

    fun homePackages(context: Context): Set<String> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return context.packageManager
            .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
            .map { it.activityInfo.packageName }
            .toSet()
    }

    fun isAccessibilityEnabled(context: Context): Boolean {
        val expected = ComponentName(context, AppGateService::class.java).flattenToString()
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
        ) ?: return false
        return enabled.split(':').any { it.equals(expected, ignoreCase = true) }
    }
}
