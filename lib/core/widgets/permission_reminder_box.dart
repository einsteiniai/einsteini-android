import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:einsteiniapp/core/routes/app_router.dart' as router;
import 'package:einsteiniapp/core/utils/permission_utils.dart';

class PermissionReminderBox extends StatelessWidget {
  final AppPermission permission;
  final VoidCallback? onDismiss;

  const PermissionReminderBox({
    Key? key,
    required this.permission,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    String title;
    String description;
    String buttonText;
    IconData icon;
    String route;

    switch (permission) {
      case AppPermission.overlay:
        title = 'Display Over Other Apps';
        description = 'Grant permission to display over other apps to get AI assistance directly in LinkedIn';
        buttonText = 'Enable Now';
        icon = Icons.layers;
        route = router.AppRoutes.overlayPermission;
        break;
      case AppPermission.accessibility:
        title = 'Accessibility Service';
        description = 'Grant accessibility permission to analyze LinkedIn content and provide AI assistance';
        buttonText = 'Enable Now';
        icon = Icons.accessibility_new;
        route = router.AppRoutes.accessibilityPermission;
        break;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDarkMode
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.primary.withOpacity(0.05),
              isDarkMode
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Theme.of(context).colorScheme.primary.withOpacity(0.15),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    tooltip: 'Dismiss',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    if (onDismiss != null) {
                      onDismiss!();
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Later'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.push(route);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(buttonText),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
      begin: 0.2,
      end: 0,
      duration: 600.ms,
      curve: Curves.easeOutQuad,
    );
  }
} 