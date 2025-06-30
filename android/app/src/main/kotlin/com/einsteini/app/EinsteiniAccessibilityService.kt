package com.einsteini.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import org.json.JSONArray
import com.einsteini.app.R

// Extension function to safely get roleDescription on Android P and above
private fun AccessibilityNodeInfo.getRoleDescriptionCompat(): String? {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        try {
            // Use reflection to access the method safely
            val method = AccessibilityNodeInfo::class.java.getMethod("getRoleDescription")
            method.invoke(this) as? String
        } catch (e: Exception) {
            null
        }
    } else {
        null
    }
}

class EinsteiniAccessibilityService : AccessibilityService() {

    companion object {
        private var instance: EinsteiniAccessibilityService? = null
        private var running = false
        private var methodChannel: MethodChannel? = null
        private const val TAG = "EinsteiniAccessibility"
        
        // LinkedIn package name
        private const val LINKEDIN_PACKAGE = "com.linkedin.android"
        
        // Content types
        private const val TYPE_LINKEDIN_POST = "linkedin_post"
        private const val TYPE_LINKEDIN_PROFILE = "linkedin_profile"
        private const val TYPE_LINKEDIN_COMMENT = "linkedin_comment"

        fun getInstance(): EinsteiniAccessibilityService? {
            return instance
        }

        // Check if the service is running
        fun isRunning(): Boolean {
            return running
        }
        
        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onServiceConnected() {
        instance = this
        super.onServiceConnected()
        running = true
        Log.d(TAG, "Service connected")
    }

    override fun onDestroy() {
        super.onDestroy()
        running = false
        Log.d(TAG, "Service destroyed")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        try {
            // Only process events from LinkedIn app
            if (event.packageName?.toString() == LINKEDIN_PACKAGE) {
                when (event.eventType) {
                    AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
                    AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                        processLinkedInContent(event)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing accessibility event", e)
        }
    }
    
    private fun processLinkedInContent(event: AccessibilityEvent) {
        val rootNode = try {
            rootInActiveWindow
        } catch (e: Exception) {
            Log.e(TAG, "Error getting root node", e)
            null
        } ?: return
        
        try {
            // Check for LinkedIn post
            val postContent = findLinkedInPostContent(rootNode)
            if (postContent.isNotEmpty()) {
                val data = JSONObject()
                data.put("type", TYPE_LINKEDIN_POST)
                data.put("content", postContent.content)
                data.put("author", postContent.author)
                data.put("hasImage", postContent.hasImage)
                
                // Send the data to Flutter
                methodChannel?.invokeMethod("onLinkedInContentDetected", data.toString())
                return
            }
            
            // Check for LinkedIn profile
            val profileContent = findLinkedInProfileContent(rootNode)
            if (profileContent.isNotEmpty()) {
                val data = JSONObject()
                data.put("type", TYPE_LINKEDIN_PROFILE)
                data.put("name", profileContent.name)
                data.put("title", profileContent.title)
                data.put("about", profileContent.about)
                data.put("url", profileContent.url)
                data.put("mutual", profileContent.mutual)
                
                // Send the data to Flutter
                methodChannel?.invokeMethod("onLinkedInContentDetected", data.toString())
                return
            }
            
            // Check for LinkedIn comments
            val commentsContent = findLinkedInComments(rootNode)
            if (commentsContent.isNotEmpty()) {
                val data = JSONObject()
                data.put("type", TYPE_LINKEDIN_COMMENT)
                
                // Convert comments to JSON array
                val commentsArray = JSONArray()
                for (comment in commentsContent) {
                    val commentObj = JSONObject()
                    commentObj.put("author", comment.author)
                    commentObj.put("text", comment.text)
                    commentsArray.put(commentObj)
                }
                
                data.put("comments", commentsArray)
                
                // Send the data to Flutter
                methodChannel?.invokeMethod("onLinkedInContentDetected", data.toString())
                return
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding LinkedIn content", e)
        } finally {
            rootNode.recycle()
        }
    }
    
    private data class LinkedInPostContent(
        val content: String,
        val author: String,
        val hasImage: Boolean
    ) {
        fun isNotEmpty(): Boolean {
            return content.isNotEmpty() || author.isNotEmpty()
        }
    }
    
    private data class LinkedInProfileContent(
        val name: String,
        val title: String,
        val about: String,
        val url: String,
        val mutual: String
    ) {
        fun isNotEmpty(): Boolean {
            return name.isNotEmpty() || title.isNotEmpty() || about.isNotEmpty()
        }
    }
    
    private data class LinkedInComment(
        val author: String,
        val text: String
    )
    
    private fun findLinkedInPostContent(rootNode: AccessibilityNodeInfo): LinkedInPostContent {
        // Try to find post content in the LinkedIn app using more specific selectors
        var content = ""
        var author = ""
        var hasImage = false
        
        // Look for post content - using selectors from contentScript.js
        val contentSelectors = listOf(
            "feed-shared-update-v2__description",
            "feed-shared-inline-show-more-text",
            "update-components-text",
            "feed-shared-update-v2__commentary",
            "feed-shared-text__text-view"
        )
        
        for (selector in contentSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                val nodeText = nodes[0].text?.toString()
                if (!nodeText.isNullOrEmpty()) {
                    content = nodeText.replace("…see more", "").trim()
                    break
                }
            }
        }
        
        // Look for author name - using selectors from contentScript.js
        val authorSelectors = listOf(
            "update-components-actor__title",
            "feed-shared-actor__title",
            "update-components-actor__name",
            "feed-shared-actor__name"
        )
        
        for (selector in authorSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                for (node in nodes) {
                    val nodeText = node.text?.toString()
                    if (!nodeText.isNullOrEmpty() && 
                        !nodeText.contains("LinkedIn") && 
                        !nodeText.contains("Sign in") && 
                        !nodeText.contains("Join now")) {
                        author = nodeText.trim()
                        break
                    }
                }
                if (author.isNotEmpty()) break
            }
        }
        
        // If still no author found, try to find it in visually-hidden spans
        if (author.isEmpty()) {
            val hiddenSpans = findNodesByText(rootNode, "visually-hidden")
            for (node in hiddenSpans) {
                val nodeText = node.text?.toString()
                if (!nodeText.isNullOrEmpty() && 
                    !nodeText.contains("LinkedIn") && 
                    !nodeText.contains("Sign in") && 
                    nodeText.length < 50) {  // Author names are typically short
                    author = nodeText.trim()
                    break
                }
            }
        }
        
        // Also try to find text directly with common patterns in LinkedIn posts
        if (content.isEmpty()) {
            // Look for contentDescription that might contain post text
            val possibleContentNodes = findNodesWithNonEmptyContentDescription(rootNode)
            for (node in possibleContentNodes) {
                val desc = node.contentDescription?.toString() ?: ""
                if (desc.length > 50 && !desc.contains("profile") && !desc.contains("photo")) {
                    content = desc
                    break
                }
            }
        }
        
        // Check for images using multiple selectors
        val imageSelectors = listOf(
            "update-components-image",
            "feed-shared-image",
            "update-components-image__image-link",
            "ivm-view-attr__img-wrapper",
            "ivm-image-view-model"
        )
        
        for (selector in imageSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                hasImage = true
                break
            }
        }
        
        // Also check for contentDescription containing "image" or "photo"
        if (!hasImage) {
            val imageDescriptionNodes = findNodesByContentDescription(rootNode, "image")
            hasImage = imageDescriptionNodes.isNotEmpty()
            
            if (!hasImage) {
                val photoDescriptionNodes = findNodesByContentDescription(rootNode, "photo")
                hasImage = photoDescriptionNodes.isNotEmpty()
            }
        }
        
        // Clean up the content
        content = content.replace(Regex("LinkedIn\\s+Articles\\s+People\\s+Learning\\s+Jobs\\s+"), "")
            .replace(Regex("(?i)to view or add a comment,? sign in.*$"), "")
            .replace(Regex("(?i)to leave a comment,? sign in.*$"), "")
            .replace(Regex("(?i)to engage with this post,? sign in.*$"), "")
            .replace(Regex("(?i)sign in to.*comment.*$"), "")
            .replace(Regex("(?i)like comment share.*$"), "")
            .replace(Regex("\\s+"), " ")
            .trim()
        
        return LinkedInPostContent(content, author, hasImage)
    }
    
    private fun findLinkedInProfileContent(rootNode: AccessibilityNodeInfo): LinkedInProfileContent {
        // Try to find profile content in the LinkedIn app using more specific selectors
        var name = ""
        var title = ""
        var about = ""
        var url = ""
        var mutual = ""
        
        // Look for name - try multiple possible selectors
        val nameSelectors = listOf(
            "profile-view-name",
            "top-card-layout__title",
            "text-heading-xlarge"
        )
        
        for (selector in nameSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                val nodeText = nodes[0].text?.toString()
                if (!nodeText.isNullOrEmpty()) {
                    name = nodeText.trim()
                    break
                }
            }
        }
        
        // If still no name found, try to find it in visually-hidden spans
        if (name.isEmpty()) {
            val hiddenSpans = findNodesByText(rootNode, "visually-hidden")
            for (node in hiddenSpans) {
                val nodeText = node.text?.toString()
                if (!nodeText.isNullOrEmpty() && 
                    !nodeText.contains("LinkedIn") && 
                    !nodeText.contains("Sign in") && 
                    nodeText.length < 50) {  // Names are typically short
                    name = nodeText.trim()
                    break
                }
            }
        }
        
        // Look for title/headline
        val titleSelectors = listOf(
            "top-card-layout__headline",
            "text-body-medium",
            "profile-view-headline"
        )
        
        for (selector in titleSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                for (node in nodes) {
                    val nodeText = node.text?.toString()
                    if (!nodeText.isNullOrEmpty() && 
                        !nodeText.contains("LinkedIn") && 
                        !nodeText.contains("Sign in") && 
                        !nodeText.contains("followers") && 
                        !nodeText.contains("connections")) {
                        title = nodeText.trim()
                        break
                    }
                }
                if (title.isNotEmpty()) break
            }
        }
        
        // Look for about section
        val aboutSelectors = listOf(
            "about-section",
            "profile-section-card__contents",
            "core-section-container__content"
        )
        
        for (selector in aboutSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                for (node in nodes) {
                    // Try to find the about text within this section
                    val aboutText = collectTextFromNode(node)
                    if (aboutText.isNotEmpty() && aboutText.length > 50) {
                        about = aboutText.trim()
                        break
                    }
                }
                if (about.isNotEmpty()) break
            }
        }
        
        // Look for mutual connections
        val mutualSelectors = listOf(
            "mutual-connections",
            "top-card__connections-count"
        )
        
        for (selector in mutualSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                val nodeText = nodes[0].text?.toString()
                if (!nodeText.isNullOrEmpty()) {
                    mutual = nodeText.trim()
                    break
                }
            }
        }
        
        // Try to extract URL or profile ID
        url = extractProfileIdFromView(rootNode)
        
        return LinkedInProfileContent(name, title, about, url, mutual)
    }
    
    private fun findLinkedInComments(rootNode: AccessibilityNodeInfo): List<LinkedInComment> {
        val comments = mutableListOf<LinkedInComment>()
        
        // Look for comments section
        val commentSectionSelectors = listOf(
            "comments-comments-list",
            "social-details-social-activity",
            "comments-container",
            "feed-shared-comments-list"
        )
        
        var commentSection: AccessibilityNodeInfo? = null
        for (selector in commentSectionSelectors) {
            val nodes = findNodesByText(rootNode, selector)
            if (nodes.isNotEmpty()) {
                commentSection = nodes[0]
                break
            }
        }
        
        if (commentSection != null) {
            // Look for individual comments
            val commentItemSelectors = listOf(
                "comments-comment-item",
                "comments-comment-item-content",
                "feed-shared-comment",
                "social-details-comment-item"
            )
            
            var commentItems = mutableListOf<AccessibilityNodeInfo>()
            for (selector in commentItemSelectors) {
                val nodes = findNodesByText(commentSection, selector)
                if (nodes.isNotEmpty()) {
                    commentItems.addAll(nodes)
                    break
                }
            }
            
            // Process each comment item
            for (commentItem in commentItems) {
                var author = ""
                var text = ""
                
                // Look for author name
                val authorSelectors = listOf(
                    "comments-comment-item__author-name",
                    "feed-shared-comment-actor__name",
                    "comments-post-meta__name-text",
                    "comments-commenter-name"
                )
                
                for (selector in authorSelectors) {
                    val nodes = findNodesByText(commentItem, selector)
                    if (nodes.isNotEmpty()) {
                        val authorText = nodes[0].text?.toString()
                        if (!authorText.isNullOrEmpty()) {
                            author = authorText.trim()
                            break
                        }
                    }
                }
                
                // Look for comment text
                val textSelectors = listOf(
                    "comments-comment-item-content-body",
                    "feed-shared-comment-item__content",
                    "comments-comment-item__main-content",
                    "feed-shared-text",
                    "comments-comment-text"
                )
                
                for (selector in textSelectors) {
                    val nodes = findNodesByText(commentItem, selector)
                    if (nodes.isNotEmpty()) {
                        val commentText = nodes[0].text?.toString()
                        if (!commentText.isNullOrEmpty()) {
                            text = commentText.trim()
                            break
                        }
                    }
                }
                
                // If both author and text are found, add to comments list
                if (author.isNotEmpty() && text.isNotEmpty()) {
                    comments.add(LinkedInComment(author, text))
                }
            }
        }
        
        return comments
    }
    
    // Helper method to find nodes by a partial class name, ID or content description
    private fun findNodesByText(node: AccessibilityNodeInfo?, searchText: String): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        if (node == null) return results
        
        try {
            // Check view ID
            val viewIdResourceName = node.viewIdResourceName ?: ""
            if (viewIdResourceName.contains(searchText, ignoreCase = true)) {
                results.add(node)
            }
            
            // Check class name
            val className = node.className?.toString() ?: ""
            if (className.contains(searchText, ignoreCase = true)) {
                results.add(node)
            }
            
            // Check content description
            val contentDesc = node.contentDescription?.toString() ?: ""
            if (contentDesc.contains(searchText, ignoreCase = true)) {
                results.add(node)
            }
            
            // For LinkedIn's specific class naming convention
            if (node.text != null) {
                val parentElement = node.parent
                if (parentElement != null) {
                    val parentClassName = parentElement.className?.toString() ?: ""
                    if (parentClassName.contains(searchText, ignoreCase = true)) {
                        results.add(node)
                    }
                }
            }
            
            // Recursively check children
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    results.addAll(findNodesByText(childNode, searchText))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error searching for node by text", e)
        }
        
        return results
    }
    
    // Helper method to find nodes with exact text
    private fun findNodesWithExactText(node: AccessibilityNodeInfo?, exactText: String): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        if (node == null) return results
        
        try {
            if (node.text?.toString() == exactText) {
                results.add(node)
            }
            
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    results.addAll(findNodesWithExactText(childNode, exactText))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error searching for node by exact text", e)
        }
        
        return results
    }
    
    // Helper method to find content after a specific node
    private fun findContentAfterNode(rootNode: AccessibilityNodeInfo?, targetNode: AccessibilityNodeInfo): String {
        // This is a simplified implementation that would need to be adapted to the actual structure
        if (rootNode == null || targetNode == null) return ""
        
        try {
            val parentNode = findParentSection(rootNode, targetNode)
            if (parentNode != null) {
                val contentBuilder = StringBuilder()
                
                // Collect text from all children of the parent node except the target node
                for (i in 0 until parentNode.childCount) {
                    val childNode = parentNode.getChild(i)
                    if (childNode != null && childNode != targetNode) {
                        contentBuilder.append(collectTextFromNode(childNode)).append(" ")
                    }
                }
                
                return contentBuilder.toString().trim()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding content after node", e)
        }
        
        return ""
    }
    
    // Helper method to find the parent section of a node
    private fun findParentSection(rootNode: AccessibilityNodeInfo?, targetNode: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (rootNode == null || targetNode == null) return null
        
        // Check if this node is a section and contains the target node
        if (isSection(rootNode) && containsNode(rootNode, targetNode)) {
            return rootNode
        }
        
        // Check all children
        for (i in 0 until rootNode.childCount) {
            val childNode = rootNode.getChild(i)
            if (childNode != null) {
                val foundSection = findParentSection(childNode, targetNode)
                if (foundSection != null) {
                    return foundSection
                }
            }
        }
        
        return null
    }
    
    // Helper method to check if a node is a section
    private fun isSection(node: AccessibilityNodeInfo?): Boolean {
        if (node == null) return false
        
        // In LinkedIn, sections might be div elements or have specific roles
        return node.className?.contains("section") == true ||
               node.getRoleDescriptionCompat()?.contains("section") == true
    }
    
    // Helper method to check if a node contains another node
    private fun containsNode(parentNode: AccessibilityNodeInfo?, searchNode: AccessibilityNodeInfo): Boolean {
        if (parentNode == null || searchNode == null) return false
        if (parentNode == searchNode) return true
        
        for (i in 0 until parentNode.childCount) {
            val childNode = parentNode.getChild(i)
            if (childNode != null) {
                if (childNode == searchNode || containsNode(childNode, searchNode)) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Helper method to collect text from a node and its children
    private fun collectTextFromNode(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""
        
        val contentBuilder = StringBuilder()
        try {
            if (node.text != null && node.text.isNotEmpty()) {
                contentBuilder.append(node.text).append(" ")
            }
            
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    contentBuilder.append(collectTextFromNode(childNode)).append(" ")
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error collecting text from node", e)
        }
        
        return contentBuilder.toString().trim()
    }

    override fun onInterrupt() {
        // No action needed on interrupt
    }

    override fun onUnbind(intent: Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    // Helper method to find nodes with non-empty contentDescription
    private fun findNodesWithNonEmptyContentDescription(node: AccessibilityNodeInfo?): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        if (node == null) return results
        
        try {
            if (!node.contentDescription.isNullOrEmpty()) {
                results.add(node)
            }
            
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    results.addAll(findNodesWithNonEmptyContentDescription(childNode))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding nodes with content description", e)
        }
        
        return results
    }
    
    // Helper method to find nodes by content description containing text
    private fun findNodesByContentDescription(node: AccessibilityNodeInfo?, searchText: String): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        if (node == null) return results
        
        try {
            val contentDesc = node.contentDescription?.toString()
            if (contentDesc != null && contentDesc.contains(searchText, ignoreCase = true)) {
                results.add(node)
            }
            
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    results.addAll(findNodesByContentDescription(childNode, searchText))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error searching for node by content description", e)
        }
        
        return results
    }
    
    // Helper method to find heading nodes (useful for profile names)
    private fun findHeadingNodes(node: AccessibilityNodeInfo?): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        if (node == null) return results
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                if (node.isHeading) {
                    results.add(node)
                }
            }
            
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    results.addAll(findHeadingNodes(childNode))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error finding heading nodes", e)
        }
        
        return results
    }
    
    // Helper method to find nodes containing specific text
    private fun findNodesContainingText(node: AccessibilityNodeInfo?, searchText: String): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        if (node == null) return results
        
        try {
            val nodeText = node.text?.toString()
            if (nodeText != null && nodeText.contains(searchText, ignoreCase = true)) {
                results.add(node)
            }
            
            for (i in 0 until node.childCount) {
                val childNode = node.getChild(i)
                if (childNode != null) {
                    results.addAll(findNodesContainingText(childNode, searchText))
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error searching for nodes containing text", e)
        }
        
        return results
    }
    
    // Helper method to extract profile ID from view
    private fun extractProfileIdFromView(rootNode: AccessibilityNodeInfo?): String {
        // This is a placeholder implementation
        // In a real implementation, we would need to extract this from the URL in WebView
        // or from other identifiable elements in the LinkedIn app
        return ""
    }
} 
