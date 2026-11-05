package com.recall.recall

import com.recall.recall.gate.AppGateChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The app-lock settings screen talks to the native side through this.
        AppGateChannel.register(flutterEngine, this)
    }
}
