package com.recall.recall.gate

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * `recall/app_gate`: what the Flutter side may ask of the app lock.
 *
 * Registered on the main app's engine (settings) and on the gate screen's own
 * engine (target, unlock, home).
 */
object AppGateChannel {
    private const val NAME = "recall/app_gate"
    private val background = Executors.newSingleThreadExecutor()
    private val channels = mutableMapOf<Activity, MethodChannel>()

    fun register(engine: FlutterEngine, activity: Activity, gate: GateActivity? = null) {
        val channel = MethodChannel(engine.dartExecutor.binaryMessenger, NAME)
        channels[activity] = channel
        channel.setMethodCallHandler { call, result ->
            val context = activity.applicationContext
            when (call.method) {
                "getConfig" -> result.success(AppGate.configJson(context))
                "saveConfig" -> {
                    AppGate.saveConfig(context, call.arguments as String)
                    result.success(null)
                }
                "setDueState" -> {
                    val count = call.argument<Int>("count") ?: -1
                    val day = call.argument<String>("day") ?: ""
                    AppGate.setDue(context, count, day)
                    result.success(null)
                }
                "status" -> result.success(
                    mapOf(
                        "accessibility" to AppGate.isAccessibilityEnabled(context),
                        "overlay" to (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                            Settings.canDrawOverlays(context)),
                    ),
                )
                "openAccessibilitySettings" -> {
                    openAccessibilitySettings(activity)
                    result.success(null)
                }
                "openAppInfo" -> {
                    activity.startActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:${context.packageName}"),
                        ),
                    )
                    result.success(null)
                }
                "openOverlaySettings" -> {
                    activity.startActivity(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${context.packageName}"),
                        ),
                    )
                    result.success(null)
                }
                "listApps" -> background.execute {
                    // Off the main thread: loading every icon takes a moment.
                    val apps = listApps(activity)
                    activity.runOnUiThread { result.success(apps) }
                }
                "getTarget" -> {
                    val pkg = gate?.target
                    result.success(
                        if (pkg == null) null else mapOf("package" to pkg, "label" to label(activity, pkg)),
                    )
                }
                "unlockAndOpen" -> {
                    gate?.unlockAndOpen(call.arguments as String)
                    result.success(null)
                }
                "goHome" -> {
                    gate?.goHome()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Straight to this app's own switch where Android allows it.
     *
     * Android 13+ has a public screen for one service's details. Before that,
     * the accessibility list is opened with this service highlighted — an
     * argument Settings honours on most phones and ignores harmlessly on the
     * rest. If neither opens, the plain accessibility list does.
     */
    private fun openAccessibilitySettings(activity: Activity) {
        val component = ComponentName(activity, AppGateService::class.java)
        val flat = component.flattenToString()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Not in the public SDK; some phones guard it with a system
            // permission, which is why it may throw and fall through.
            val details = Intent("android.settings.ACCESSIBILITY_DETAILS_SETTINGS")
                .putExtra(Intent.EXTRA_COMPONENT_NAME, flat)
            if (tryStart(activity, details)) return
        }

        val highlighted = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            .putExtra(":settings:fragment_args_key", flat)
            .putExtra(
                ":settings:show_fragment_args",
                Bundle().apply { putString(":settings:fragment_args_key", flat) },
            )
        if (tryStart(activity, highlighted)) return

        tryStart(activity, Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
    }

    private fun tryStart(activity: Activity, intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (_: ActivityNotFoundException) {
        false
    } catch (_: SecurityException) {
        false
    }

    fun notifyTargetChanged(activity: Activity) {
        channels[activity]?.invokeMethod("targetChanged", null)
    }

    private fun label(activity: Activity, pkg: String): String = try {
        val pm = activity.packageManager
        pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        pkg
    }

    /** Apps with a launcher icon, minus the ones that are never gated. */
    private fun listApps(activity: Activity): List<Map<String, Any>> {
        val pm = activity.packageManager
        val excluded = AppGate.excludedPackages(activity)
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(intent, 0)
            .map { it.activityInfo.packageName }
            .distinct()
            .filter { it !in excluded }
            .mapNotNull { pkg ->
                try {
                    val info = pm.getApplicationInfo(pkg, 0)
                    mapOf(
                        "package" to pkg,
                        "label" to pm.getApplicationLabel(info).toString(),
                        "icon" to png(pm.getApplicationIcon(info)),
                    )
                } catch (_: Exception) {
                    null
                }
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    private fun png(drawable: Drawable): ByteArray {
        val size = 96
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        return out.toByteArray()
    }
}
