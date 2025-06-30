package com.einsteini.app

import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
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
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.view.animation.OvershootInterpolator
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.RadioButton
import android.widget.RadioGroup
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.TextView
import androidx.cardview.widget.CardView
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import androidx.core.view.children
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.lang.Exception
import java.lang.Math.abs
import java.lang.Math.max
import java.lang.Math.min
import java.net.HttpURLConnection
import java.net.URL
import kotlin.properties.Delegates

class EinsteiniOverlayService : Service() {
    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private lateinit var overlayView: View
    private lateinit var closeButtonView: View
    
    // Add tab TextView references as class members
    private lateinit var tab1: TextView
    private lateinit var tab2: TextView
    private lateinit var tab3: TextView
    private lateinit var contentViewLinkedIn: LinearLayout
    private lateinit var contentViewTwitter: LinearLayout
    private lateinit var contentViewComment: LinearLayout
    
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
    private var isDarkTheme: Boolean = false
    private var fromShare: Boolean = false

    // Global flag to track if bubble is shown
    private var isBubbleShown = false

    // Add a helper method to check if dark mode is enabled
    private fun isDarkModeEnabled(): Boolean {
        return (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }

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
        
        // Send scraped content to Flutter
        fun sendScrapedContentToFlutter(content: Map<String, Any>) {
            try {
                methodChannel?.invokeMethod("onContentScraped", content)
            } catch (e: Exception) {
                Log.e(TAG, "Error sending scraped content to Flutter", e)
            }
        }
    }
    
    @SuppressLint("ClickableViewAccessibility")
    override fun onCreate() {
        super.onCreate()
        Log.d("EinsteiniOverlay", "Service onCreate")
        
        try {
            // Apply the Material Components theme for proper styling
            setTheme(R.style.EinsteiniOverlayTheme)
            
            windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
            
            // Get screen dimensions
            val metrics = DisplayMetrics()
            windowManager.defaultDisplay.getMetrics(metrics)
            screenWidth = metrics.widthPixels
            screenHeight = metrics.heightPixels
            
            // Initialize isDarkTheme based on system preference by default
            // This will be overridden by the intent extra in onStartCommand
            isDarkTheme = (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
            
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
        Log.d("EinsteiniOverlay", "Service onStartCommand with intent: $intent, action: ${intent?.action}")
        
        // Store whether this came from a share
        val wasFromShare = intent?.getBooleanExtra("fromShare", false) ?: false
        fromShare = wasFromShare
        
        Log.d("EinsteiniOverlay", "fromShare set to: $fromShare")
        
        try {
            if (intent?.action == "UPDATE_THEME") {
                val isDarkMode = intent.getBooleanExtra("isDarkMode", false)
                Log.d("EinsteiniOverlay", "Received theme update: isDarkMode=$isDarkMode")
                updateOverlayTheme(isDarkMode)
                return START_STICKY
            }
            
            if (intent?.action == "PROCESS_LINKEDIN_URL") {
                val linkedInUrl = intent.getStringExtra("linkedInUrl")
                Log.d("EinsteiniOverlay", "Processing LinkedIn URL: $linkedInUrl, fromShare: $fromShare")
                
                if (!linkedInUrl.isNullOrEmpty()) {
                    // Remove bubble first if it exists
                    removeBubbleIfExists()
                    
                    // Show the overlay window immediately
                    showOverlayWindow()
                    
                    // Process the LinkedIn URL and update the overlay content
                    processLinkedInUrl(linkedInUrl)
                }
                
                return START_STICKY
            }
            
            if (intent?.action == "SHOW_TRANSLATED_CONTENT") {
                val original = intent.getStringExtra("original") ?: ""
                val translation = intent.getStringExtra("translation") ?: ""
                val language = intent.getStringExtra("language") ?: ""
                
                // Remove bubble first if it exists
                removeBubbleIfExists()
                
                // Make sure the overlay is visible
                showOverlayWindow()
                
                // Show the translated content
                showTranslatedContent(original, translation, language)
                
                return START_STICKY
            }
            
            if (intent?.action == "SHOW_COMMENT_OPTIONS") {
                val professional = intent.getStringExtra("professional") ?: ""
                val question = intent.getStringExtra("question") ?: ""
                val thoughtful = intent.getStringExtra("thoughtful") ?: ""
                
                // Remove bubble first if it exists
                removeBubbleIfExists()
                
                // Make sure the overlay is visible
                showOverlayWindow()
                
                // Show the comment options
                showCommentOptions(professional, question, thoughtful)
                
                return START_STICKY
            }
            
            if (intent?.action == "STOP_SERVICE") {
                Log.d("EinsteiniOverlay", "Stopping service by request")
                stopSelf()
                return START_NOT_STICKY
            }
            
            // Default behavior - show the bubble if not showing overlay
            if (!isOverlayVisible) {
                Log.d("EinsteiniOverlay", "Default behavior - showing bubble")
            showBubble()
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error in onStartCommand", e)
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
            
            // Get the image view
            val bubbleImageView = bubbleView.findViewById<ImageView>(R.id.bubble_icon)
            
            // Set the correct icon based on theme immediately during setup
            val iconResource = if (isDarkTheme) {
                R.drawable.einsteini_white
            } else {
                R.drawable.einsteini_black
            }
            
            // Set the correct background based on theme
            val bubbleBackground = if (isDarkTheme) {
                R.drawable.bubble_background_dark
            } else {
                R.drawable.bubble_background_light
            }
            
            // Apply theme immediately during setup
            bubbleImageView.setImageResource(iconResource)
            bubbleImageView.background = ContextCompat.getDrawable(this, bubbleBackground)
            
            Log.d(TAG, "Bubble theme set initially to isDarkTheme=$isDarkTheme, background=$bubbleBackground, icon=$iconResource")
            
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
            Log.e(TAG, "Error setting up bubble", e)
        }
    }
    
    // Update bubble theme based on current dark mode setting
    private fun updateBubbleTheme() {
        if (!::bubbleView.isInitialized) {
            Log.d(TAG, "Bubble view not initialized yet, skipping theme update")
            return
        }
        
        Log.d(TAG, "Updating bubble theme. Dark mode: $isDarkTheme")
        
        try {
            val bubbleImageView = bubbleView.findViewById<ImageView>(R.id.bubble_icon)
            
            // Set the correct background based on theme
            val bubbleBackground = if (isDarkTheme) {
                R.drawable.bubble_background_dark
            } else {
                R.drawable.bubble_background_light
            }
            
            // Set the correct icon based on theme
            val iconResource = if (isDarkTheme) {
                R.drawable.einsteini_white
            } else {
                R.drawable.einsteini_black
            }
            
            // Apply background and image immediately in a UI-thread safe way
            bubbleView.post {
                try {
                    // Update background
                    bubbleImageView?.background = ContextCompat.getDrawable(this, bubbleBackground)
                    
                    // Update image
                    bubbleImageView?.setImageResource(iconResource)
                    
                    Log.d(TAG, "Bubble theme updated successfully. Using background: $bubbleBackground and icon: $iconResource")
                } catch (e: Exception) {
                    Log.e(TAG, "Error setting bubble background or image", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating bubble theme", e)
        }
    }
    
    @SuppressLint("ClickableViewAccessibility")
    private fun setupOverlay() {
        Log.d("EinsteiniOverlay", "Creating overlay")
        try {
            // Create overlay view from layout
            overlayView = LayoutInflater.from(this).inflate(R.layout.overlay_window, null)
            
            // Get content view containers
            contentViewLinkedIn = overlayView.findViewById(R.id.contentViewLinkedIn)
            contentViewTwitter = overlayView.findViewById(R.id.contentViewTwitter)
            contentViewComment = overlayView.findViewById(R.id.contentViewComment)
            
            // Initialize tabs
            tab1 = overlayView.findViewById(R.id.tab1)
            tab2 = overlayView.findViewById(R.id.tab2)
            tab3 = overlayView.findViewById(R.id.tab3)
            
            // Load and apply custom fonts
            val spaceGrotesk = ResourcesCompat.getFont(this, R.font.spacegrotesk_medium)
            val inter = ResourcesCompat.getFont(this, R.font.inter_18pt_regular)
            
            // Apply fonts to tabs
            tab1.typeface = spaceGrotesk
            tab2.typeface = spaceGrotesk
            tab3.typeface = spaceGrotesk
            
            // Apply fonts to all text elements in the overlay
            applyFontsToAllTextViews(overlayView, spaceGrotesk, inter)
            
            // Set up click listener for the scrim to close the overlay
            val overlayScrim = overlayView.findViewById<View>(R.id.overlay_scrim)
            overlayScrim.setOnClickListener {
                hideOverlay()
            }
            
            // Set background based on theme
            val overlayContainer = overlayView.findViewById<LinearLayout>(R.id.overlay_container)
            overlayContainer.background = ContextCompat.getDrawable(
                this, 
                if (isDarkTheme) R.drawable.overlay_rounded_background_dark_bordered else R.drawable.overlay_rounded_background_bordered
            )
            
            // Setup the dropdowns
            setupSummaryOptions()
            setupTranslationOptions()
            setupCommentOptions()
            
            // Set up tab click listeners
            tab1.setOnClickListener {
                updateTabs(0)
            }
            
            tab2.setOnClickListener {
                updateTabs(1)
            }
            
            tab3.setOnClickListener {
                updateTabs(2)
            }
            
            // Get reference to the ScrollView
            val scrollView = overlayView.findViewById<ScrollView>(R.id.contentScrollView)
            
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
                            initialHeight = overlayContainer.height
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            // Calculate new height based on drag (moving up increases height)
                            val dy = initialTouchY - event.rawY
                            val newHeight = initialHeight + dy.toInt()
                            
                            // If height is below minimum threshold, immediately dismiss
                            if (newHeight < minHeight) {
                                hideOverlay()
                                return true
                            } else {
                                overlayContainer.alpha = 1f
                                
                                // Update the overlay container height
                                try {
                                    val params = overlayContainer.layoutParams
                                    params.height = newHeight
                                    overlayContainer.layoutParams = params
                                } catch (e: Exception) {
                                    Log.e("EinsteiniOverlay", "Error updating overlay height", e)
                                }
                            }
                            return true
                        }
                        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                            scrollView.requestDisallowInterceptTouchEvent(false)
                            // If we ended with a height below minimum, hide the overlay
                            if (overlayContainer.height < minHeight) {
                                hideOverlay()
                            }
                            return true
                        }
                        else -> return false
                    }
                }
            })
            
            // Add drag functionality to the tab layout
            val tabLayout = overlayView.findViewById<LinearLayout>(R.id.tabLayout)
            tabLayout.setOnTouchListener(object : View.OnTouchListener {
                private var initialX = 0
                private var initialY = 0
                private var initialTouchX = 0f
                private var initialTouchY = 0f
                
                @SuppressLint("ClickableViewAccessibility")
                override fun onTouch(v: View, event: MotionEvent): Boolean {
                    // Handle touch events for dragging the overlay
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            // Store initial positions
                            initialX = overlayParams?.x ?: 0
                            initialY = overlayParams?.y ?: 0
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            isDraggingOverlay = true
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            if (isDraggingOverlay) {
                                // Calculate new position
                                val newX = initialX + (event.rawX - initialTouchX).toInt()
                                val newY = initialY + (event.rawY - initialTouchY).toInt()
                                
                                // Update overlay position
                                overlayParams?.x = newX
                                overlayParams?.y = newY
                                
                                // Apply the new position
                                try {
                                    if (::overlayView.isInitialized && overlayView.isAttachedToWindow) {
                                        windowManager.updateViewLayout(overlayView, overlayParams)
                                    }
                                } catch (e: Exception) {
                                    Log.e("EinsteiniOverlay", "Error updating overlay position", e)
                                }
                                return true
                            }
                        }
                        MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                            isDraggingOverlay = false
                            return true
                        }
                    }
                    return false
                }
            })
            
            // Make sure to apply the current theme immediately after creating the overlay
            updateOverlayTheme(isDarkTheme)
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error setting up overlay", e)
        }
    }
    
    // Setup summary options dropdown
    private fun setupSummaryOptions() {
        try {
            // Get references to the spinner
            val summarySpinner = overlayView.findViewById<Spinner>(R.id.summary_type_spinner)
            
            // Create an adapter for the spinner
            val summaryTypes = arrayOf("Brief", "Detailed", "Key Points", "Executive", "Technical")
            val adapter = object : ArrayAdapter<String>(
                this,
                android.R.layout.simple_spinner_item,
                summaryTypes
            ) {
                override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    return view
                }
                
                override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getDropDownView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    textView.setPadding(16, 16, 16, 16)
                    return view
                }
            }
            
            // Apply the adapter to the spinner
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            summarySpinner.adapter = adapter
            
            // Set up generate button click listener
            val generateButton = overlayView.findViewById<Button>(R.id.generate_summary_button)
            generateButton.setOnClickListener {
                val selectedSummaryType = summaryTypes[summarySpinner.selectedItemPosition]
                generateSummary(selectedSummaryType)
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error setting up summary options", e)
        }
    }
    
    // Setup translation options dropdown
    private fun setupTranslationOptions() {
        try {
            // Get references to the spinner
            val languageSpinner = overlayView.findViewById<Spinner>(R.id.language_spinner)
            
            // Create an adapter for the spinner
            val languages = arrayOf("English", "Spanish", "French", "German", "Chinese")
            val adapter = object : ArrayAdapter<String>(
                this,
                android.R.layout.simple_spinner_item,
                languages
            ) {
                override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    return view
                }
                
                override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getDropDownView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    textView.setPadding(16, 16, 16, 16)
                    return view
                }
            }
            
            // Apply the adapter to the spinner
            adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            languageSpinner.adapter = adapter
            
            // Set up translate button click listener
            val translateButton = overlayView.findViewById<Button>(R.id.translate_button)
            translateButton.setOnClickListener {
                val selectedLanguage = languages[languageSpinner.selectedItemPosition]
                generateTranslation(selectedLanguage)
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error setting up translation options", e)
        }
    }
    
    // Setup comment options dropdowns
    private fun setupCommentOptions() {
        try {
            // Get references to the spinners
            val commentTypeSpinner = overlayView.findViewById<Spinner>(R.id.comment_type_spinner)
            val commentToneSpinner = overlayView.findViewById<Spinner>(R.id.comment_tone_spinner)
            
            // Create adapters for the spinners
            val commentTypes = arrayOf("General", "Question", "Appreciation", "Critique")
            val typeAdapter = object : ArrayAdapter<String>(
                this,
                android.R.layout.simple_spinner_item,
                commentTypes
            ) {
                override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    return view
                }
                
                override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getDropDownView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    textView.setPadding(16, 16, 16, 16)
                    return view
                }
            }
            
            val commentTones = arrayOf("Professional", "Casual", "Enthusiastic", "Thoughtful")
            val toneAdapter = object : ArrayAdapter<String>(
                this,
                android.R.layout.simple_spinner_item,
                commentTones
            ) {
                override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    return view
                }
                
                override fun getDropDownView(position: Int, convertView: View?, parent: ViewGroup): View {
                    val view = super.getDropDownView(position, convertView, parent)
                    val textView = view.findViewById<TextView>(android.R.id.text1)
                    textView.setTextColor(Color.WHITE)
                    textView.setPadding(16, 16, 16, 16)
                    return view
                }
            }
            
            // Apply the adapters to the spinners
            typeAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            commentTypeSpinner.adapter = typeAdapter
            
            toneAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
            commentToneSpinner.adapter = toneAdapter
            
            // Set up generate button click listener
            val generateButton = overlayView.findViewById<Button>(R.id.generate_comment_button)
            generateButton.setOnClickListener {
                // Get selected values from spinners
                val selectedType = commentTypes[commentTypeSpinner.selectedItemPosition]
                val selectedTone = commentTones[commentToneSpinner.selectedItemPosition]
                
                // Generate comment
                generateComment(selectedType, selectedTone)
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error setting up comment options", e)
        }
    }
    
    // Generate summary based on selected type
    private fun generateSummary(summaryType: String) {
        try {
            // Update the UI to show loading state
            val blockContent = contentViewLinkedIn.findViewById<TextView>(R.id.block_content)
            blockContent?.text = "Generating $summaryType summary..."
            
            // In a real implementation, you would call your API here
            // For now, we'll simulate a delay and then update with sample content
            Handler(Looper.getMainLooper()).postDelayed({
                val summary = when (summaryType) {
                    "Brief" -> "This is a brief summary of the LinkedIn post, highlighting only the most essential points in a concise format."
                    "Detailed" -> "This detailed summary provides an in-depth analysis of the LinkedIn post, covering all major points and supporting details with thorough explanations of concepts mentioned."
                    "Key Points" -> "• First key point from the post\n• Second important takeaway\n• Third significant insight\n• Final notable conclusion"
                    "Executive Summary" -> "Executive overview: This post discusses [topic] with implications for [industry]. The author presents [main argument] supported by [evidence]. Recommended action items include [actions]."
                    "Technical" -> "Technical analysis: The post describes [technical concept] with implementation details for [platform/system]. Key technical specifications include [specs] with performance metrics of [metrics]."
                    else -> "Summary generated based on the LinkedIn post content."
                }
                
                blockContent?.text = summary
                
                // Update the key points section as well
                val keyPointsContent = contentViewLinkedIn.findViewById<TextView>(R.id.key_points_content)
                keyPointsContent?.text = "• Generated based on $summaryType summary type\n• Customized to highlight relevant information\n• Formatted for easy reading and comprehension"
            }, 1500)
                                } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error generating summary", e)
        }
    }
    
    // Generate translation based on selected language
    private fun generateTranslation(language: String) {
        try {
            // Get the original content
            val originalContent = contentViewTwitter.findViewById<TextView>(R.id.original_content)
            val originalText = originalContent?.text?.toString() ?: "No content to translate"
            
            // Update UI to show loading state
            val translationContent = contentViewTwitter.findViewById<TextView>(R.id.translation_content)
            translationContent?.text = "Translating to $language..."
            
            // Update the translation title
            val translationTitle = contentViewTwitter.findViewById<TextView>(R.id.translation_title)
            translationTitle?.text = "Translation ($language)"
            
            // In a real implementation, you would call your translation API here
            // For now, we'll simulate a delay and then update with sample content
            Handler(Looper.getMainLooper()).postDelayed({
                val translation = when (language) {
                    "English" -> "Artificial intelligence is transforming the way we work and interact with technology in our daily lives."
                    "Spanish" -> "La inteligencia artificial está transformando la forma en que trabajamos e interactuamos con la tecnología en nuestra vida cotidiana."
                    "French" -> "L'intelligence artificielle transforme notre façon de travailler et d'interagir avec la technologie dans notre vie quotidienne."
                    "German" -> "Künstliche Intelligenz verändert die Art und Weise, wie wir arbeiten und mit Technologie in unserem Alltag interagieren."
                    "Chinese" -> "人工智能正在改变我们工作和与日常生活中的技术交互的方式。"
                    "Japanese" -> "人工知能は、私たちの日常生活で働き、テクノロジーと対話する方法を変革しています。"
                    "Russian" -> "Искусственный интеллект меняет то, как мы работаем и взаимодействуем с технологиями в нашей повседневной жизни."
                    "Arabic" -> "الذكاء الاصطناعي يغير الطريقة التي نعمل بها ونتفاعل مع التكنولوجيا في حياتنا اليومية."
                    "Portuguese" -> "A inteligência artificial está transformando a forma como trabalhamos e interagimos com a tecnologia em nossa vida diária."
                    "Italian" -> "L'intelligenza artificiale sta trasformando il modo in cui lavoriamo e interagiamo con la tecnologia nella nostra vita quotidiana."
                    else -> "Translation not available for $language"
                }
                
                translationContent?.text = translation
            }, 1500)
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error generating translation", e)
        }
    }
    
    // Generate comment based on selected type and tone
    private fun generateComment(commentType: String, commentTone: String) {
        try {
            // Update UI to show loading state
            val professionalContent = contentViewComment.findViewById<TextView>(R.id.professional_content)
            val questionContent = contentViewComment.findViewById<TextView>(R.id.question_content)
            val thoughtfulContent = contentViewComment.findViewById<TextView>(R.id.thoughtful_content)
            
            professionalContent?.text = "Generating $commentType comment with $commentTone tone..."
            questionContent?.text = "Generating alternative comment options..."
            thoughtfulContent?.text = "Generating additional comment variations..."
            
            // In a real implementation, you would call your API here
            // For now, we'll simulate a delay and then update with sample content
            Handler(Looper.getMainLooper()).postDelayed({
                // Generate different comments based on type and tone
                val professionalComment = "This is a $commentType comment with a $commentTone tone. Thank you for sharing these insights! I've been exploring similar implementation strategies in my work."
                
                val questionComment = when (commentType) {
                    "Question" -> "I'm curious to learn more about this topic. Could you elaborate on how you implemented these strategies in your specific context?"
                    "Appreciation" -> "I really appreciate you sharing this valuable information! What inspired you to focus on this particular approach?"
                    "Critique" -> "Interesting perspective, though I wonder if you've considered alternative approaches? What are your thoughts on [alternative method]?"
                    "Addition" -> "Great points! I'd also add that [additional insight] can further enhance these strategies. Have you explored that aspect as well?"
                    else -> "This is very interesting! Could you share more about specific tools your team has found most effective?"
                }
                
                val thoughtfulComment = when (commentTone) {
                    "Professional" -> "From a professional standpoint, these insights align with industry best practices. I've observed similar patterns in my organization's implementation."
                    "Casual" -> "Love this! Been trying something similar and it's definitely a game-changer. Anyone else seeing these kinds of results?"
                    "Enthusiastic" -> "Wow! This is EXACTLY what our team needed! Can't wait to implement these amazing strategies right away! Thank you so much for sharing!"
                    "Academic" -> "The methodological approach presented here correlates with recent findings in the literature. Further research might explore the causal mechanisms underlying these observations."
                    else -> "While the insights are valuable, it's also important to consider the broader implications. The balance between efficiency and human factors remains an important consideration."
                }
                
                // Update the UI with the generated comments
                professionalContent?.text = professionalComment
                questionContent?.text = questionComment
                thoughtfulContent?.text = thoughtfulComment
            }, 1500)
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error generating comment", e)
        }
    }
    
    // Update overlay appearance based on current theme
    private fun updateOverlayTheme(isDark: Boolean) {
        if (!::overlayView.isInitialized) {
            Log.d(TAG, "Overlay view not initialized yet, skipping theme update")
            return
        }
        
        Log.d(TAG, "Updating overlay theme. Dark mode: $isDark")
        
        try {
            // Apply changes in UI-thread safe way
            overlayView.post {
                try {
                    // Get the main overlay container
                    val overlayContainer = overlayView.findViewById<LinearLayout>(R.id.overlay_container)
                    
                    // Set main background with dotted borders
                    if (isDark) {
                        overlayContainer?.setBackgroundResource(R.drawable.overlay_rounded_background_dark_bordered)
                    } else {
                        overlayContainer?.setBackgroundResource(R.drawable.overlay_rounded_background_bordered)
                    }
                    
                    // Update tab layout background
                    val tabLayout = overlayView.findViewById<LinearLayout>(R.id.tabLayout)
                    tabLayout?.setBackgroundColor(Color.parseColor(if (isDark) "#121827" else "#FFFFFF"))
                    
                    // Update divider color
                    val divider = overlayView.findViewById<View>(R.id.divider)
                    divider?.setBackgroundColor(Color.parseColor(if (isDark) "#1A2235" else "#EEEEEE"))
                    
                    // Update tab text colors
                    val tab1 = overlayView.findViewById<TextView>(R.id.tab1)
                    val tab2 = overlayView.findViewById<TextView>(R.id.tab2)
                    val tab3 = overlayView.findViewById<TextView>(R.id.tab3)
                    
                    val activeTabColor = ContextCompat.getColor(this, R.color.purple_accent)
                    val inactiveTabColor = if (isDark) 
                        ContextCompat.getColor(this, R.color.inactive_tab_dark) 
                    else 
                        ContextCompat.getColor(this, R.color.inactive_tab_light)
                    
                    tab1?.setTextColor(activeTabColor)
                    tab2?.setTextColor(inactiveTabColor)
                    tab3?.setTextColor(inactiveTabColor)
                    
                    // Update all content sections
                    updateContentSectionTheme(R.id.contentViewLinkedIn)
                    updateContentSectionTheme(R.id.contentViewTwitter)
                    updateContentSectionTheme(R.id.contentViewComment)
                    
                    Log.d(TAG, "Overlay theme updated successfully")
                } catch (e: Exception) {
                    Log.e(TAG, "Error updating overlay theme elements", e)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error updating overlay theme", e)
        }
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
        Log.d("EinsteiniOverlay", "Toggling overlay visibility. Current state: isOverlayVisible=$isOverlayVisible")
        
        if (!isOverlayVisible) {
            // Hide bubble first
            removeBubbleIfExists()
            
            // Then show overlay
            showOverlayWindow()
        } else {
            // Hide overlay (which will show bubble)
            hideOverlay()
        }
    }
    
    private fun showOverlayWindow() {
        if (isOverlayVisible) return
        
        try {
            // Hide bubble first
            removeBubbleIfExists()
            
            // Make sure overlay view is initialized
            if (!::overlayView.isInitialized) {
                setupOverlay()
            }
            
            // Calculate initial height (full screen for the container with the overlay at the bottom)
            val screenHeight = resources.displayMetrics.heightPixels
            val overlayHeight = (screenHeight * 0.4).toInt()
            
            // Position the overlay to fill the entire screen
            if (overlayParams == null) {
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                
                overlayParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.MATCH_PARENT,
                    WindowManager.LayoutParams.MATCH_PARENT,
                    type,
                    WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    x = 0
                    y = 0
                }
            } else {
                // Update existing params
                overlayParams?.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                                      WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                overlayParams?.gravity = Gravity.TOP or Gravity.START
                overlayParams?.width = WindowManager.LayoutParams.MATCH_PARENT
                overlayParams?.height = WindowManager.LayoutParams.MATCH_PARENT
                overlayParams?.x = 0
                overlayParams?.y = 0
            }
            
            // Get the overlay container and set its height
            val overlayContainer = overlayView.findViewById<LinearLayout>(R.id.overlay_container)
            val params = overlayContainer?.layoutParams
            params?.height = overlayHeight
            overlayContainer?.layoutParams = params
            
            try {
                if (overlayView.parent == null) {
                    windowManager.addView(overlayView, overlayParams)
                }
                overlayView.visibility = View.VISIBLE
                
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
    
    private fun hideOverlay() {
        if (!isOverlayVisible) return
        
        Log.d("EinsteiniOverlay", "Hiding overlay")
        
        try {
            // First hide the overlay window
            if (::overlayView.isInitialized && overlayView.isAttachedToWindow) {
                        windowManager.removeView(overlayView)
                    }
            
            // Hide the close button
            if (::closeButtonView.isInitialized && closeButtonView.isAttachedToWindow) {
                windowManager.removeView(closeButtonView)
            }
            
            isOverlayVisible = false
            
            // Show the bubble with a delay to ensure clean transition
            Handler(Looper.getMainLooper()).postDelayed({
                showBubble()
            }, 200)
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error hiding overlay", e)
            
            // Try direct approach as fallback
            try {
                if (::overlayView.isInitialized && overlayView.isAttachedToWindow) {
                    windowManager.removeView(overlayView)
                }
                
                if (::closeButtonView.isInitialized && closeButtonView.isAttachedToWindow) {
                    windowManager.removeView(closeButtonView)
                }
                
                isOverlayVisible = false
                showBubble()
            } catch (e2: Exception) {
                Log.e("EinsteiniOverlay", "Error in fallback overlay removal", e2)
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
        
        try {
            // Animate scale
            val scaleAnimator = ValueAnimator.ofFloat(0.5f, 1.0f)
            scaleAnimator.duration = 300
            scaleAnimator.interpolator = OvershootInterpolator()
            
            scaleAnimator.addUpdateListener { animation ->
                val scale = animation.animatedValue as Float
                bubbleView.scaleX = scale
                bubbleView.scaleY = scale
            }
            
            scaleAnimator.start()
            
            // Animate alpha
            bubbleView.alpha = 0f
            bubbleView.animate()
                .alpha(1f)
                .setDuration(200)
                .start()
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error animating entry", e)
        }
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
        return isDarkTheme
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
        updateOverlayTheme(isDarkTheme)
    }

    /**
     * Show generated content in the overlay
     */
    fun showGeneratedContent(content: String, type: String) {
        try {
            Log.d(TAG, "Showing generated content of type: $type with content: $content")
            val contentTextView = overlayView.findViewById<TextView>(R.id.generated_content)
            val contentTypeTextView = overlayView.findViewById<TextView>(R.id.content_type)
            
            if (contentTextView != null && contentTypeTextView != null) {
                // Update on UI thread
                contentTextView.post {
                    contentTextView.text = content
                    
                    // Set the content type label based on the type
                    val contentTypeLabel = when(type) {
                        "comment" -> "LinkedIn Comment"
                        "personalized_comment" -> "Personalized Comment"
                        "post" -> "LinkedIn Post"
                        "about" -> "About Section"
                        "connection_note" -> "Connection Note"
                        "translation" -> "Translation"
                        "grammar_correction" -> "Grammar Correction"
                        else -> "Generated Content"
                    }
                    
                    contentTypeTextView.text = contentTypeLabel
                    
                    // Make sure the content is visible
                    val contentContainer = overlayView.findViewById<CardView>(R.id.content_container)
                    if (contentContainer != null) {
                        contentContainer.visibility = View.VISIBLE
                    }
                    
                    // Ensure the overlay is expanded
                    if (!isOverlayVisible) {
                        expandOverlay()
                    }
                    
                    // Notify Flutter that content is ready
                    methodChannel?.invokeMethod("onGeneratedContentReady", content)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error showing generated content", e)
        }
    }
    
    /**
     * Handle action from Flutter
     */
    fun handleAction(action: String, data: org.json.JSONObject) {
        try {
            Log.d(TAG, "Handling action: $action")
            
            when (action) {
                "copy_content" -> {
                    // Copy content to clipboard
                    val clipboardManager = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                    val content = data.optString("content", "")
                    val clipData = android.content.ClipData.newPlainText("Einsteini Generated Content", content)
                    clipboardManager.setPrimaryClip(clipData)
                    
                    // Show toast on UI thread
                    overlayView.post {
                        android.widget.Toast.makeText(applicationContext, "Copied to clipboard", android.widget.Toast.LENGTH_SHORT).show()
                    }
                }
                "clear_content" -> {
                    // Clear generated content
                    val contentTextView = overlayView.findViewById<TextView>(R.id.generated_content)
                    val contentContainer = overlayView.findViewById<CardView>(R.id.content_container)
                    
                    if (contentTextView != null && contentContainer != null) {
                        contentTextView.post {
                            contentTextView.text = ""
                            contentContainer.visibility = View.GONE
                        }
                    }
                }
                "expand_overlay" -> {
                    // Expand the overlay
                    if (!isOverlayVisible) {
                        expandOverlay()
                    }
                }
                "collapse_overlay" -> {
                    // Collapse the overlay
                    if (isOverlayVisible) {
                        collapseOverlay()
                    }
                }
                else -> {
                    Log.w(TAG, "Unknown action: $action")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling action", e)
        }
    }
    
    /**
     * Expand the overlay to show content
     */
    fun expandOverlay() {
        if (isOverlayVisible) return
        showOverlayWindow()
    }
    
    /**
     * Collapse the overlay to hide content
     */
    fun collapseOverlay() {
        if (!isOverlayVisible) return
        hideOverlay()
    }
    
    /**
     * Update theme of the overlay
     */
    fun updateTheme(newIsDarkTheme: Boolean): Boolean {
        try {
            // Store the new theme value
            this.isDarkTheme = newIsDarkTheme
            Log.d(TAG, "Setting service theme state to isDarkTheme=$newIsDarkTheme")
            
            // Update UI components with the new theme
            updateBubbleTheme()
            updateOverlayTheme(newIsDarkTheme)
            
            return true
        } catch (e: Exception) {
            Log.e(TAG, "Error updating theme", e)
            return false
        }
    }

    // Process LinkedIn URL and update the overlay content
    private fun processLinkedInUrl(url: String) {
        // Make sure we're on a background thread
        Thread {
            try {
                Log.d("EinsteiniOverlay", "Starting to scrape LinkedIn URL: $url")
                
                // Call the backend API to scrape the LinkedIn post
                val scrapedData = scrapeLinkedInPost(url)
                
                // Update the UI on the main thread
                Handler(Looper.getMainLooper()).post {
                    try {
                        updateOverlayWithScrapedData(scrapedData)
                        
                        // Send the scraped content to Flutter
                        sendScrapedContentToFlutter(scrapedData)
                    } catch (e: Exception) {
                        Log.e("EinsteiniOverlay", "Error updating overlay with scraped data", e)
                    }
                }
            } catch (e: Exception) {
                Log.e("EinsteiniOverlay", "Error processing LinkedIn URL", e)
                
                // Update the UI with an error message
                Handler(Looper.getMainLooper()).post {
                    try {
                        showErrorInOverlay("Failed to process LinkedIn content: ${e.message}")
                    } catch (e: Exception) {
                        Log.e("EinsteiniOverlay", "Error showing error in overlay", e)
                    }
                }
            }
        }.start()
    }
    
    // Send scraped content to Flutter
    private fun sendScrapedContentToFlutter(content: Map<String, Any>) {
        try {
            // Make sure we have a valid method channel
            if (methodChannel != null) {
                methodChannel?.invokeMethod("onContentScraped", content)
            } else {
                Log.e("EinsteiniOverlay", "Method channel is null, can't send scraped content to Flutter")
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error sending scraped content to Flutter", e)
        }
    }
    
    // Scrape LinkedIn post using the backend API
    private fun scrapeLinkedInPost(url: String): Map<String, Any> {
        try {
            Log.d("EinsteiniOverlay", "Scraping LinkedIn URL: $url")
            
            // Create the API URL
            val apiUrl = "https://backend.einsteini.ai/scrape?url=${Uri.encode(url)}"
            
            // Make the HTTP request
            val connection = URL(apiUrl).openConnection() as HttpURLConnection
            connection.requestMethod = "GET"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("Cache-Control", "no-cache")
            connection.connectTimeout = 15000
            connection.readTimeout = 15000
            
            // Get the response
            val responseCode = connection.responseCode
            Log.d("EinsteiniOverlay", "Scrape response code: $responseCode")
            
            if (responseCode == HttpURLConnection.HTTP_OK) {
                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                val response = StringBuilder()
                var line: String?
                
                while (reader.readLine().also { line = it } != null) {
                    response.append(line)
                }
                
                reader.close()
                Log.d("EinsteiniOverlay", "Scrape response: ${response.substring(0, Math.min(100, response.length))}...")
                
                // Parse the JSON response
                val jsonResponse = JSONObject(response.toString())
                
                // Extract the data
                val result = mutableMapOf<String, Any>()
                
                // Handle both string and object responses
                if (jsonResponse.has("content")) {
                    result["content"] = jsonResponse.getString("content")
                } else {
                    result["content"] = response.toString()
                }
                
                // Extract other fields if available
                if (jsonResponse.has("author")) {
                    result["author"] = jsonResponse.getString("author")
                } else {
                    result["author"] = "Unknown author"
                }
                
                if (jsonResponse.has("date")) {
                    result["date"] = jsonResponse.getString("date")
                } else {
                    result["date"] = "Unknown date"
                }
                
                return result
            } else {
                Log.e("EinsteiniOverlay", "Error scraping LinkedIn post: $responseCode")
                return mapOf(
                    "content" to "Error: Failed to scrape LinkedIn post (HTTP $responseCode)",
                    "author" to "Error",
                    "date" to "Unknown date"
                )
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Exception while scraping LinkedIn post", e)
            return mapOf(
                "content" to "Error: ${e.message}",
                "author" to "Error",
                "date" to "Unknown date"
            )
        }
    }
    
    // Update the overlay with the scraped data
    private fun updateOverlayWithScrapedData(scrapedData: Map<String, Any>) {
        if (!::overlayView.isInitialized) {
            Log.e("EinsteiniOverlay", "Overlay view not initialized")
            return
        }
        
        try {
            // Get the content views
            val contentViewLinkedIn = overlayView.findViewById<LinearLayout>(R.id.contentViewLinkedIn)
            val contentViewTwitter = overlayView.findViewById<LinearLayout>(R.id.contentViewTwitter)
            val contentViewComment = overlayView.findViewById<LinearLayout>(R.id.contentViewComment)
            
            // Get the tab views
            val tab1 = overlayView.findViewById<TextView>(R.id.tab1)
            val tab2 = overlayView.findViewById<TextView>(R.id.tab2)
            val tab3 = overlayView.findViewById<TextView>(R.id.tab3)
            
            // Set the active tab
            tab1.setTextColor(Color.parseColor("#BD79FF"))
            tab2.setTextColor(Color.parseColor("#B4B7BD"))
            tab3.setTextColor(Color.parseColor("#B4B7BD"))
            
            // Show the LinkedIn content view
            contentViewLinkedIn.visibility = View.VISIBLE
            contentViewTwitter.visibility = View.GONE
            contentViewComment.visibility = View.GONE
            
            // Get the content blocks
            val contentBlocks = contentViewLinkedIn.children.filterIsInstance<LinearLayout>().toList()
            
            // Update the summary block
            if (contentBlocks.isNotEmpty()) {
                val summaryBlock = contentBlocks[0]
                // Find the TextViews using findViewById
                val titleTextView = summaryBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = summaryBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Summary"
                    
                    val content = scrapedData["content"] as? String ?: "No content found"
                    contentTextView.text = content
                }
            }
            
            // Update the key points block
            if (contentBlocks.size > 1) {
                val keyPointsBlock = contentBlocks[1]
                // Find the TextViews using findViewById
                val titleTextView = keyPointsBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = keyPointsBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Post Details"
                    
                    val author = scrapedData["author"] as? String ?: "Unknown author"
                    val date = scrapedData["date"] as? String ?: "Unknown date"
                    contentTextView.text = "Author: $author\nDate: $date"
                }
            }
            
            // Set up tab click listeners
            tab1.setOnClickListener {
                updateTabs(0)
            }
            
            tab2.setOnClickListener {
                updateTabs(1)
            }
            
            tab3.setOnClickListener {
                updateTabs(2)
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error updating overlay with scraped data", e)
        }
    }
    
    // Show an error message in the overlay
    private fun showErrorInOverlay(errorMessage: String) {
        if (!::overlayView.isInitialized) {
            Log.e("EinsteiniOverlay", "Overlay view not initialized")
            return
        }
        
        try {
            // Get the content view
            val contentViewLinkedIn = overlayView.findViewById<LinearLayout>(R.id.contentViewLinkedIn)
            
            // Make sure it's visible
            contentViewLinkedIn.visibility = View.VISIBLE
            
            // Get the content blocks
            val contentBlocks = contentViewLinkedIn.children.filterIsInstance<LinearLayout>().toList()
            
            // Update the summary block with the error message
            if (contentBlocks.isNotEmpty()) {
                val summaryBlock = contentBlocks[0]
                // Find the TextViews using findViewById
                val titleTextView = summaryBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = summaryBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Error"
                    contentTextView.text = errorMessage
                }
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error showing error in overlay", e)
        }
    }

    // Show translated content in the overlay
    private fun showTranslatedContent(original: String, translation: String, language: String) {
        if (!::overlayView.isInitialized) {
            Log.e("EinsteiniOverlay", "Overlay view not initialized")
            return
        }
        
        try {
            // Set the active tab using the updateTabs function
            updateTabs(1)
            
            // Get the content blocks
            val contentBlocks = contentViewTwitter.children.filterIsInstance<LinearLayout>().toList()
            
            // Update the translation block
            if (contentBlocks.isNotEmpty()) {
                val translationBlock = contentBlocks[0]
                val titleTextView = translationBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = translationBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Translation"
                    contentTextView.text = "Here is the translated content from the original post."
                }
            }
            
            // Update the original block
            if (contentBlocks.size > 1) {
                val originalBlock = contentBlocks[1]
                val titleTextView = originalBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = originalBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Original"
                    contentTextView.text = original
                }
            }
            
            // Update the translation block
            if (contentBlocks.size > 2) {
                val translationBlock = contentBlocks[2]
                val titleTextView = translationBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = translationBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Translation ($language)"
                    contentTextView.text = translation
                }
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error showing translated content", e)
        }
    }
    
    // Show comment options in the overlay
    private fun showCommentOptions(professional: String, question: String, thoughtful: String) {
        if (!::overlayView.isInitialized) {
            Log.e("EinsteiniOverlay", "Overlay view not initialized")
            return
        }
        
        try {
            // Set the active tab using the updateTabs function
            updateTabs(2)
            
            // Get the content blocks
            val contentBlocks = contentViewComment.children.filterIsInstance<LinearLayout>().toList()
            
            // Update the comment ideas block
            if (contentBlocks.isNotEmpty()) {
                val commentIdeasBlock = contentBlocks[0]
                val titleTextView = commentIdeasBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = commentIdeasBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Comment Ideas"
                    contentTextView.text = "Here are some suggested comments you could post in response to this content."
                }
            }
            
            // Update the professional comment block
            if (contentBlocks.size > 1) {
                val professionalBlock = contentBlocks[1]
                val titleTextView = professionalBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = professionalBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Professional"
                    contentTextView.text = professional
                }
            }
            
            // Update the question comment block
            if (contentBlocks.size > 2) {
                val questionBlock = contentBlocks[2]
                val titleTextView = questionBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = questionBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Question"
                    contentTextView.text = question
                }
            }
            
            // Update the thoughtful comment block
            if (contentBlocks.size > 3) {
                val thoughtfulBlock = contentBlocks[3]
                val titleTextView = thoughtfulBlock.findViewById<TextView>(R.id.block_title)
                val contentTextView = thoughtfulBlock.findViewById<TextView>(R.id.block_content)
                
                if (titleTextView != null && contentTextView != null) {
                    titleTextView.text = "Thoughtful"
                    contentTextView.text = thoughtful
                }
            }
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error showing comment options", e)
        }
    }

    // Show the bubble when the overlay is collapsed
    private fun showBubble() {
        Log.d("EinsteiniOverlay", "showBubble called - direct implementation")
        
        // Don't do anything if bubble is already shown
        if (isBubbleShown) {
            Log.d("EinsteiniOverlay", "Bubble already shown, returning")
            return
        }
        
        try {
            // Remove any existing bubble first to be safe
            removeBubbleIfExists()
            
            // Create the bubble view if not initialized
            if (!::bubbleView.isInitialized) {
                Log.d("EinsteiniOverlay", "Initializing bubble view")
                setupBubble()
            }
            
            // Set position at right edge of screen
                    bubbleParams?.x = screenWidth - bubbleSize - 16
                    bubbleParams?.y = 100
                    
            // Add bubble to window manager
            Log.d("EinsteiniOverlay", "Adding bubble to window manager")
            windowManager.addView(bubbleView, bubbleParams)
            isBubbleShown = true
            
            // Make sure it's visible
            bubbleView.visibility = View.VISIBLE
            
            // Animate entry
            bubbleView.alpha = 0f
            bubbleView.scaleX = 0.5f
            bubbleView.scaleY = 0.5f
            
            bubbleView.animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .setDuration(300)
                .setInterpolator(OvershootInterpolator())
                .start()
                
            Log.d("EinsteiniOverlay", "Bubble added and animated")
        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error showing bubble", e)
            
            // Try again after a delay as last resort
                    Handler(Looper.getMainLooper()).postDelayed({
                        try {
                    removeBubbleIfExists()
                    setupBubble()
                            windowManager.addView(bubbleView, bubbleParams)
                    isBubbleShown = true
                    Log.d("EinsteiniOverlay", "Bubble added on second attempt")
                } catch (e2: Exception) {
                    Log.e("EinsteiniOverlay", "Failed to add bubble on second attempt", e2)
                }
            }, 500)
        }
    }
    
    // Helper method to safely remove bubble if it exists
    private fun removeBubbleIfExists() {
        try {
            if (::bubbleView.isInitialized && bubbleView.parent != null) {
                windowManager.removeView(bubbleView)
                isBubbleShown = false
                Log.d("EinsteiniOverlay", "Removed existing bubble")
            }
                        } catch (e: Exception) {
            Log.e("EinsteiniOverlay", "Error removing existing bubble", e)
        }
    }

    // Add this new function
    private fun applyFontsToAllTextViews(view: View, titleFont: Typeface?, bodyFont: Typeface?) {
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                applyFontsToAllTextViews(view.getChildAt(i), titleFont, bodyFont)
            }
        } else if (view is TextView) {
            // Check if this is a title or body text based on text size or style
            if (view.textSize >= 18 * resources.displayMetrics.density || 
                view.text.toString().lowercase().contains("summary") ||
                view.text.toString().lowercase().contains("key points") ||
                view.text.toString().lowercase().contains("implementation") ||
                view.text.toString().lowercase().contains("results") ||
                view.text.toString().lowercase().contains("translation") ||
                view.text.toString().lowercase().contains("original") ||
                view.text.toString().lowercase().contains("comment")) {
                // Apply title font
                view.typeface = titleFont
                view.setTextColor(Color.parseColor("#BD79FF"))
            } else {
                // Apply body font
                view.typeface = bodyFont
                view.setTextColor(Color.WHITE)
            }
        }
    }

    private fun updateTabs(activeTabIndex: Int) {
        // Set the appropriate colors based on theme
        val activeTabColor = ContextCompat.getColor(this, R.color.purple_accent)
        val inactiveTabColor = if (isDarkTheme) 
            ContextCompat.getColor(this, R.color.inactive_tab_dark) 
        else 
            ContextCompat.getColor(this, R.color.inactive_tab_light)
            
        // Reset tab styles
        tab1.setTextColor(inactiveTabColor)
        tab2.setTextColor(inactiveTabColor)
        tab3.setTextColor(inactiveTabColor)
        tab1.textSize = 14f
        tab2.textSize = 14f
        tab3.textSize = 14f
        
        // Set active tab
        when (activeTabIndex) {
            0 -> {
                tab1.setTextColor(activeTabColor)
                tab1.textSize = 16f
                contentViewLinkedIn.visibility = View.VISIBLE
                contentViewTwitter.visibility = View.GONE
                contentViewComment.visibility = View.GONE
            }
            1 -> {
                tab2.setTextColor(activeTabColor)
                tab2.textSize = 16f
                contentViewLinkedIn.visibility = View.GONE
                contentViewTwitter.visibility = View.VISIBLE
                contentViewComment.visibility = View.GONE
            }
            2 -> {
                tab3.setTextColor(activeTabColor)
                tab3.textSize = 16f
                contentViewLinkedIn.visibility = View.GONE
                contentViewTwitter.visibility = View.GONE
                contentViewComment.visibility = View.VISIBLE
            }
        }
        
        // Reset scroll position when changing tabs
        overlayView.findViewById<ScrollView>(R.id.contentScrollView)?.scrollTo(0, 0)
    }
} 
