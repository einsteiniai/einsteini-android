package com.example.einsteiniapp

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodChannel

class EinsteiniAccessibilityService : AccessibilityService() {

    companion object {
        private var instance: EinsteiniAccessibilityService? = null
        private var running = false

        fun getInstance(): EinsteiniAccessibilityService? {
            return instance
        }

        // Check if the service is running
        fun isRunning(): Boolean {
            return running
        }
    }

    override fun onServiceConnected() {
        instance = this
        super.onServiceConnected()
        running = true
        Log.d("EinsteiniAccessibility", "Service connected")
    }

    override fun onDestroy() {
        super.onDestroy()
        running = false
        Log.d("EinsteiniAccessibility", "Service destroyed")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // We don't need to handle any accessibility events
    }

    override fun onInterrupt() {
        // No action needed on interrupt
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }
} 