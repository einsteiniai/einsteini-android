package com.example.einsteiniapp

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import kotlinx.coroutines.*
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.einsteini.ai/settings"
    private val SCRAPER_CHANNEL = "com.einsteini.ai/scraper"
    private val OVERLAY_CHANNEL = "com.einsteini.ai/overlay"
    private val executor = Executors.newFixedThreadPool(2)

    // Helper method to check if dark mode is enabled
    private fun isDarkModeEnabled(): Boolean {
        return when (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) {
            Configuration.UI_MODE_NIGHT_YES -> true
            else -> false
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Settings channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSystemSettings" -> {
                    val action = call.argument<String>("action")
                    if (action != null) {
                        openSystemSettings(action)
                        result.success(true)
                    } else {
                        result.error("MISSING_PARAM", "Missing action parameter", null)
                    }
                }
                "checkOverlayPermission" -> {
                    result.success(checkOverlayPermission())
                }
                "checkAccessibilityPermission" -> {
                    result.success(isAccessibilityServiceEnabled())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Overlay service channel
        val overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)
        EinsteiniOverlayService.setMethodChannel(overlayChannel)
        overlayChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startOverlayService" -> {
                    Log.d("EinsteiniApp", "Received request to start overlay service")
                    
                    if (!checkOverlayPermission()) {
                        Log.e("EinsteiniApp", "Overlay permission denied")
                        result.error("PERMISSION_DENIED", "Overlay permission not granted", null)
                        return@setMethodCallHandler
                    }
                    
                    try {
                        // Check if service is already running
                        if (EinsteiniOverlayService.isRunning()) {
                            Log.d("EinsteiniApp", "Service already running, returning success")
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        
                        // Create explicit intent
                        val intent = Intent(applicationContext, EinsteiniOverlayService::class.java)
                        intent.action = "START_OVERLAY"
                        
                        Log.d("EinsteiniApp", "Starting overlay service")
                        
                        // Check for the foreground service data sync permission on Android 14+
                        val hasForegroundPermission = if (Build.VERSION.SDK_INT >= 34) {
                            val permissionName = android.Manifest.permission.FOREGROUND_SERVICE_DATA_SYNC
                            checkSelfPermission(permissionName) == android.content.pm.PackageManager.PERMISSION_GRANTED
                        } else {
                            true
                        }
                        
                        Log.d("EinsteiniApp", "Has foreground service permission: $hasForegroundPermission")
                        
                        // Start service based on Android version
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Log.d("EinsteiniApp", "Starting as foreground service (Android O+)")
                            applicationContext.startForegroundService(intent)
                        } else {
                            Log.d("EinsteiniApp", "Starting as regular service")
                            applicationContext.startService(intent)
                        }
                        
                        // Brief delay to allow service to start
                        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                            val isRunning = EinsteiniOverlayService.isRunning()
                            Log.d("EinsteiniApp", "Service running after delay: $isRunning")
                            result.success(isRunning)
                        }, 1000) // Increased delay for better reliability
                    } catch (e: Exception) {
                        Log.e("EinsteiniApp", "Error starting service", e)
                        e.printStackTrace()
                        result.error("SERVICE_ERROR", "Failed to start overlay service: ${e.message}", null)
                    }
                }
                "updateOverlayTheme" -> {
                    try {
                        // Send a broadcast to update theme in the service
                        val intent = Intent("com.example.einsteiniapp.THEME_CHANGED")
                        sendBroadcast(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("EinsteiniApp", "Error updating theme", e)
                        result.error("THEME_ERROR", "Failed to update theme: ${e.message}", null)
                    }
                }
                "stopOverlayService" -> {
                    try {
                        val intent = Intent(this, EinsteiniOverlayService::class.java)
                        stopService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        e.printStackTrace()
                        result.error("SERVICE_ERROR", "Failed to stop overlay service: ${e.message}", null)
                    }
                }
                "isOverlayServiceRunning" -> {
                    result.success(EinsteiniOverlayService.isRunning())
                }
                "resizeExpandedView" -> {
                    val width = call.argument<Int>("width") ?: -1
                    val height = call.argument<Int>("height") ?: -1
                    
                    if (width > 0 && height > 0) {
                        val service = EinsteiniOverlayService.getInstance()
                        try {
                            service?.resizeExpandedView(width, height)
                            result.success(true)
                        } catch (e: Exception) {
                            e.printStackTrace()
                            result.error("RESIZE_ERROR", "Failed to resize view: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_DIMENSIONS", "Width and height must be greater than 0", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Scraper channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCRAPER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scrapeLinkedInPost" -> {
                    val url = call.argument<String>("url")
                    if (url != null) {
                        // Run scraping in background thread
                        executor.execute {
                            try {
                                val scrapedData = scrapeLinkedInPost(url)
                                runOnUiThread {
                                    result.success(scrapedData)
                                }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("SCRAPE_ERROR", "Failed to scrape LinkedIn post: ${e.message}", null)
                                }
                            }
                        }
                    } else {
                        result.error("MISSING_PARAM", "Missing URL parameter", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scrapeLinkedInPost(url: String): Map<String, Any> {
        try {
            // Set user agent to mimic a browser
            val userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
            
            // Connect to the URL with a timeout
            val document = Jsoup.connect(url)
                .userAgent(userAgent)
                .timeout(10000)
                .followRedirects(true)  // Follow redirects if any
                .get()
            
            // Extract post content
            val rawContent = extractPostContent(document)
            val content = cleanupContent(rawContent)
            
            // Extract author info
            val author = extractAuthorName(document)
            
            // Extract post date
            val date = extractPostDate(document)
            
            // Extract engagement metrics
            val engagementData = extractEngagementMetrics(document)
            
            // Extract images
            val images = extractImages(document)
            
            // Extract special content if available
            val specialContent = extractSpecialContent(document)
            
            // Extract comments
            val comments = extractComments(document)
            
            // Merge special content with regular content if available
            val finalContent = if (specialContent.isNotEmpty() && content.length < 100) {
                "$content\n\n$specialContent"
            } else {
                content
            }
            
            // Return the scraped data
            return mapOf(
                "content" to finalContent,
                "author" to author,
                "date" to date,
                "likes" to (engagementData["likes"] ?: 0),
                "comments" to (engagementData["comments"] ?: 0),
                "images" to images,
                "commentsList" to comments
            )
        } catch (e: Exception) {
            // If scraping fails, return some information about the failure
            return mapOf(
                "content" to "Failed to scrape LinkedIn post. LinkedIn may be blocking scraping attempts. Error: ${e.message}",
                "author" to "Unknown",
                "date" to "Unknown",
                "likes" to 0,
                "comments" to 0,
                "images" to listOf<String>(),
                "commentsList" to listOf<Map<String, String>>()
            )
        }
    }
    
    private fun extractPostContent(document: Document): String {
        // Try different selectors that might contain the post content
        val contentSelectors = listOf(
            ".feed-shared-update-v2__description",
            ".feed-shared-text",
            ".feed-shared-text__text-view",
            ".share-update-card__update-text",
            ".update-components-text",
            ".feed-shared-inline-show-more-text"
        )
        
        for (selector in contentSelectors) {
            val element = document.select(selector).first()
            if (element != null && element.text().isNotEmpty()) {
                return element.text()
            }
        }
        
        // If we couldn't find the content with specific selectors, try a more targeted approach
        try {
            // Look for article content
            val articleContent = document.select("article p").text()
            if (articleContent.isNotEmpty() && articleContent.length > 30) {
                return articleContent
            }
            
            // Look for post content in specific divs that might contain it
            val postDiv = document.select("div[data-id]").first()
            if (postDiv != null) {
                val postText = postDiv.text()
                // Filter out common UI text that's not part of the post
                if (!postText.contains("Skip to main content") && 
                    !postText.contains("Agree & Join LinkedIn") &&
                    postText.length > 30) {
                    return postText
                }
            }
            
            // Try to find the main post heading and content
            val postTitle = document.select("h1, h2, h3").first()?.text() ?: ""
            val mainContent = document.select("div.scaffold-layout__main p").text()
            
            if (postTitle.isNotEmpty() && mainContent.isNotEmpty()) {
                return "$postTitle\n\n$mainContent"
            }
        } catch (e: Exception) {
            // Ignore errors in fallback methods
        }
        
        // Fallback: try to extract the actual post content by removing common UI elements
        val bodyText = document.body().text()
        if (bodyText.isNotEmpty()) {
            // Split by common UI separators and take the most likely post content part
            val parts = bodyText.split(
                "Agree & Join LinkedIn", 
                "Skip to main content", 
                "Sign in", 
                "Join now",
                "Report this post"
            )
            
            // Find the part that's most likely to be the post content
            for (part in parts) {
                val trimmed = part.trim()
                // Look for parts that have reasonable length and don't start with UI text
                if (trimmed.length > 50 && 
                    !trimmed.startsWith("LinkedIn") && 
                    !trimmed.startsWith("People") &&
                    !trimmed.startsWith("Learning") &&
                    !trimmed.startsWith("Jobs") &&
                    !trimmed.startsWith("Articles")) {
                    
                    // Limit length to avoid returning the entire page
                    return trimmed.substring(0, minOf(1000, trimmed.length))
                }
            }
            
            // If we couldn't find a good part, just return a limited portion
            return bodyText.substring(0, minOf(500, bodyText.length))
        }
        
        return "Could not extract post content. LinkedIn may be blocking scraping attempts."
    }
    
    private fun extractAuthorName(document: Document): String {
        // Try different selectors that might contain the author name
        val authorSelectors = listOf(
            ".feed-shared-actor__name",
            ".update-components-actor__name",
            ".share-update-card__actor-name",
            "span.feed-shared-actor__title",
            ".base-main-card__title", 
            ".share-actor__title",
            "a.app-aware-link span[dir=ltr]"
        )
        
        for (selector in authorSelectors) {
            val element = document.select(selector).first()
            if (element != null && element.text().isNotEmpty()) {
                val authorName = element.text().trim()
                // Filter out common UI elements that might be mistaken for author names
                if (!authorName.equals("LinkedIn", ignoreCase = true) && 
                    !authorName.contains("Sign in") && 
                    !authorName.contains("Join now")) {
                    return authorName
                }
            }
        }
        
        // Try to extract from meta tags
        val metaAuthor = document.select("meta[property=og:title]").attr("content")
        if (metaAuthor.isNotEmpty()) {
            // Parse out the author name from the meta title if it's in format "Author Name on LinkedIn"
            val authorFromMeta = metaAuthor.split(" on LinkedIn").firstOrNull()
            if (authorFromMeta != null && authorFromMeta.isNotEmpty()) {
                return authorFromMeta
            }
            return metaAuthor
        }
        
        // Try to find the author in the post header
        try {
            val postHeader = document.select("div.scaffold-layout__main header").first()
            if (postHeader != null) {
                // Look for the author name in strong or span elements within the header
                val headerAuthor = postHeader.select("strong, span.text-heading-xlarge").first()?.text()
                if (headerAuthor != null && headerAuthor.isNotEmpty()) {
                    return headerAuthor
                }
            }
        } catch (e: Exception) {
            // Ignore errors in fallback methods
        }
        
        return "LinkedIn User"
    }
    
    private fun extractPostDate(document: Document): String {
        // Try different selectors that might contain the post date
        val dateSelectors = listOf(
            ".feed-shared-actor__sub-description",
            ".update-components-actor__sub-description",
            ".share-update-card__post-date",
            "span.feed-shared-actor__sub-description",
            "time.post-date",
            "span.t-black--light"
        )
        
        for (selector in dateSelectors) {
            val element = document.select(selector).first()
            if (element != null && element.text().isNotEmpty()) {
                val dateText = element.text().trim()
                
                // Filter out text that's not actually a date
                if (!dateText.contains("followers") && 
                    !dateText.contains("connections") && 
                    !dateText.startsWith("LinkedIn") &&
                    !dateText.contains("Sign in")) {
                    
                    // Extract just the date part if it contains other information
                    if (dateText.contains("•")) {
                        val parts = dateText.split("•")
                        for (part in parts) {
                            val trimmed = part.trim()
                            // Look for parts that might be dates
                            if (trimmed.contains("day") || 
                                trimmed.contains("week") || 
                                trimmed.contains("month") || 
                                trimmed.contains("hour") ||
                                trimmed.contains("min") ||
                                trimmed.matches(Regex(".*\\d+.*"))) { // Contains numbers
                                return trimmed
                            }
                        }
                    }
                    
                    return dateText
                }
            }
        }
        
        // Try to find the date in a time element
        val timeElement = document.select("time").first()
        if (timeElement != null) {
            val dateAttr = timeElement.attr("datetime")
            if (dateAttr.isNotEmpty()) {
                return formatDate(dateAttr)
            }
            
            val timeText = timeElement.text()
            if (timeText.isNotEmpty()) {
                return timeText
            }
        }
        
        // Try to find the date in the article metadata
        try {
            val articleMeta = document.select("span.artdeco-entity-lockup__caption").first()?.text()
            if (articleMeta != null && articleMeta.isNotEmpty()) {
                return articleMeta
            }
        } catch (e: Exception) {
            // Ignore errors in fallback methods
        }
        
        return "Recently posted"
    }
    
    private fun formatDate(dateStr: String): String {
        try {
            // This is a simple formatter for ISO dates
            // For a more sophisticated approach, you could use SimpleDateFormat
            if (dateStr.contains("T")) {
                val datePart = dateStr.split("T").firstOrNull() ?: return dateStr
                val parts = datePart.split("-")
                if (parts.size == 3) {
                    return "${parts[1]}/${parts[2]}/${parts[0]}"
                }
            }
            return dateStr
        } catch (e: Exception) {
            return dateStr
        }
    }
    
    private fun extractEngagementMetrics(document: Document): Map<String, Int> {
        var likes = 0
        var comments = 0
        
        // Try to extract likes count
        val likeSelectors = listOf(
            ".social-details-social-counts__reactions-count",
            ".social-details-social-counts__count-value",
            ".feed-shared-social-counts__num-likes"
        )
        
        for (selector in likeSelectors) {
            val element = document.select(selector).first()
            if (element != null && element.text().isNotEmpty()) {
                try {
                    val text = element.text().replace(",", "").replace("+", "")
                    likes = text.toIntOrNull() ?: 0
                    break
                } catch (e: Exception) {
                    // Ignore parsing errors
                }
            }
        }
        
        // Try to extract comments count
        val commentSelectors = listOf(
            ".social-details-social-counts__comments-count",
            ".feed-shared-social-counts__num-comments"
        )
        
        for (selector in commentSelectors) {
            val element = document.select(selector).first()
            if (element != null && element.text().isNotEmpty()) {
                try {
                    val text = element.text().replace(",", "").replace("+", "")
                    comments = text.toIntOrNull() ?: 0
                    break
                } catch (e: Exception) {
                    // Ignore parsing errors
                }
            }
        }
        
        return mapOf("likes" to likes, "comments" to comments)
    }
    
    private fun extractImages(document: Document): List<String> {
        val images = mutableListOf<String>()
        
        // Try different selectors that might contain post images
        val imageSelectors = listOf(
            ".feed-shared-image__container img",
            ".feed-shared-image img",
            ".feed-shared-update-v2__content img",
            ".update-components-image img",
            ".ivm-view-attr__img--centered",
            "img.ivm-view-attr__img",
            ".update-components-carousel__slider img",
            "article img[src]",
            ".artdeco-carousel__content img",
            ".artdeco-card img",
            "div[data-id] img[src]",
            "img.share-article__image",
            ".reader-article-content img"
        )
        
        // Process each selector
        for (selector in imageSelectors) {
            val elements = document.select(selector)
            for (element in elements) {
                // Try to get image source from different attributes
                val sources = listOf(
                    element.attr("src"),
                    element.attr("data-delayed-url"),
                    element.attr("data-ghost-url"),
                    element.attr("data-src")
                )
                
                for (src in sources) {
                    if (src.isNotEmpty() && 
                        !src.contains("data:image") && 
                        !images.contains(src) &&
                        (src.startsWith("http") || src.startsWith("//"))
                    ) {
                        // Ensure URL is absolute
                        val absoluteUrl = if (src.startsWith("//")) "https:$src" else src
                        images.add(absoluteUrl)
                    }
                }
            }
        }
        
        // Also try to get images from meta tags
        val metaSelectors = listOf(
            "meta[property=og:image]",
            "meta[name=twitter:image]",
            "meta[property=og:image:url]",
            "meta[name=thumbnail]"
        )
        
        for (selector in metaSelectors) {
            val metaImage = document.select(selector).attr("content")
            if (metaImage.isNotEmpty() && 
                !images.contains(metaImage) && 
                (metaImage.startsWith("http") || metaImage.startsWith("//"))
            ) {
                // Ensure URL is absolute
                val absoluteUrl = if (metaImage.startsWith("//")) "https:$metaImage" else metaImage
                images.add(absoluteUrl)
            }
        }
        
        // Try to find images in background style attributes
        try {
            val elementsWithBgImage = document.select("[style*=background-image]")
            for (element in elementsWithBgImage) {
                val style = element.attr("style")
                val bgImageMatch = Regex("background-image:\\s*url\\(['\"](.*?)['\"]\\)").find(style)
                if (bgImageMatch != null) {
                    val bgImage = bgImageMatch.groupValues[1]
                    if (bgImage.isNotEmpty() && 
                        !images.contains(bgImage) && 
                        !bgImage.contains("data:image") &&
                        (bgImage.startsWith("http") || bgImage.startsWith("//"))
                    ) {
                        // Ensure URL is absolute
                        val absoluteUrl = if (bgImage.startsWith("//")) "https:$bgImage" else bgImage
                        images.add(absoluteUrl)
                    }
                }
            }
        } catch (e: Exception) {
            // Ignore errors in optional processing
        }
        
        return images
    }

    private fun openSystemSettings(action: String) {
        try {
            // Handle special cases
            if (action == "android.settings.MANAGE_OVERLAY_PERMISSION") {
                // Special handling for overlay permission on Android M and above
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${packageName}")
                    )
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY
                    startActivity(intent)
                    return
                }
            } else if (action == "android.settings.ACCESSIBILITY_SETTINGS") {
                // Direct navigation to our accessibility service
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    // For Android 7.0 and above, we can navigate directly to our accessibility service
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    val componentName = packageName + "/com.example.einsteiniapp.EinsteiniAccessibilityService"
                    
                    intent.putExtra(":settings:fragment_args_key", componentName)
                    intent.putExtra(":settings:show_fragment_args", true)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY
                    startActivity(intent)
                    return
                } else {
                    // For older Android versions, fallback to general accessibility settings
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY
                    startActivity(intent)
                    return
                }
            }

            // General approach for other settings pages
            val intent = Intent(action)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY
            startActivity(intent)
        } catch (e: Exception) {
            // If specific setting page isn't available, open general settings
            val intent = Intent(Settings.ACTION_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_HISTORY
            startActivity(intent)
        }
    }
    
    private fun checkOverlayPermission(): Boolean {
        Log.d("EinsteiniApp", "Checking overlay permission")
        val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val canDraw = Settings.canDrawOverlays(this)
            Log.d("EinsteiniApp", "Can draw overlays: $canDraw")
            canDraw
        } else {
            Log.d("EinsteiniApp", "Android version < M, permission granted by default")
            true // On older versions, this permission is granted by default
        }
        
        if (!hasPermission) {
            Log.e("EinsteiniApp", "Overlay permission denied, opening settings")
        }
        
        return hasPermission
    }
    
    private fun isAccessibilityServiceEnabled(): Boolean {
        val expectedServiceName = packageName + "/com.example.einsteiniapp.EinsteiniAccessibilityService"
        
        try {
            val enabledServices = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            )
            
            if (enabledServices != null) {
                val colonSplitter = TextUtils.SimpleStringSplitter(':')
                colonSplitter.setString(enabledServices)
                
                while (colonSplitter.hasNext()) {
                    val componentName = colonSplitter.next()
                    if (componentName.equals(expectedServiceName, ignoreCase = true)) {
                        return true
                    }
                }
            }
            
            // Also check if our service is running
            return EinsteiniAccessibilityService.isRunning()
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    private fun cleanupContent(content: String): String {
        if (content.isEmpty()) return content
        
        // List of common UI text patterns to remove
        val uiPatterns = listOf(
            "Agree & Join LinkedIn",
            "Skip to main content",
            "LinkedIn Articles",
            "People Learning Jobs",
            "Get the app",
            "Join now",
            "Sign in",
            "Report this post",
            "Cookie Policy",
            "User Agreement",
            "Privacy Policy",
            "Community Guidelines",
            "6d Edited",
            "Edited"
        )
        
        var cleanedContent = content
        
        // Remove UI patterns
        for (pattern in uiPatterns) {
            cleanedContent = cleanedContent.replace(pattern, "")
        }
        
        // Remove common LinkedIn navigation text
        cleanedContent = cleanedContent.replace(Regex("LinkedIn\\s+Articles\\s+People\\s+Learning\\s+Jobs\\s+"), "")
        
        // Remove LinkedIn call-to-actions and comment prompts
        cleanedContent = cleanedContent.replace(Regex("(?i)to view or add a comment,? sign in.*$"), "")
        cleanedContent = cleanedContent.replace(Regex("(?i)to leave a comment,? sign in.*$"), "")
        cleanedContent = cleanedContent.replace(Regex("(?i)to engage with this post,? sign in.*$"), "")
        cleanedContent = cleanedContent.replace(Regex("(?i)sign in to.*comment.*$"), "")
        cleanedContent = cleanedContent.replace(Regex("(?i)like comment share.*$"), "")
        
        // Remove multiple spaces and trim
        cleanedContent = cleanedContent.replace(Regex("\\s+"), " ").trim()
        
        // If content starts with "Our project" or similar but has UI text before it, try to extract just the post
        val postStart = cleanedContent.indexOf("Our project")
        if (postStart > 0 && postStart < 100) {
            cleanedContent = cleanedContent.substring(postStart)
        }
        
        return cleanedContent
    }
    
    private fun extractSpecialContent(document: Document): String {
        // Check for various types of special content that might be embedded
        
        // 1. Look for shared article content
        try {
            val articleTitle = document.select(".feed-shared-article__title, .article-title, .share-article__title").first()?.text() ?: ""
            val articleDesc = document.select(".feed-shared-article__description, .share-article__description, .article-summary").first()?.text() ?: ""
            
            if (articleTitle.isNotEmpty()) {
                if (articleDesc.isNotEmpty()) {
                    return "Shared Article: $articleTitle\n$articleDesc"
                }
                return "Shared Article: $articleTitle"
            }
        } catch (e: Exception) { }
        
        // 2. Look for document or PDF content
        try {
            val docTitle = document.select(".feed-shared-document__title, .document-title").first()?.text() ?: ""
            if (docTitle.isNotEmpty()) {
                return "Shared Document: $docTitle"
            }
        } catch (e: Exception) { }
        
        // 3. Look for video content
        try {
            val videoTitle = document.select(".feed-shared-video__title, .video-title").first()?.text() ?: ""
            if (videoTitle.isNotEmpty()) {
                return "Shared Video: $videoTitle"
            }
        } catch (e: Exception) { }
        
        // 4. Look for poll content
        try {
            val pollQuestion = document.select(".feed-shared-poll__question, .poll-question").first()?.text() ?: ""
            if (pollQuestion.isNotEmpty()) {
                val options = document.select(".feed-shared-poll__option-label, .poll-option").map { it.text() }
                val optionsText = options.joinToString("\n- ", prefix = "\n- ")
                return "Poll: $pollQuestion$optionsText"
            }
        } catch (e: Exception) { }
        
        // 5. Look for LinkedIn article content (native articles)
        try {
            val articleBody = document.select(".article-content__body, .reader-article-content p").eachText().joinToString("\n")
            if (articleBody.isNotEmpty() && articleBody.length > 100) {
                return articleBody
            }
        } catch (e: Exception) { }
        
        return ""
    }
    
    private fun extractComments(document: Document): List<Map<String, String>> {
        val commentsList = mutableListOf<Map<String, String>>()
        
        try {
            // Try different selectors for comment sections
            val commentSectionSelectors = listOf(
                ".comments-comments-list",
                ".social-details-social-activity",
                ".comments-container",
                ".feed-shared-comments-list"
            )
            
            // Find the comment section
            var commentSection: org.jsoup.nodes.Element? = null
            for (selector in commentSectionSelectors) {
                commentSection = document.select(selector).first()
                if (commentSection != null) break
            }
            
            if (commentSection != null) {
                // Try different selectors for individual comments
                val commentSelectors = listOf(
                    ".comments-comment-item",
                    ".comments-comment-item-content",
                    ".feed-shared-comment",
                    ".social-details-comment-item"
                )
                
                var comments = listOf<org.jsoup.nodes.Element>()
                for (selector in commentSelectors) {
                    val foundComments = commentSection.select(selector)
                    if (foundComments.isNotEmpty()) {
                        comments = foundComments
                        break
                    }
                }
                
                // Process each comment
                for (comment in comments) {
                    // Try to extract the comment author name
                    val authorSelectors = listOf(
                        ".comments-comment-item__author-name",
                        ".feed-shared-comment-actor__name",
                        ".comments-post-meta__name-text",
                        ".comments-commenter-name",
                        "span.feed-shared-actor__title",
                        "a.comments-post-meta__actor-link"
                    )
                    
                    var authorName = "LinkedIn User"
                    for (selector in authorSelectors) {
                        val authorElement = comment.select(selector).first()
                        if (authorElement != null && authorElement.text().isNotEmpty()) {
                            authorName = authorElement.text().trim()
                            break
                        }
                    }
                    
                    // Try to extract the comment text
                    val textSelectors = listOf(
                        ".comments-comment-item-content-body",
                        ".feed-shared-comment-item__content",
                        ".comments-comment-item__main-content",
                        ".feed-shared-text",
                        ".comments-comment-text",
                        ".feed-shared-comment__content"
                    )
                    
                    var commentText = ""
                    for (selector in textSelectors) {
                        val textElement = comment.select(selector).first()
                        if (textElement != null && textElement.text().isNotEmpty()) {
                            commentText = textElement.text().trim()
                            break
                        }
                    }
                    
                    // If we found comment text, add it to our list
                    if (commentText.isNotEmpty()) {
                        commentsList.add(mapOf(
                            "author" to authorName,
                            "text" to commentText
                        ))
                    }
                }
            }
            
            // If we couldn't find comments with the structured approach, try a more general approach
            if (commentsList.isEmpty()) {
                // Look for elements that might contain comments
                val possibleCommentContainers = document.select("div.comments-comment-item, div.social-details-comment-item")
                
                for (container in possibleCommentContainers) {
                    val possibleAuthor = container.select("span[dir=ltr], a.comments-post-meta__actor-link").first()?.text() ?: "LinkedIn User"
                    val possibleText = container.select("p, span.feed-shared-text__text-view").text()
                    
                    if (possibleText.isNotEmpty()) {
                        commentsList.add(mapOf(
                            "author" to possibleAuthor,
                            "text" to possibleText
                        ))
                    }
                }
            }
        } catch (e: Exception) {
            // Return empty list if comment extraction fails
        }
        
        return commentsList
    }
    
    override fun onDestroy() {
        super.onDestroy()
        executor.shutdown()
        try {
            if (!executor.awaitTermination(800, TimeUnit.MILLISECONDS)) {
                executor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            executor.shutdownNow()
        }
    }
}
