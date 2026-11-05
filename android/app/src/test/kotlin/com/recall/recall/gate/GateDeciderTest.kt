package com.recall.recall.gate

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class GateDeciderTest {
    private val insta = "com.instagram.android"
    private val telegram = "org.telegram.messenger"
    private val launcher = "com.sec.android.app.launcher"
    private val today = "2026-11-05"

    private fun decider(
        grace: Boolean = false,
        due: Int = 5,
        state: GateState = GateState(),
    ): Pair<GateDecider, GateState> {
        state.dueCount = due
        state.dueDay = today
        return GateDecider(
            GateConfig(enabled = true, packages = setOf(insta), graceEnabled = grace, graceMinutes = 5),
            state,
        ) to state
    }

    @Test
    fun `opening a chosen app is gated`() {
        val (d, _) = decider()
        d.onWindow(launcher, isApp = true, nowMs = 0, today = today)
        assertEquals(insta, d.onWindow(insta, isApp = true, nowMs = 1, today = today))
    }

    @Test
    fun `an app that was not chosen opens freely`() {
        val (d, _) = decider()
        assertNull(d.onWindow(telegram, isApp = true, nowMs = 0, today = today))
    }

    @Test
    fun `staying in the app for hours is not opening it again`() {
        val (d, _) = decider()
        d.onWindow(insta, true, 0, today)
        d.unlocked(insta, 0)
        assertNull(d.onWindow(insta, true, 1, today)) // the unlocked launch
        // Hours of new screens and dialogs inside the app.
        for (t in 1L..1000L) assertNull(d.onWindow(insta, true, t * 60_000, today))
    }

    @Test
    fun `the notification shade, keyboard and lock screen are not leaving the app`() {
        val (d, _) = decider()
        d.onWindow(insta, true, 0, today)
        d.unlocked(insta, 0)
        d.onWindow(insta, true, 1, today)
        d.onWindow("com.android.systemui", isApp = false, nowMs = 2, today = today)
        d.onWindow("com.samsung.android.honeyboard", isApp = false, nowMs = 3, today = today)
        assertNull(d.onWindow(insta, true, 4, today))
    }

    @Test
    fun `coming back from another app is opening it again`() {
        val (d, _) = decider()
        d.onWindow(insta, true, 0, today)
        d.unlocked(insta, 0)
        d.onWindow(insta, true, 1, today)
        d.onWindow(telegram, true, 60_000, today)
        assertEquals(insta, d.onWindow(insta, true, 120_000, today))
    }

    @Test
    fun `the gate's own launch of the app passes once, so it cannot loop`() {
        val (d, _) = decider()
        assertEquals(insta, d.onWindow(insta, true, 0, today))
        d.onWindow("com.recall.recall", true, 1, today) // the gate screen
        d.unlocked(insta, 2)
        assertNull(d.onWindow(insta, true, 3, today))
        // The pass is spent: the next opening is gated again.
        d.onWindow(launcher, true, 4, today)
        assertEquals(insta, d.onWindow(insta, true, 5, today))
    }

    @Test
    fun `a stale pass does not let a later opening through`() {
        val (d, _) = decider()
        d.onWindow(insta, true, 0, today)
        d.onWindow("com.recall.recall", true, 1, today)
        d.unlocked(insta, 2)
        // The user backed out instead; much later they open it from the launcher.
        d.onWindow(launcher, true, 3, today)
        assertEquals(insta, d.onWindow(insta, true, 3 + GateDecider.PASS_WINDOW_MS + 1, today))
    }

    @Test
    fun `nothing due today means no gate at all`() {
        val (d, _) = decider(due = 0)
        assertNull(d.onWindow(insta, true, 0, today))
    }

    @Test
    fun `a due count from yesterday is not trusted`() {
        val (d, state) = decider(due = 0)
        state.dueDay = "2026-11-04"
        assertEquals(insta, d.onWindow(insta, true, 0, today))
    }

    @Test
    fun `without the free window every opening is gated`() {
        val (d, _) = decider(grace = false)
        d.onWindow(insta, true, 0, today)
        d.unlocked(insta, 0)
        d.onWindow(insta, true, 1, today)
        d.onWindow(launcher, true, 2, today)
        assertEquals(insta, d.onWindow(insta, true, 60_000, today))
    }

    @Test
    fun `with the free window, reopening within it is free and after it is gated`() {
        val (d, _) = decider(grace = true)
        d.onWindow(insta, true, 0, today)
        d.unlocked(insta, 0)
        d.onWindow(insta, true, 1, today)
        d.onWindow(launcher, true, 2, today)
        assertNull(d.onWindow(insta, true, 4 * 60_000, today))
        d.onWindow(launcher, true, 4 * 60_000 + 1, today)
        assertEquals(insta, d.onWindow(insta, true, 6 * 60_000, today))
    }

    @Test
    fun `the feature switched off gates nothing`() {
        val state = GateState().apply { dueCount = 5; dueDay = today }
        val d = GateDecider(GateConfig(enabled = false, packages = setOf(insta)), state)
        assertNull(d.onWindow(insta, true, 0, today))
    }
}
