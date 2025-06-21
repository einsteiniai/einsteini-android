import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einsteiniapp/core/constants/app_constants.dart';
import 'package:einsteiniapp/core/routes/app_router.dart' as router;
import 'package:einsteiniapp/core/utils/toast_utils.dart';

class AuthScreen extends StatefulWidget {
  final bool isSignUp;
  
  const AuthScreen({
    Key? key,
    this.isSignUp = false,
  }) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // In a real app, you would implement actual authentication here
      await Future.delayed(const Duration(seconds: 1));
      
      // Save user login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.userLoggedInKey, true);
      
      // For demo, we're storing a fake user ID
      await prefs.setString(AppConstants.userProfileKey, 'user_${DateTime.now().millisecondsSinceEpoch}');
      
      if (mounted) {
        context.go(router.AppRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        // Show error toast
        ToastUtils.showErrorToast('Authentication failed: $error');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (_isSignUp && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (_isSignUp && (value == null || value.isEmpty)) {
      return 'Name is required';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo and Title
                Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                    ? 'assets/images/einsteini_white.png'
                    : 'assets/images/einsteini_black.png',
                  height: 50,
                  width: 50,
                  fit: BoxFit.contain,
                ).animate().fadeIn(duration: 600.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  _isSignUp ? 'Create Account' : 'Welcome Back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                
                const SizedBox(height: 8),
                
                Text(
                  _isSignUp 
                    ? 'Sign up to start crafting engaging LinkedIn content'
                    : 'Login to continue your LinkedIn growth journey',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 600.ms, delay: 300.ms),
                
                const SizedBox(height: 40),
                
                // Auth Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_isSignUp)
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _validateName,
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      
                      if (_isSignUp) const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ).animate().fadeIn(duration: 600.ms, delay: _isSignUp ? 500.ms : 400.ms),
                      
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: _isSignUp ? 'Create a password' : 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        validator: _validatePassword,
                      ).animate().fadeIn(duration: 600.ms, delay: _isSignUp ? 600.ms : 500.ms),
                      
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Handle forgot password
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Password reset link sent to your email'),
                                ),
                              );
                            },
                            child: const Text('Forgot Password?'),
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 600.ms),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          ),
                          child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              )
                            : Text(_isSignUp ? 'Sign Up' : 'Login'),
                        ),
                      ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isSignUp
                              ? 'Already have an account?'
                              : 'Don\'t have an account?',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: _toggleAuthMode,
                            child: Text(_isSignUp ? 'Login' : 'Sign Up'),
                          ),
                        ],
                      ).animate().fadeIn(duration: 600.ms, delay: 800.ms),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Social logins
                Column(
                  children: [
                    Text(
                      'Or continue with',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(
                          icon: Icons.g_mobiledata,
                          onPressed: () {
                            // Handle Google sign in
                            _handleSocialLogin('Google');
                          },
                        ),
                        const SizedBox(width: 16),
                        _buildSocialButton(
                          icon: Icons.apple,
                          onPressed: () {
                            // Handle Apple sign in
                            _handleSocialLogin('Apple');
                          },
                        ),
                      ],
                    ),
                  ],
                ).animate().fadeIn(duration: 600.ms, delay: 900.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerTheme.color ?? Colors.grey[300]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 32,
        ),
      ),
    );
  }
  
  void _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate social sign-in
      await Future.delayed(const Duration(seconds: 1));
      
      // Save user login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.userLoggedInKey, true);
      await prefs.setString(AppConstants.userProfileKey, '${provider}_user_${DateTime.now().millisecondsSinceEpoch}');
      
      if (mounted) {
        // Show success toast
        ToastUtils.showSuccessToast('Successfully signed in with $provider');
        context.go(router.AppRoutes.home);
      }
    } catch (error) {
      if (mounted) {
        // Show error toast
        ToastUtils.showErrorToast('$provider sign in failed: $error');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 