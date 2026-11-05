package com.recall.recall.gate

/**
 * Decides, from the stream of "this app's window came to the front" events,
 * when one of the chosen apps is being *opened* and has to wait for flashcards.
 *
 * Pure Kotlin with no Android types, so every rule here is unit tested.
 *
 * ## What counts as opening
 *
 * Arriving at a chosen app from somewhere else: another app, the home screen,
 * the recent-apps list. Staying in it does not count, however long — a window
 * event from the same app (a dialog, the next screen) changes nothing. Windows
 * that are not apps at all (the notification shade, the keyboard, the lock
 * screen) are ignored outright, so pulling the shade down and back up is not
 * leaving the app. The caller says which packages are real apps, because only
 * Android can tell.
 *
 * ## When an opening is let through
 *
 * - the feature is off, or the app is not one of the chosen ones;
 * - there are no cards due today — nothing to ask, so nothing to wait for;
 * - the app was just unlocked by the gate, and this is that same launch
 *   arriving (a one-shot pass, so it cannot loop);
 * - the optional free window after an unlock is on and has not run out.
 */
class GateDecider(private val config: GateConfig, private val state: GateState) {

    /** Returns the package to gate, or null to let the event through. */
    fun onWindow(pkg: String, isApp: Boolean, nowMs: Long, today: String): String? {
        if (!isApp) return null
        if (pkg == state.current) return null

        state.current = pkg

        if (!config.enabled || pkg !in config.packages) return null

        // A launch the gate itself just made: consume the pass, once.
        val pass = state.passPackage
        if (pass == pkg && nowMs - state.passAtMs <= PASS_WINDOW_MS) {
            state.passPackage = null
            return null
        }

        // Nothing due today, and the count is known to be for today.
        if (state.dueDay == today && state.dueCount <= 0) return null

        if (config.graceEnabled) {
            val until = state.unlockedUntil[pkg] ?: 0L
            if (nowMs < until) return null
        }

        return pkg
    }

    /** The gate finished for [pkg]: let its launch through, and start any free window. */
    fun unlocked(pkg: String, nowMs: Long) {
        state.passPackage = pkg
        state.passAtMs = nowMs
        if (config.graceEnabled) {
            state.unlockedUntil[pkg] = nowMs + config.graceMinutes * 60_000L
        }
    }

    companion object {
        /** How long the one-shot pass waits for the unlocked app to come up. */
        const val PASS_WINDOW_MS = 10_000L
    }
}

/** What the user chose in the app-lock settings. */
data class GateConfig(
    val enabled: Boolean = false,
    val packages: Set<String> = emptySet(),
    val graceEnabled: Boolean = false,
    val graceMinutes: Int = 5,
)

/** What the service remembers between events. */
class GateState {
    /** The app last seen in front, among real apps. */
    var current: String? = null

    var passPackage: String? = null
    var passAtMs: Long = 0L

    val unlockedUntil: MutableMap<String, Long> = mutableMapOf()

    /** Today's due count for the chosen space, and the day it was counted for. */
    var dueCount: Int = -1
    var dueDay: String? = null
}
