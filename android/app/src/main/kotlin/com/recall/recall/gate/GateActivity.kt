package com.recall.recall.gate

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * The flashcards shown before a chosen app opens.
 *
 * Its own task, kept out of the recent-apps list, so it sits between the user
 * and the app and leaves no trace behind. Runs the `gateMain` Dart entry point,
 * not the full app.
 */
class GateActivity : FlutterActivity() {

    var target: String? = null
        private set

    override fun getDartEntrypointFunctionName(): String = "gateMain"

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        target = intent?.getStringExtra(EXTRA_TARGET)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        target = intent.getStringExtra(EXTRA_TARGET)
        // A different app was opened while this screen was up; the Flutter side
        // asks again for the target when it is told.
        AppGateChannel.notifyTargetChanged(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AppGateChannel.register(flutterEngine, this, gate = this)
    }

    /** Back leaves to the home screen, never into the app it was guarding. */
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        goHome()
    }

    fun goHome() {
        startActivity(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        finish()
    }

    /** The cards are answered: let [pkg] through and open it. */
    fun unlockAndOpen(pkg: String) {
        AppGate.ensureLoaded(this)
        AppGate.decider.unlocked(pkg, System.currentTimeMillis())
        val launch = packageManager.getLaunchIntentForPackage(pkg)
        if (launch != null) {
            startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
        finish()
    }

    companion object {
        const val EXTRA_TARGET = "target"
    }
}
