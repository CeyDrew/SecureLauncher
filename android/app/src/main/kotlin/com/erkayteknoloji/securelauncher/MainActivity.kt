package com.erkayteknoloji.securelauncher

import android.app.ActivityManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.kiosk/locktask"
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Navigation bar'ı her zaman gizli tut
        hideNavigationBar()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, MyDeviceAdminReceiver::class.java)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startLockTask" -> {
                    try {
                        startLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("LOCK_TASK_ERROR", e.message, null)
                    }
                }
                "stopLockTask" -> {
                    try {
                        stopLockTask()
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("UNLOCK_TASK_ERROR", e.message, null)
                    }
                }
                "isLockTaskActive" -> {
                    try {
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val lockTaskMode = activityManager.lockTaskModeState
                        val isActive = lockTaskMode != ActivityManager.LOCK_TASK_MODE_NONE
                        Log.d("MainActivity", "Lock task mode state: $lockTaskMode, isActive: $isActive")
                        result.success(isActive)
                    } catch (e: Exception) {
                        result.error("CHECK_LOCK_TASK_ERROR", e.message, null)
                    }
                }
                "setLockTaskPackages" -> {
                    try {
                        val packages = call.argument<List<String>>("packages")
                        if (packages != null) {
                            val success = setLockTaskPackages(packages)
                            result.success(success)
                        } else {
                            result.error("INVALID_PACKAGES", "Packages list is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("SET_LOCK_TASK_PACKAGES_ERROR", e.message, null)
                    }
                }
                "isDeviceOwner" -> {
                    try {
                        val isOwner = devicePolicyManager.isDeviceOwnerApp(packageName)
                        result.success(isOwner)
                    } catch (e: Exception) {
                        result.error("CHECK_DEVICE_OWNER_ERROR", e.message, null)
                    }
                }
                "launchApp" -> {
                    try {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            val success = launchApp(packageName)
                            result.success(success)
                        } else {
                            result.error("INVALID_PACKAGE_NAME", "Package name is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("LAUNCH_APP_ERROR", e.message, null)
                    }
                }
                "getLaunchableApps" -> {
                    try {
                        val apps = getLaunchableApps()
                        result.success(apps)
                    } catch (e: Exception) {
                        result.error("GET_APPS_ERROR", e.message, null)
                    }
                }
                "shouldAutoStartKiosk" -> {
                    try {
                        val shouldAutoStart = intent.getBooleanExtra("auto_start_kiosk", false)
                        result.success(shouldAutoStart)
                    } catch (e: Exception) {
                        result.error("CHECK_AUTO_START_ERROR", e.message, null)
                    }
                }
                "verifyMasterKey" -> {
                    try {
                        val masterKey = call.argument<String>("masterKey")
                        if (masterKey != null) {
                            val isValid = verifyMasterKey(masterKey)
                            result.success(isValid)
                        } else {
                            result.error("INVALID_MASTER_KEY", "Master key is null", null)
                        }
                    } catch (e: Exception) {
                        result.error("VERIFY_MASTER_KEY_ERROR", e.message, null)
                    }
                }
                "uninstallApp" -> {
                    try {
                        val success = uninstallApp()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("UNINSTALL_ERROR", e.message, null)
                    }
                }
                "setAsHomeApp" -> {
                    try {
                        val success = setAsHomeApp()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("SET_HOME_APP_ERROR", e.message, null)
                    }
                }
                "clearHomeApp" -> {
                    try {
                        val success = clearHomeApp()
                        result.success(success)
                    } catch (e: Exception) {
                        result.error("CLEAR_HOME_APP_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setLockTaskPackages(packages: List<String>): Boolean {
        return try {
            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                devicePolicyManager.setLockTaskPackages(componentName, packages.toTypedArray())
                true
            } else {
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error setting lock task packages", e)
            false
        }
    }

    private fun launchApp(packageName: String): Boolean {
        return try {
            Log.d("MainActivity", "Attempting to launch app: $packageName")
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                Log.d("MainActivity", "Launch intent found for: $packageName")
                startActivity(launchIntent)
                Log.d("MainActivity", "Successfully started activity for: $packageName")
                true
            } else {
                Log.w("MainActivity", "No launch intent found for: $packageName")
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error launching app: $packageName", e)
            false
        }
    }

    private fun getLaunchableApps(): List<Map<String, Any?>> {
        val apps = mutableListOf<Map<String, Any?>>()
        
        try {
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
            }
            
            val resolveInfos = packageManager.queryIntentActivities(intent, 0)
            
            for (resolveInfo in resolveInfos) {
                val activityInfo = resolveInfo.activityInfo
                val packageName = activityInfo.packageName
                val appName = packageManager.getApplicationLabel(activityInfo.applicationInfo).toString()
                val icon = packageManager.getApplicationIcon(activityInfo.applicationInfo)
                val iconBytes = drawableToByteArray(icon)
                
                apps.add(mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "iconBytes" to iconBytes
                ))
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error getting launchable apps", e)
        }
        
        return apps
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }
        
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
    
    private fun hideNavigationBar() {
        Log.d("MainActivity", "Hiding navigation bar permanently")
        
        // Navigation bar'ı tamamen gizle - immersive sticky mode
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
            View.SYSTEM_UI_FLAG_FULLSCREEN or
            View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        // Tam ekran mod
        window.addFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS
        )
        
        // UI visibility listener - tekrar gösterilmeye çalışılırsa engelle
        window.decorView.setOnSystemUiVisibilityChangeListener { visibility ->
            Log.d("MainActivity", "System UI visibility changed: $visibility - re-hiding")
            
            // Navigation bar gösterilmeye çalışılırsa tekrar gizle
            if ((visibility and View.SYSTEM_UI_FLAG_HIDE_NAVIGATION) == 0 ||
                (visibility and View.SYSTEM_UI_FLAG_FULLSCREEN) == 0) {
                window.decorView.postDelayed({
                    hideNavigationBar()
                }, 100)
            }
        }
    }

    private fun verifyMasterKey(masterKey: String): Boolean {
        return try {
            val expectedHash = "14dd0014c26d361c6d3cb09480d915f4b12f28ef1a95d90ce5a48f27da739b8d"
            val digest = MessageDigest.getInstance("SHA-256")
            val hashBytes = digest.digest(masterKey.toByteArray())
            val hashString = hashBytes.joinToString("") { "%02x".format(it) }

            Log.d("MainActivity", "Master key verification: expected=$expectedHash, actual=$hashString")
            hashString == expectedHash
        } catch (e: Exception) {
            Log.e("MainActivity", "Error verifying master key", e)
            false
        }
    }

    private fun setAsHomeApp(): Boolean {
        return try {
            Log.d("MainActivity", "Setting SecureLauncher as home app")

            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                // IntentFilter oluştur
                val intentFilter = android.content.IntentFilter().apply {
                    addAction(Intent.ACTION_MAIN)
                    addCategory(Intent.CATEGORY_HOME)
                    addCategory(Intent.CATEGORY_DEFAULT)
                }

                // Bu uygulamayı home app olarak ayarla
                devicePolicyManager.addPersistentPreferredActivity(
                    componentName,
                    intentFilter,
                    ComponentName(packageName, MainActivity::class.java.name)
                )

                Log.d("MainActivity", "Successfully set as home app")
                true
            } else {
                Log.w("MainActivity", "Not device owner, cannot set as home app")
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error setting as home app", e)
            false
        }
    }

    private fun clearHomeApp(): Boolean {
        return try {
            Log.d("MainActivity", "Clearing home app preference")

            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                // Önce kendi package'ımızı temizle
                try {
                    devicePolicyManager.clearPackagePersistentPreferredActivities(
                        componentName,
                        packageName
                    )
                    Log.d("MainActivity", "Cleared our package persistent preferred activities")
                } catch (e: Exception) {
                    Log.w("MainActivity", "Could not clear our package activities: ${e.message}")
                }

                // Diğer launcher'ları bul ve onları restore et
                try {
                    val pm = packageManager
                    val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                        addCategory(Intent.CATEGORY_HOME)
                    }
                    val homeApps = pm.queryIntentActivities(homeIntent, 0)

                    Log.d("MainActivity", "Found ${homeApps.size} home apps")

                    // Bizim uygulamayı hariç tut, diğer launcher'ları bul
                    for (resolveInfo in homeApps) {
                        val activityInfo = resolveInfo.activityInfo
                        if (activityInfo.packageName != packageName) {
                            Log.d("MainActivity", "Found other launcher: ${activityInfo.packageName}")

                            // Bu launcher'ı default olarak ayarla
                            try {
                                val intentFilter = android.content.IntentFilter().apply {
                                    addAction(Intent.ACTION_MAIN)
                                    addCategory(Intent.CATEGORY_HOME)
                                    addCategory(Intent.CATEGORY_DEFAULT)
                                }

                                devicePolicyManager.addPersistentPreferredActivity(
                                    componentName,
                                    intentFilter,
                                    ComponentName(activityInfo.packageName, activityInfo.name)
                                )

                                Log.d("MainActivity", "Set ${activityInfo.packageName} as default launcher")
                                break // İlk bulduğunu ayarla ve çık
                            } catch (e: Exception) {
                                Log.w("MainActivity", "Could not set ${activityInfo.packageName} as default: ${e.message}")
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.w("MainActivity", "Error restoring default launcher: ${e.message}")
                }

                // Son bir kez bizim package'ı temizle
                try {
                    devicePolicyManager.clearPackagePersistentPreferredActivities(
                        componentName,
                        packageName
                    )
                    Log.d("MainActivity", "Final clear of our package")
                } catch (e: Exception) {
                    Log.w("MainActivity", "Final clear failed: ${e.message}")
                }

                Log.d("MainActivity", "Successfully cleared home app preference")
                true
            } else {
                Log.w("MainActivity", "Not device owner, cannot clear home app preference")
                false
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "Error clearing home app preference", e)
            false
        }
    }

    private fun uninstallApp(): Boolean {
        return try {
            Log.d("MainActivity", "Attempting to uninstall app")

            // Önce device admin'i devre dışı bırak
            if (devicePolicyManager.isDeviceOwnerApp(packageName)) {
                Log.d("MainActivity", "Removing device owner status")
                devicePolicyManager.clearDeviceOwnerApp(packageName)
            }

            if (devicePolicyManager.isAdminActive(componentName)) {
                Log.d("MainActivity", "Removing device admin")
                devicePolicyManager.removeActiveAdmin(componentName)
            }

            // Uninstall intent'ini başlat
            val uninstallIntent = Intent(Intent.ACTION_UNINSTALL_PACKAGE).apply {
                data = android.net.Uri.parse("package:$packageName")
                putExtra(Intent.EXTRA_RETURN_RESULT, true)
            }

            startActivity(uninstallIntent)
            true
        } catch (e: Exception) {
            Log.e("MainActivity", "Error uninstalling app", e)
            false
        }
    }
}
