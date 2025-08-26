package com.einsteini.app

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import org.json.JSONObject
import com.einsteini.app.R
import android.os.Handler
import android.os.Looper
import android.widget.Toast
import androidx.annotation.NonNull
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.einsteini.app/platform_channel"
    private val OVERLAY_CHANNEL = "com.einsteini.ai/overlay"
    private val executor = Executors.newFixedThreadPool(2)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ compatibility
        try {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        } catch (e: Exception) {
            Log.w("MainActivity", "Could not enable edge-to-edge", e)
        }
        
        // Handle any intent that was used to start the activity
        handleIntent(intent)
    }

    // Helper method to check if dark mode is enabled
    private fun isDarkModeEnabled(): Boolean {
        return when (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) {
            Configuration.UI_MODE_NIGHT_YES -> true
            else -> false
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Set up the main platform channel
        setupMethodChannel(flutterEngine)

        // Set up the overlay channel
        val overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.einsteini.ai/overlay")
        overlayChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    val text = call.argument<String>("text") ?: ""
                    showOverlay(text)
                    result.success(true)
                }
                "hideOverlay" -> {
                    hideOverlay()
                    result.success(true)
                }
                "updateOverlayTheme" -> {
                    val isDarkMode = call.argument<Boolean>("isDarkMode") ?: isDarkModeEnabled()
                    Log.d("MainActivity", "Explicitly updating overlay theme with isDarkMode: $isDarkMode")
                    updateOverlayTheme(isDarkMode)
                    result.success(true)
                }
                "startOverlayService" -> {
                    try {
                        Log.d("MainActivity", "Starting overlay service")
                        if (checkOverlayPermission()) {
                            val intent = Intent(this, EinsteiniOverlayService::class.java)
                            
                            // Get the explicit theme mode from Flutter 
                            val isDarkMode = call.argument<Boolean>("isDarkMode")
                            Log.d("MainActivity", "Flutter explicitly provided isDarkMode: $isDarkMode")
                            
                            if (isDarkMode != null) {
                                intent.putExtra("isDarkMode", isDarkMode)
                                Log.d("MainActivity", "Starting overlay with explicit isDarkMode: $isDarkMode")
                            } else {
                                // Fallback to system setting if Flutter didn't provide theme
                                val systemDarkMode = isDarkModeEnabled()
                                intent.putExtra("isDarkMode", systemDarkMode)
                                Log.d("MainActivity", "Starting overlay with system isDarkMode: $systemDarkMode")
                            }
                            
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } else {
                            Log.d("MainActivity", "Cannot start overlay service - permission not granted")
                            result.success(false)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error starting overlay service", e)
                        result.success(false)
                    }
                }
                "stopOverlayService" -> {
                    try {
                        Log.d("MainActivity", "Stopping overlay service")
                        val intent = Intent(this, EinsteiniOverlayService::class.java)
                        stopService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error stopping overlay service", e)
                        result.success(false)
                    }
                }
                "isOverlayServiceRunning" -> {
                    try {
                        val isRunning = EinsteiniOverlayService.isRunning()
                        Log.d("MainActivity", "Overlay service running: $isRunning")
                        result.success(isRunning)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error checking if overlay service is running", e)
                        result.success(false)
                    }
                }
                "processLinkedInUrl" -> {
                    try {
                        val url = call.argument<String>("url")
                        if (url != null) {
                            Log.d("MainActivity", "Processing LinkedIn URL: $url")
                            
                            if (checkOverlayPermission()) {
                                val intent = Intent(this, EinsteiniOverlayService::class.java)
                                intent.action = "PROCESS_LINKEDIN_URL"
                                intent.putExtra("linkedInUrl", url)
                                intent.putExtra("isDarkMode", isDarkModeEnabled())
                                
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    startForegroundService(intent)
                                } else {
                                    startService(intent)
                                }
                                result.success(true)
                            } else {
                                Log.d("MainActivity", "Cannot process LinkedIn URL - overlay permission not granted")
                                result.success(false)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "URL cannot be null", null)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error processing LinkedIn URL", e)
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set the method channel in the overlay service
        Log.d("MainActivity", "Setting method channel in overlay service: $overlayChannel")
        EinsteiniOverlayService.setMethodChannel(overlayChannel)
        
        // Set up the platform channel for additional methods
        val platformChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "einsteini/platform")
        platformChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openOverlayPermissionActivity" -> {
                    val intent = Intent(this, OverlayPermissionActivity::class.java)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }
                "shareToLinkedIn" -> {
                    val content = call.argument<String>("content") ?: ""
                    shareToLinkedIn(content)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        val settingsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.einsteini.ai/settings")
        settingsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "openSystemSettings" -> {
                    val action = call.argument<String>("action")
                    if (action != null) {
                        openSystemSettings(action)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Action cannot be null", null)
                    }
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "checkAccessibilityPermission" -> {
                    result.success(checkAccessibilityPermission())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        val overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.einsteini.ai/overlay")
        overlayChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverlay" -> {
                    if (checkOverlayPermission()) {
                        EinsteiniOverlayService.showOverlay(this)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "hideOverlay" -> {
                    EinsteiniOverlayService.hideOverlay(this)
                    result.success(true)
                }
                "processLinkedInUrl" -> {
                    try {
                        val linkedInUrl = call.argument<String>("linkedInUrl")
                        if (linkedInUrl != null) {
                            if (checkOverlayPermission()) {
                                val intent = Intent(this, EinsteiniOverlayService::class.java)
                                intent.action = "PROCESS_LINKEDIN_URL"
                                intent.putExtra("linkedInUrl", linkedInUrl)
                                intent.putExtra("isDarkMode", isDarkModeEnabled())
                                
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                    startForegroundService(intent)
                                } else {
                                    startService(intent)
                                }
                                result.success(true)
                            } else {
                                Log.d("MainActivity", "Cannot process LinkedIn URL - overlay permission not granted")
                                result.success(false)
                            }
                        } else {
                            result.error("INVALID_ARGUMENT", "URL cannot be null", null)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error processing LinkedIn URL", e)
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    // Open system settings with the given action
    private fun openSystemSettings(action: String) {
        try {
            val intent = Intent(action)
            if (action == "android.settings.MANAGE_OVERLAY_PERMISSION") {
                // Make sure to set the package URI correctly
                intent.data = Uri.parse("package:$packageName")
                
                // Add flags to ensure the intent opens properly
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                intent.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY)
                
                startActivity(intent)
            } else {
                // For other settings intents
                startActivity(intent)
            }
        } catch (e: Exception) {
            // Fallback method for devices with custom UIs
            Log.e("MainActivity", "Error opening system settings: ${e.message}")
            
            try {
                // Alternative approach for overlay permission
                if (action == "android.settings.MANAGE_OVERLAY_PERMISSION") {
                    // Try to use the Settings.ACTION_MANAGE_OVERLAY_PERMISSION constant directly
                    val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
                    intent.data = Uri.parse("package:$packageName")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                }
            } catch (e2: Exception) {
                Log.e("MainActivity", "Error with first fallback approach: ${e2.message}")
                
                // Last resort fallback - try to go to app settings if all else fails
                try {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                    intent.data = Uri.parse("package:$packageName")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    Log.e("MainActivity", "Opened general app settings as last resort")
                } catch (e3: Exception) {
                    Log.e("MainActivity", "All attempts to open settings failed: ${e3.message}")
                }
            }
        }
    }
    
    // Check if overlay permission is granted
    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }
    
    // Check if accessibility service is enabled
    private fun checkAccessibilityPermission(): Boolean {
        val accessibilityEnabled = try {
            Settings.Secure.getInt(contentResolver, Settings.Secure.ACCESSIBILITY_ENABLED)
        } catch (e: Settings.SettingNotFoundException) {
            0
        }
        
        if (accessibilityEnabled == 1) {
            val services = Settings.Secure.getString(contentResolver, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            if (services != null) {
                return services.contains("$packageName/com.einsteini.app.EinsteiniAccessibilityService")
        }
        }
        return false
    }
    
    // Show overlay with the given text
    private fun showOverlay(text: String) {
        if (checkOverlayPermission()) {
            val intent = Intent(this, EinsteiniOverlayService::class.java)
            intent.putExtra("text", text)
            intent.putExtra("isDarkMode", isDarkModeEnabled())
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }
        
    // Hide the overlay
    private fun hideOverlay() {
        val intent = Intent(this, EinsteiniOverlayService::class.java)
        stopService(intent)
    }
                
    // Update the theme of the overlay
    private fun updateOverlayTheme(isDarkMode: Boolean) {
        if (checkOverlayPermission()) {
            Log.d("MainActivity", "Sending theme update to service: isDarkMode=$isDarkMode")
            val intent = Intent(this, EinsteiniOverlayService::class.java)
            intent.action = "UPDATE_THEME"
            intent.putExtra("isDarkMode", isDarkMode)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }
    
    // Handle new intents (for sharing from other apps like LinkedIn)
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent) {
        val action = intent.action
        val type = intent.type
        
        if (Intent.ACTION_SEND == action && type != null) {
            if ("text/plain" == type) {
                val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)
                if (sharedText != null) {
                    // Process directly without showing the app UI
                    processSharedText(sharedText)
                    
                    // Don't pass control to Flutter, we're handling this directly
                    return
                }
            }
        }
        
        // For all other intents, proceed with normal app startup
    }
    
    private fun processSharedText(text: String) {
        Log.d("MainActivity", "Processing shared text: $text")
        
        // Extract LinkedIn URL if present
        val urlPattern = "(https?://([\\w-]+\\.)?linkedin\\.com/[^\\s]+)".toRegex()
        val matchResult = urlPattern.find(text)
        
        if (matchResult != null) {
            val linkedInUrl = matchResult.value
            Log.d("MainActivity", "Found LinkedIn URL: $linkedInUrl")
            
            // Check if overlay permission is granted
            if (checkOverlayPermission()) {
                try {
                    // Start overlay service with the LinkedIn URL immediately
                    val serviceIntent = Intent(this, EinsteiniOverlayService::class.java)
                    serviceIntent.action = "PROCESS_LINKEDIN_URL"
                    serviceIntent.putExtra("linkedInUrl", linkedInUrl)
                    serviceIntent.putExtra("isDarkMode", isDarkModeEnabled())
                    serviceIntent.putExtra("fromShare", true) // Flag to indicate this is from sharing
                    
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    
                    // Move to background immediately to return to LinkedIn seamlessly
                    moveTaskToBack(true)
                } catch (e: Exception) {
                    Log.e("MainActivity", "Error starting overlay service", e)
                    finish()
                }
            } else {
                Log.d("MainActivity", "Cannot show overlay - permission not granted")
                Toast.makeText(this, "Overlay permission is required to use this feature", Toast.LENGTH_LONG).show()
                // Open overlay permission settings
                openSystemSettings("android.settings.MANAGE_OVERLAY_PERMISSION")
            }
        } else {
            Log.d("MainActivity", "No LinkedIn URL found in shared text")
            Toast.makeText(this, "No LinkedIn URL found in shared content", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    private fun shareToLinkedIn(content: String) {
        val intent = Intent(Intent.ACTION_SEND)
        intent.type = "text/plain"
        intent.setPackage("com.linkedin.android")
        intent.putExtra(Intent.EXTRA_TEXT, content)
        try {
            startActivity(intent)
        } catch (e: Exception) {
            // Fallback: open LinkedIn web post creation
            val webIntent = Intent(Intent.ACTION_VIEW)
            webIntent.data = Uri.parse("https://www.linkedin.com/feed/?shareActive=true")
            startActivity(webIntent)
        }
    }
}
