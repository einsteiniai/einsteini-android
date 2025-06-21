package com.example.einsteiniapp

import android.animation.ValueAnimator
import android.animation.AnimatorListenerAdapter
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.graphics.PixelFormat
import android.graphics.Color
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.view.isVisible
import io.flutter.plugin.common.MethodChannel
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class EinsteiniOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private lateinit var overlayView: View
    private lateinit var closeButtonView: View
    
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var overlayParams: WindowManager.LayoutParams? = null
    private var closeButtonParams: WindowManager.LayoutParams? = null
    
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    private var screenWidth: Int = 0
    private var screenHeight: Int = 0
    private var bubbleSize: Int = 120 // Increased size
    private var closeButtonSize: Int = 180 // Slightly larger than bubble for easier targeting
    private var lastUpdateTime: Long = 0
    private val FRAME_RATE = 60 // Target 60 FPS
    private val FRAME_TIME = (1000 / FRAME_RATE).toLong() // Time per frame in milliseconds
    private var currentAnimator: ValueAnimator? = null
    private var isOverlayVisible = false
    private val NOTIFICATION_ID = 101
    private val CHANNEL_ID = "einsteini_overlay_channel"
    private var isDraggingOverlay = false
    
    private var overlayWidth = 800
    private var overlayHeight = 600
    private val CLOSE_TRIGGER_DISTANCE = 100

    companion object {
        private var instance: EinsteiniOverlayService? = null
        private var methodChannel: MethodChannel? = null
        private var running = false

        fun isRunning(): Boolean {
            return running && instance != null
        }

        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }

        fun getInstance(): EinsteiniOverlayService? {
            return instance
        }

        private const val TAG = "EinsteiniOverlayService"
        private const val NOTIFICATION_ID_NEW = 1001
        private const val CHANNEL_ID_NEW = "EinsteiniOverlayChannel"
        private const val CHANNEL_NAME = "Overlay Service"
        
        // Theme-related constants
        private const val THEME_PREFERENCE_KEY = "theme_preference"
        
        // Public methods to control service from outside
        fun showOverlay(context: Context) {
            Log.d(TAG, "showOverlay called from companion")
            try {
                val intent = Intent(context, EinsteiniOverlayService::class.java)
                intent.action = "START_OVERLAY"
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Log.d(TAG, "Starting as foreground service")
                    context.startForegroundService(intent)
                } else {
                    Log.d(TAG, "Starting as regular service")
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Exception in showOverlay", e)
            }
        }
        
        fun hideOverlay(context: Context) {
            Log.d(TAG, "hideOverlay called from companion")
            try {
                val intent = Intent(context, EinsteiniOverlayService::class.java)
                intent.action = "STOP_SERVICE"
                context.startService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Exception in hideOverlay", e)
            }
        }
    }
    
    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate() {
        super.onCreate()
        Log.d("EinsteiniOverlay", "Service onCreate")
        
        try {
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            
            // Get screen dimensions
            val metrics = DisplayMetrics()
            windowManager.defaultDisplay.getMetrics(metrics)
            screenWidth = metrics.widthPixels
            screenHeight = metrics.heightPixels
            
            // Update instance and running state
            instance = this
            running = true
            
            // Create notification channel for Android O and above
            createNotificationChannel()
            
            // Start as foreground service with notification
            try {
                startForeground(NOTIFICATION_ID, createNotification())
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Failed to start as foreground service", e)
                // Continue anyway, as we might still be able to show the overlay
                // even if the foreground service fails
            }
            
            // Setup components in sequence, with error handling for each
            try {
                setupBubble()
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error setting up bubble", e)
            }
            
            try {
                setupOverlay()
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error setting up overlay", e)
            }
            
            try {
                setupCloseButton()
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error setting up close button", e)
            }
            
            // Register for theme changes from Flutter
            registerThemeChangeReceiver()
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Fatal error in onCreate", e)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("EinsteiniOverlay", "Service onStartCommand with action: ${intent?.action}")
        
        if (intent?.action == "STOP_SERVICE") {
            Log.d("EinsteiniOverlay", "Received stop command, stopping service")
            stopSelf()
            return START_NOT_STICKY
        }
        
        // Make sure we start as a foreground service if not already
        try {
            startForeground(NOTIFICATION_ID, createNotification())
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error starting as foreground service", e)
            // Continue anyway as we might still be able to show the overlay
        }
        
        // Initialize all necessary components
        try {
            // Make sure we have at least initialized the bubble
            if (!::bubbleView.isInitialized) {
                Log.d("EinsteiniOverlay", "Bubble not initialized, setting up bubble now")
                setupBubble()
            }
            
            // Make sure all necessary components are initialized
            if (!::overlayView.isInitialized) {
                Log.d("EinsteiniOverlay", "Overlay not initialized, setting up overlay now")
                setupOverlay()
            }
            
            if (!::closeButtonView.isInitialized) {
                Log.d("EinsteiniOverlay", "Close button not initialized, setting up now")
                setupCloseButton()
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error initializing components", e)
        }
        
        // Only show bubble if it's not already visible
        if (::bubbleView.isInitialized) {
            try {
                if (bubbleView.parent == null) {
                    Log.d("EinsteiniOverlay", "Adding bubble to window manager")
                    // Position the bubble at the right edge of the screen
                    bubbleParams?.x = screenWidth - bubbleSize - 16
                    bubbleParams?.y = 100
                    windowManager.addView(bubbleView, bubbleParams)
                    // Animate entry only when we add the view
                    animateEntry(bubbleParams)
                } else {
                    Log.d("EinsteiniOverlay", "Bubble already visible, not adding again")
                    // Make sure it's visible
                    bubbleView.visibility = View.VISIBLE
                }
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error showing bubble in onStartCommand", e)
            }
        } else {
            Log.e("EinsteiniOverlay", "Bubble view initialization failed")
        }
        
        return START_STICKY
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Einsteini Overlay"
            val descriptionText = "Notifications for Einsteini overlay service"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
                setShowBadge(false)
            }
            val notificationManager: NotificationManager = 
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, 
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else 
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Create a stop action
        val stopIntent = Intent(this, EinsteiniOverlayService::class.java).apply {
            action = "STOP_SERVICE"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) 
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            else 
                PendingIntent.FLAG_UPDATE_CURRENT
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Einsteini Floating Assistant")
            .setContentText("Tap to open app")
            .setSmallIcon(android.R.drawable.ic_dialog_info) // Fallback icon
            .setColor(0xC58AFF) // Purple color
            .setColorized(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupBubble() {
        Log.d("EinsteiniOverlay", "Creating bubble")
        try {
            // Create the bubble view
            bubbleView = LayoutInflater.from(this).inflate(R.layout.bubble, null)
            
            // Set the correct icon and background based on theme
            updateBubbleTheme()
            
            // Create a layout type based on Android version
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                WindowManager.LayoutParams.TYPE_PHONE
            }
            
            bubbleParams = WindowManager.LayoutParams(
                bubbleSize,
                bubbleSize,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                        WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = 0
                y = 100
            }

            bubbleView.setOnTouchListener { view, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        Log.d("EinsteiniOverlay", "Bubble touched down")
                        currentAnimator?.cancel()
                        initialX = bubbleParams?.x ?: 0
                        initialY = bubbleParams?.y ?: 0
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        try {
                            showCloseButton()
                        } catch (e: Exception) {
                            Log.e("EinsteiniOverlay", "Error showing close button", e)
                        }
                        true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val currentTime = System.currentTimeMillis()
                        if (currentTime - lastUpdateTime >= FRAME_TIME) {
                            bubbleParams?.x = initialX + (event.rawX - initialTouchX).toInt()
                            bubbleParams?.y = initialY + (event.rawY - initialTouchY).toInt()

                            // Ensure bubble stays within screen bounds
                            bubbleParams?.x = max(0, min(bubbleParams?.x ?: 0, screenWidth - bubbleSize))
                            bubbleParams?.y = max(0, min(bubbleParams?.y ?: 0, screenHeight - bubbleSize))

                            try {
                                if (bubbleView.parent != null) {
                                    windowManager.updateViewLayout(bubbleView, bubbleParams)
                                }
                            } catch (e: Exception) {
                                Log.e("EinsteiniOverlay", "Error updating bubble position", e)
                            }

                            // Update close button alpha based on proximity
                            if (isNearCloseButton(event.rawX, event.rawY)) {
                                animateCloseButtonAlpha(1f)
                            } else {
                                animateCloseButtonAlpha(0.5f)
                            }

                            lastUpdateTime = currentTime
                        }
                        true
                    }
                    MotionEvent.ACTION_UP -> {
                        Log.d("EinsteiniOverlay", "Bubble touched up")
                        val moved = abs(event.rawX - initialTouchX) > 10 ||
                                  abs(event.rawY - initialTouchY) > 10

                        if (moved) {
                            if (isNearCloseButton(event.rawX, event.rawY)) {
                                animateAndClose()
                            } else {
                                snapToEdge(bubbleParams)
                            }
                        } else {
                            // It was a click
                            Log.d("EinsteiniOverlay", "Bubble clicked, showing overlay")
                            toggleOverlayVisibility()
                        }
                        try {
                            hideCloseButton()
                        } catch (e: Exception) {
                            Log.e("EinsteiniOverlay", "Error hiding close button", e)
                        }
                        true
                    }
                    else -> false
                }
            }

            // Don't add view here, we'll add it in onStartCommand
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error in setupBubble", e)
            throw e // Re-throw to let the caller handle it
        }
    }
    
    // Update bubble appearance based on current theme
    private fun updateBubbleTheme() {
        if (!::bubbleView.isInitialized) return
        
        val circleView = bubbleView.findViewById<ImageView>(R.id.circle)
        val isDark = isDarkMode()
        
        Log.d(TAG, "Updating bubble theme. Dark mode: $isDark")
        
        if (isDark) {
            // Dark mode - white logo on black background
            circleView.setImageResource(R.drawable.einsteini_white)
            circleView.setBackgroundResource(R.drawable.bubble_background_dark)
        } else {
            // Light mode - black logo on white background
            circleView.setImageResource(R.drawable.einsteini_black)
            circleView.setBackgroundResource(R.drawable.bubble_background_light)
        }
    }
    
    @SuppressLint("ClickableViewAccessibility")
    private fun setupOverlay() {
        try {
            overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_window, null)
            
            // Apply theme to the overlay
            updateOverlayTheme()
            
            // Set up the tabs
            val tab1 = overlayView.findViewById<TextView>(R.id.tab1)
            val tab2 = overlayView.findViewById<TextView>(R.id.tab2)
            val tab3 = overlayView.findViewById<TextView>(R.id.tab3)
            
            val contentView1 = overlayView.findViewById<LinearLayout>(R.id.contentViewLinkedIn)
            val contentView2 = overlayView.findViewById<LinearLayout>(R.id.contentViewTwitter)
            val contentView3 = overlayView.findViewById<LinearLayout>(R.id.contentViewComment)
            
            // Get reference to the ScrollView
            val scrollView = overlayView.findViewById<ScrollView>(R.id.contentScrollView)
            
            tab1.setOnClickListener {
                tab1.setTextColor(Color.parseColor("#BD79FF"))
                tab2.setTextColor(Color.parseColor(if (isDarkMode()) "#B4B7BD" else "#666666"))
                tab3.setTextColor(Color.parseColor(if (isDarkMode()) "#B4B7BD" else "#666666"))
                tab1.textSize = 16f
                tab2.textSize = 14f
                tab3.textSize = 14f
                
                contentView1.visibility = View.VISIBLE
                contentView2.visibility = View.GONE
                contentView3.visibility = View.GONE
                
                // Reset scroll position when changing tabs
                scrollView.scrollTo(0, 0)
            }
            
            tab2.setOnClickListener {
                tab1.setTextColor(Color.parseColor(if (isDarkMode()) "#B4B7BD" else "#666666"))
                tab2.setTextColor(Color.parseColor("#BD79FF"))
                tab3.setTextColor(Color.parseColor(if (isDarkMode()) "#B4B7BD" else "#666666"))
                tab1.textSize = 14f
                tab2.textSize = 16f
                tab3.textSize = 14f
                
                contentView1.visibility = View.GONE
                contentView2.visibility = View.VISIBLE
                contentView3.visibility = View.GONE
                
                // Reset scroll position when changing tabs
                scrollView.scrollTo(0, 0)
            }
            
            tab3.setOnClickListener {
                tab1.setTextColor(Color.parseColor(if (isDarkMode()) "#B4B7BD" else "#666666"))
                tab2.setTextColor(Color.parseColor(if (isDarkMode()) "#B4B7BD" else "#666666"))
                tab3.setTextColor(Color.parseColor("#BD79FF"))
                tab1.textSize = 14f
                tab2.textSize = 14f
                tab3.textSize = 16f
                
                contentView1.visibility = View.GONE
                contentView2.visibility = View.GONE
                contentView3.visibility = View.VISIBLE
                
                // Reset scroll position when changing tabs
                scrollView.scrollTo(0, 0)
            }
            
            // Set up resize handle with direct window manager updates
            val resizeHandle = overlayView.findViewById<View>(R.id.resizeHandle)
            var initialTouchY = 0f
            var initialHeight = 0
            
            // Minimum height is 40% of screen height (same as initial height)
            val minHeight = (resources.displayMetrics.heightPixels * 0.4).toInt()
            
            // Intercept touch events on the resize handle to prevent scroll conflicts
            resizeHandle.setOnTouchListener(object : View.OnTouchListener {
                override fun onTouch(view: View, event: MotionEvent): Boolean {
                    // Prevent scroll view from intercepting touch events during resize
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            scrollView.requestDisallowInterceptTouchEvent(true)
                            initialTouchY = event.rawY
                            initialHeight = overlayView.height
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            // Calculate new height based on drag (moving up increases height)
                            val dy = initialTouchY - event.rawY
                            val newHeight = initialHeight + dy.toInt()
                            
                            // If height is below minimum threshold, immediately dismiss
                            if (newHeight < minHeight) {
                                hideOverlayWindow()
                                return true
                            } else {
                                overlayView.alpha = 1f
                                
                                // Update the window layout params directly
                                try {
                                    if (overlayParams != null && overlayView.parent != null) {
                                        overlayParams?.height = newHeight
                                        windowManager.updateViewLayout(overlayView, overlayParams)
                                    }
                                } catch (e: Exception) {
                                    Log.e(TAG, "Error updating overlay height", e)
                                }
                            }
                            return true
                        }
                        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                            scrollView.requestDisallowInterceptTouchEvent(false)
                            // If we ended with a height below minimum, hide the overlay
                            if (overlayView.height < minHeight) {
                                hideOverlayWindow()
                            }
                            return true
                        }
                        else -> return false
                    }
                }
            })
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up overlay", e)
        }
    }
    
    // Update overlay appearance based on current theme
    private fun updateOverlayTheme() {
        if (!::overlayView.isInitialized) return
        
        val isDark = isDarkMode()
        Log.d(TAG, "Updating overlay theme. Dark mode: $isDark")
        
        // Set main background
        if (isDark) {
            overlayView.setBackgroundResource(R.drawable.overlay_rounded_background_dark)
        } else {
            overlayView.setBackgroundResource(R.drawable.overlay_rounded_background)
        }
        
        // Update tab layout background
        val tabLayout = overlayView.findViewById<LinearLayout>(R.id.tabLayout)
        tabLayout.setBackgroundColor(Color.parseColor(if (isDark) "#121827" else "#FFFFFF"))
        
        // Update divider color
        val divider = overlayView.findViewById<View>(R.id.divider)
        divider.setBackgroundColor(Color.parseColor(if (isDark) "#1A2235" else "#EEEEEE"))
        
        // Update tab text colors (inactive tabs)
        val tab1 = overlayView.findViewById<TextView>(R.id.tab1)
        val tab2 = overlayView.findViewById<TextView>(R.id.tab2)
        val tab3 = overlayView.findViewById<TextView>(R.id.tab3)
        
        val inactiveTabColor = if (isDark) "#B4B7BD" else "#666666"
        
        // Check which tab is active and update colors accordingly
        if (tab1.currentTextColor == Color.parseColor("#BD79FF")) {
            tab2.setTextColor(Color.parseColor(inactiveTabColor))
            tab3.setTextColor(Color.parseColor(inactiveTabColor))
        } else if (tab2.currentTextColor == Color.parseColor("#BD79FF")) {
            tab1.setTextColor(Color.parseColor(inactiveTabColor))
            tab3.setTextColor(Color.parseColor(inactiveTabColor))
        } else if (tab3.currentTextColor == Color.parseColor("#BD79FF")) {
            tab1.setTextColor(Color.parseColor(inactiveTabColor))
            tab2.setTextColor(Color.parseColor(inactiveTabColor))
        }
        
        // Update all content sections
        updateContentSectionTheme(R.id.contentViewLinkedIn)
        updateContentSectionTheme(R.id.contentViewTwitter)
        updateContentSectionTheme(R.id.contentViewComment)
    }
    
    // Update a specific content section with theme colors
    private fun updateContentSectionTheme(contentViewId: Int) {
        if (!::overlayView.isInitialized) return
        
        val contentView = overlayView.findViewById<LinearLayout>(contentViewId)
        val isDark = isDarkMode()
        
        // Handle all content blocks within this section
        for (i in 0 until contentView.childCount) {
            val child = contentView.getChildAt(i)
            if (child is LinearLayout) {
                // This is a content block 
                child.setBackgroundColor(Color.parseColor(if (isDark) "#1A2235" else "#F5F5F5"))
                
                // Update text colors within this block
                for (j in 0 until child.childCount) {
                    val textView = child.getChildAt(j)
                    if (textView is TextView) {
                        if (textView.textSize >= 18 * resources.displayMetrics.density) {
                            // This is a heading - keep accent color
                            textView.setTextColor(Color.parseColor("#BD79FF"))
                        } else {
                            // This is content text
                            textView.setTextColor(Color.parseColor(if (isDark) "#FFFFFF" else "#333333"))
                        }
                    }
                }
            }
        }
    }
    
    fun resizeExpandedView(width: Int, height: Int) {
        if (::overlayView.isInitialized && overlayView.parent != null && isOverlayVisible) {
            val params = overlayView.layoutParams as WindowManager.LayoutParams
            params.height = height
            
            try {
                windowManager.updateViewLayout(overlayView, params)
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error resizing overlay view", e)
            }
        }
    }
    
    private fun toggleOverlayVisibility() {
        if (!isOverlayVisible) {
            showOverlayWindow()
        } else {
            hideOverlayWindow()
        }
    }
    
    private fun showOverlayWindow() {
        if (isOverlayVisible) return
        
        try {
            // Make sure overlay view is initialized
            if (!::overlayView.isInitialized) {
                setupOverlay()
            }
            
            // Calculate initial height (40% of screen height)
            val initialHeight = (resources.displayMetrics.heightPixels * 0.4).toInt()
            
            // Position the overlay at the bottom of the screen with full width
            if (overlayParams == null) {
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                
                overlayParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    initialHeight,
                    type,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                    width = WindowManager.LayoutParams.MATCH_PARENT 
                    x = 0 // Center horizontally
                    y = 0 // Position at the bottom
                }
            } else {
                // Update existing params
                overlayParams?.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                                      WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
                overlayParams?.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
                overlayParams?.width = WindowManager.LayoutParams.MATCH_PARENT
                overlayParams?.height = initialHeight
                overlayParams?.x = 0
                overlayParams?.y = 0
            }
            
            try {
                if (overlayView.parent == null) {
                    windowManager.addView(overlayView, overlayParams)
                }
                overlayView.visibility = View.VISIBLE
                
                // Set a touch listener to detect outside touches
                overlayView.setOnTouchListener { v, event ->
                    if (event.action == MotionEvent.ACTION_OUTSIDE) {
                        // User touched outside the overlay, hide it
                        hideOverlayWindow()
                        return@setOnTouchListener true
                    }
                    false
                }
                
                animateOverlayEntry()
                isOverlayVisible = true
                
                // Hide the bubble while overlay is visible
                if (::bubbleView.isInitialized) {
                    bubbleView.visibility = View.GONE
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add overlay view to window", e)
                return
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show overlay window", e)
        }
    }
    
    private fun hideOverlayWindow() {
        if (!isOverlayVisible) return
        
        try {
            // Reset overlay state first
            isOverlayVisible = false
            
            // Show the bubble again immediately
            if (::bubbleView.isInitialized) {
                bubbleView.visibility = View.VISIBLE
            }
            
            // Animate the overlay exit
            animateOverlayExit {
                try {
                    if (::overlayView.isInitialized && overlayView.parent != null) {
                        windowManager.removeView(overlayView)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Error removing overlay view", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding overlay window", e)
            
            // Try to remove view directly if animation fails
            try {
                if (::overlayView.isInitialized && overlayView.parent != null) {
                    windowManager.removeView(overlayView)
                }
            } catch (e2: Exception) {
                Log.e(TAG, "Error removing overlay view after animation failure", e2)
            }
        }
    }
    
    private fun animateOverlayEntry() {
        try {
            if (!::overlayView.isInitialized) return
            
            // Set initial state
            overlayView.alpha = 0f
            overlayView.translationY = 200f
            
            // Animate fade in and slide up
            val animator = ValueAnimator.ofFloat(0f, 1f)
            animator.duration = 250
            animator.addUpdateListener { animation ->
                val value = animation.animatedValue as Float
                overlayView.alpha = value
                overlayView.translationY = 200f * (1 - value)
            }
            
            animator.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error in animateOverlayEntry", e)
        }
    }
    
    private fun animateOverlayExit(onComplete: () -> Unit) {
        try {
            if (!::overlayView.isInitialized) {
                onComplete()
                return
            }
            
            // Animate the overlay sliding down
            val slideDown = ValueAnimator.ofFloat(1f, 0f)
            slideDown.duration = 200
            slideDown.addUpdateListener { animator ->
                val value = animator.animatedValue as Float
                overlayView.alpha = value
                
                val params = overlayView.layoutParams
                if (params != null) {
                    val translateY = (1 - value) * 200
                    overlayView.translationY = translateY
                }
            }
            
            slideDown.addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) {
                    onComplete()
                }
            })
            
            slideDown.start()
        } catch (e: Exception) {
            Log.e(TAG, "Error in animateOverlayExit", e)
            onComplete()
        }
    }

    private fun animateEntry(params: WindowManager.LayoutParams?) {
        if (params == null) return
        
        val animator = ValueAnimator.ofFloat(0f, 1f)
        animator.duration = 500
        animator.interpolator = OvershootInterpolator()
        animator.addUpdateListener { animation ->
            try {
                // Check if the bubble is still attached to the window
                if (::bubbleView.isInitialized && bubbleView.parent != null) {
                    bubbleView.scaleX = animation.animatedValue as Float
                    bubbleView.scaleY = animation.animatedValue as Float
                    windowManager.updateViewLayout(bubbleView, params)
                } else {
                    // Cancel the animation if the view is detached
                    animation.cancel()
                }
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error in entry animation", e)
                // Cancel the animation if we encounter an error
                animation.cancel()
            }
        }
        animator.start()
    }

    private fun animateAndClose() {
        val animator = ValueAnimator.ofFloat(1f, 0f)
        animator.duration = 300
        animator.addUpdateListener { animation ->
            try {
                // Check if views are still attached
                if (::bubbleView.isInitialized && bubbleView.parent != null) {
                    bubbleView.scaleX = animation.animatedValue as Float
                    bubbleView.scaleY = animation.animatedValue as Float
                    bubbleView.alpha = animation.animatedValue as Float
                    
                    if (::closeButtonView.isInitialized && closeButtonView.parent != null) {
                        closeButtonView.alpha = animation.animatedValue as Float
                    }
                    
                    windowManager.updateViewLayout(bubbleView, bubbleParams)
                } else {
                    // Cancel animation if views are detached
                    animation.cancel()
                }
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error in close animation", e)
                animation.cancel()
            }
        }
        animator.addListener(object : android.animation.Animator.AnimatorListener {
            override fun onAnimationStart(animation: android.animation.Animator) {}
            override fun onAnimationEnd(animation: android.animation.Animator) {
                stopSelf()
            }
            override fun onAnimationCancel(animation: android.animation.Animator) {
                stopSelf()
            }
            override fun onAnimationRepeat(animation: android.animation.Animator) {}
        })
        animator.start()
    }

    private fun snapToEdge(params: WindowManager.LayoutParams?) {
        if (params == null) return
        
        val middle = screenWidth / 2
        val targetX = if ((params.x + (bubbleSize / 2)) <= middle) 0 else screenWidth - bubbleSize

        currentAnimator?.cancel()
        val animator = ValueAnimator.ofInt(params.x, targetX)
        animator.duration = 300
        animator.interpolator = OvershootInterpolator(1.5f)
        animator.addUpdateListener { animation ->
            params.x = animation.animatedValue as Int
            try {
                // Check if the bubble view is still attached
                if (::bubbleView.isInitialized && bubbleView.parent != null) {
                    windowManager.updateViewLayout(bubbleView, params)
                } else {
                    // Cancel the animation if view is detached
                    animation.cancel()
                }
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error in snap animation", e)
                // Cancel the animation on error
                animation.cancel()
            }
        }
        animator.start()
        currentAnimator = animator
    }

    private fun animateCloseButtonAlpha(targetAlpha: Float) {
        try {
            if (::closeButtonView.isInitialized) {
                closeButtonView.animate()
                    .alpha(targetAlpha)
                    .setDuration(150)
                    .start()
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error animating close button alpha", e)
        }
    }

    private fun isNearCloseButton(rawX: Float, rawY: Float): Boolean {
        try {
            if (!::closeButtonView.isInitialized || closeButtonView.visibility != View.VISIBLE) {
                return false
            }
            
            val closeButtonY = screenHeight - closeButtonSize - 100 // Match the y offset in setupCloseButton
            val closeButtonX = screenWidth / 2 - closeButtonSize / 2

            return rawY > closeButtonY &&
                   rawX > closeButtonX &&
                   rawX < (closeButtonX + closeButtonSize)
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error checking close button proximity", e)
            return false
        }
    }

    private fun showCloseButton() {
        try {
            if (::closeButtonView.isInitialized) {
                closeButtonView.visibility = View.VISIBLE
                animateCloseButtonAlpha(0.5f)
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error showing close button", e)
        }
    }

    private fun hideCloseButton() {
        try {
            if (::closeButtonView.isInitialized && closeButtonView.visibility == View.VISIBLE) {
                closeButtonView.animate()
                    .alpha(0f)
                    .setDuration(200)
                    .withEndAction {
                        closeButtonView.visibility = View.GONE
                    }
                    .start()
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error hiding close button", e)
        }
    }
    
    private fun setupCloseButton() {
        try {
            // Initialize close button view
            closeButtonView = LayoutInflater.from(this).inflate(R.layout.close_button, null)
            
            closeButtonParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            )
            
            closeButtonParams?.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
            closeButtonParams?.y = 100
            
            closeButtonView.visibility = View.GONE
            try {
                windowManager.addView(closeButtonView, closeButtonParams)
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error adding close button view", e)
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error setting up close button", e)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("EinsteiniOverlay", "Service onDestroy")
        
        // Clean up all views
        try {
            if (::bubbleView.isInitialized) {
                try {
                    if (bubbleView.parent != null) {
                        windowManager.removeView(bubbleView)
                    }
                } catch (e: Exception) {
                    Log.e("EinsteiniOverlay", "Error removing bubble view", e)
                }
            }
            
            if (::closeButtonView.isInitialized) {
                try {
                    if (closeButtonView.parent != null) {
                        windowManager.removeView(closeButtonView)
                    }
                } catch (e: Exception) {
                    Log.e("EinsteiniOverlay", "Error removing close button view", e)
                }
            }
            
            if (::overlayView.isInitialized) {
                try {
                    if (overlayView.parent != null) {
                        windowManager.removeView(overlayView)
                    }
                } catch (e: Exception) {
                    Log.e("EinsteiniOverlay", "Error removing overlay view", e)
                }
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error in onDestroy cleanup", e)
        } finally {
            // Always update instance and running state
            instance = null
            running = false
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // Get the current theme mode based on Flutter app's preference
    private fun getThemeMode(): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        // Default to "system" if not found
        return prefs.getString("flutter.${THEME_PREFERENCE_KEY}", "system") ?: "system"
    }
    
    // Check if the app should be in dark mode based on theme preference
    private fun isDarkMode(): Boolean {
        val themeMode = getThemeMode()
        
        return when (themeMode) {
            "dark" -> true
            "light" -> false
            else -> { // "system" or any other value
                (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == 
                    Configuration.UI_MODE_NIGHT_YES
            }
        }
    }

    // Register for theme changes from Flutter
    @SuppressLint("UnspecifiedRegisterReceiverFlag")
    private fun registerThemeChangeReceiver() {
        try {
            val filter = IntentFilter("com.example.einsteiniapp.THEME_CHANGED")
            registerReceiver(object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    Log.d(TAG, "Theme change detected")
                    updateAllViews()
                }
            }, filter)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register theme change receiver", e)
        }
    }
    
    // Update all UI components based on current theme
    private fun updateAllViews() {
        Log.d(TAG, "Updating all views with theme")
        updateBubbleTheme()
        updateOverlayTheme()
    }
} 