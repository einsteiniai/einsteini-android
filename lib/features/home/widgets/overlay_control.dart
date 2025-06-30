import 'package:flutter/material.dart';
import '../../../core/services/overlay_service.dart';
import '../../../core/utils/permission_utils.dart';
import '../../../core/utils/toast_utils.dart';

class OverlayControl extends StatefulWidget {
  const OverlayControl({Key? key}) : super(key: key);

  @override
  OverlayControlState createState() => OverlayControlState();
}

class OverlayControlState extends State<OverlayControl> {
  final OverlayService _overlayService = OverlayService();
  bool _isOverlayActive = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Make sure overlay is initially disabled - force it to false
    _forceStopOverlay();
  }

  // Force stop overlay and ensure state is OFF
  Future<void> _forceStopOverlay() async {
    setState(() {
      _isLoading = true;
      // Force the toggle to be OFF visually immediately
      _isOverlayActive = false;
    });
    
    // Stop overlay service on widget initialization to ensure it's off by default
    await _overlayService.stopOverlayService();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleOverlayService() async {
    final hasPermission = await PermissionUtils.checkOverlayPermission();
    
    if (!hasPermission) {
      if (context.mounted) {
        PermissionUtils.showPermissionDialog(
          context,
          title: 'Overlay Permission Required',
          message: 'To show the floating overlay, please grant the "Display over other apps" permission.',
          actionText: 'Open Settings',
          onActionPressed: () {
            PermissionUtils.openOverlaySettings();
          },
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool success;
    if (_isOverlayActive) {
      success = await _overlayService.stopOverlayService();
      if (success) {
        ToastUtils.showToast('Overlay stopped');
      } else {
        ToastUtils.showToast('Failed to stop overlay');
      }
    } else {
      // Get the current theme mode
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDarkMode = Theme.of(context).brightness == Brightness.dark || 
          brightness == Brightness.dark;
      
      success = await _overlayService.startOverlayService(isDarkMode: isDarkMode);
      if (success) {
        ToastUtils.showToast('Overlay started');
      } else {
        ToastUtils.showToast('Failed to start overlay');
      }
    }

    if (success) {
      setState(() {
        _isOverlayActive = !_isOverlayActive;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          margin: const EdgeInsets.all(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Floating Overlay',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enable a floating button that expands into a window when clicked.',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Floating Overlay'),
                  value: _isOverlayActive,
                  onChanged: _isLoading ? null : (_) => _toggleOverlayService(),
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
} 