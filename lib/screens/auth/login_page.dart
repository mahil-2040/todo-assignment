import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todo_assignment/core/theme/theme_provider.dart';
import 'package:todo_assignment/core/widgets/theme_toggle_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark(context);
        
        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Scaffold(
              body: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B), // Dark slate
                            const Color(0xFF334155), // Slightly lighter slate
                            const Color(0xFF0F172A), // Very dark slate
                          ]
                        : [
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
                        const SizedBox(height: 30),
                        // Theme Toggle Button
                        Row(
                          children: [
                            const Spacer(),
                            ThemeToggleButton(size: 24),
                          ],
                        ),
                const SizedBox(height: 80),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00D4D4),
                            Color(0xFF00B4D8),
                            Color(0xFF0EA5E9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B4D8).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.task_alt,
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
                  ],
                ),

                const SizedBox(height: 20),

                // Description text
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Stay organized and never miss a deadline.\nManage your todos with smart reminders.",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF0EA5E9)
                                        .withOpacity(0.3), // Bright blue center
                                    const Color(0xFF0284C7)
                                        .withOpacity(0.2), // Medium blue
                                    const Color(0xFF0369A1)
                                        .withOpacity(0.1), // Darker blue
                                    Colors.transparent, // Fade to transparent
                                  ]
                                : [
                                    const Color(0xFF00D4AA).withOpacity(0.13),
                                    const Color(0xFF00B4D8).withOpacity(0.1),
                                    const Color(0xFF90E0EF).withOpacity(0.05),
                                    Colors.transparent,
                                  ],
                            stops: const [0.0, 0.4, 0.7, 1.0],
                          ),
                        ),
                      ),

                      Transform.rotate(
                        angle: 0.2, // Slight rotation (-5.7 degrees)
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
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
                                  
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.task_alt,
                                  color: Color.fromARGB(255, 115, 225, 172),
                                  size: 70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Floating orange dot - top right
                      Positioned(
                        top: 58,
                        right: 50,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF8A50),
                                Color(0xFFFF6B35),
                                Color(0xFFE55A2B),
                              ],
                            ),
                            shape: BoxShape.circle,
                            
                          ),
                        ),
                      ),

                      // Floating purple dot - bottom left
                      Positioned(
                        bottom: 68,
                        left: 60,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFA78BFA),
                                Color(0xFF8B5CF6),
                                Color(0xFF7C3AED),
                              ],
                            ),
                            shape: BoxShape.circle,
                            
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
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
                      foregroundColor:
                          isDark ? Colors.white : const Color(0xFF374151),
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
                        : const Color.fromARGB(255, 77, 83, 92),
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
          },
        );
      },
    );
  }
}
