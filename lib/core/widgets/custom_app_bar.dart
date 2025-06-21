import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:einsteiniapp/core/routes/app_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showDrawerButton;
  final VoidCallback? onDrawerPressed;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Widget? flexibleSpace;
  final bool showSettingsButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.showDrawerButton = true,
    this.onDrawerPressed,
    this.leading,
    this.centerTitle = true,
    this.elevation = 0,
    this.backgroundColor,
    this.flexibleSpace,
    this.showSettingsButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor,
      flexibleSpace: flexibleSpace,
      automaticallyImplyLeading: showBackButton || showDrawerButton,
      leading: _buildLeading(context),
      actions: actions ?? _buildDefaultActions(context),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) {
      return leading;
    } else if (showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      );
    } else if (showDrawerButton) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onDrawerPressed ?? () => Scaffold.of(context).openDrawer(),
      );
    }
    return null;
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    final List<Widget> defaultActions = [];
    
    if (showSettingsButton) {
      defaultActions.add(
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            context.push(AppRoutes.settings);
          },
        ),
      );
    }
    
    defaultActions.addAll([
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          // Show search dialog
        },
      ),
      IconButton(
        icon: const Icon(Icons.person_outline),
        onPressed: () {
          context.push(AppRoutes.profile);
        },
      ),
    ]);
    
    return defaultActions;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 