import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    final isDark = Theme.of(context).brightness == Brightness.dark || 
                   MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark ? [
              const Color(0xFF1E293B), // Dark slate
              const Color(0xFF334155), // Slightly lighter slate
              const Color(0xFF0F172A), // Very dark slate
            ] : [
              const Color(0xFFE8F4F8),
              const Color(0xFFF0F8FF),
              const Color(0xFFE6F3FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Top spacing
                const SizedBox(height: 60),
                
                // App Logo and Title
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B4D8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "TodoReminder",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    const Spacer(),
                    // Moon/Sun icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDark ? Icons.nightlight_round : Icons.wb_sunny,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Description text
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Stay organized and never miss a deadline.\nManage your todos with smart reminders.",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Illustration area with circular gradient
                SizedBox(
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main circular gradient background
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: isDark ? [
                              const Color(0xFF0EA5E9).withOpacity(0.3), // Bright blue center
                              const Color(0xFF0284C7).withOpacity(0.2), // Medium blue
                              const Color(0xFF0369A1).withOpacity(0.1), // Darker blue
                              Colors.transparent, // Fade to transparent
                            ] : [
                              const Color(0xFF00D4AA).withOpacity(0.2),
                              const Color(0xFF00B4D8).withOpacity(0.1),
                              const Color(0xFF90E0EF).withOpacity(0.05),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),
                      
                      // Slanted card with rotation
                      Transform.rotate(
                        angle: -0.1, // Slight rotation (-5.7 degrees)
                        child: Container(
                          width: 140,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark 
                                  ? Colors.black.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00B4D8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Floating orange dot - top right
                      Positioned(
                        top: 60,
                        right: 80,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6B35),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      
                      // Floating purple dot - bottom left
                      Positioned(
                        bottom: 80,
                        left: 60,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Google Sign In Button
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: () => _signInWithGoogle(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark 
                        ? const Color(0xFF334155).withOpacity(0.8)
                        : Colors.white,
                      foregroundColor: isDark 
                        ? Colors.white 
                        : const Color(0xFF374151),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark 
                            ? const Color(0xFF475569).withOpacity(0.5)
                            : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network(
                          'https://img.icons8.com/?size=100&id=V5cGWnc9R4xj&format=png&color=000000',
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.g_mobiledata,
                              size: 20,
                              color: Color(0xFF4285F4),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Terms text
                Text(
                  "By signing in, you agree to our Terms of Service and\nPrivacy Policy",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark 
                      ? const Color(0xFF64748B) 
                      : const Color(0xFF9CA3AF),
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
