package com.recall.recall.gate

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.pm.PackageManager
import android.view.accessibility.AccessibilityEvent

/**
 * Sees which app comes to the front and, when one of the chosen apps is being
 * opened, shows the flashcards first.
 *
 * Reads only the package name of the window that changed. It reads no screen
 * content (`canRetrieveWindowContent` is false in its configuration) and sends
 * nothing anywhere.
 */
class AppGateService : AccessibilityService() {

    /** Whether a package is a real app, cached: asked on every window change. */
    private val isAppCache = mutableMapOf<String, Boolean>()
    private var homes: Set<String> = emptySet()

    override fun onServiceConnected() {
        super.onServiceConnected()
        AppGate.ensureLoaded(this)
        homes = AppGate.homePackages(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        val pkg = event.packageName?.toString() ?: return

        AppGate.ensureLoaded(this)
        val target = AppGate.decider.onWindow(
            pkg = pkg,
            isApp = isApp(pkg),
            nowMs = System.currentTimeMillis(),
            today = AppGate.today(),
        ) ?: return

        startActivity(
            Intent(this, GateActivity::class.java)
                .putExtra(GateActivity.EXTRA_TARGET, target)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                ),
        )
    }

    /**
     * A real app — something with a launcher icon, or the home screen. The
     * notification shade, keyboards and the lock screen are not, so they never
     * count as leaving the app underneath.
     */
    private fun isApp(pkg: String): Boolean {
        if (pkg in homes) return true
        return isAppCache.getOrPut(pkg) {
            try {
                packageManager.getLaunchIntentForPackage(pkg) != null
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    override fun onInterrupt() {}
}
