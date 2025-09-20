package com.erkayteknoloji.securelauncher

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("BootReceiver", "Boot completed received: ${intent.action}")

        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {

            val prefs: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isKioskModeEnabled = prefs.getBoolean("flutter.kiosk_mode_enabled", false)

            Log.d("BootReceiver", "Kiosk mode enabled: $isKioskModeEnabled")

            if (isKioskModeEnabled) {
                Log.d("BootReceiver", "Starting SecureLauncher in kiosk mode")

                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra("auto_start_kiosk", true)
                }

                context.startActivity(launchIntent)
            }
        }
    }
}