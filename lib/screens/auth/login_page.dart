import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:todo_assignment/core/theme/theme_provider.dart';
import 'package:todo_assignment/core/widgets/theme_toggle_button.dart';
import 'package:app_links/app_links.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  StreamSubscription? _sub;
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _sub = _appLinks.uriLinkStream.listen((Uri uri) async {
      if (uri.scheme == "todo") {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

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
    _sub?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'todo://login-callback/',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isSmallScreen = screenHeight < 700;
    
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
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Column(
                      children: [
                        // Top spacing
                        SizedBox(height: screenHeight * 0.04),
                        // Theme Toggle Button
                        Row(
                          children: [
                            const Spacer(),
                            ThemeToggleButton(size: isTablet ? 28 : 24),
                          ],
                        ),
                SizedBox(height: isSmallScreen ? screenHeight * 0.08 : screenHeight * 0.10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isTablet ? 50 : 40,
                      height: isTablet ? 50 : 40,
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
                        borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00B4D8).withOpacity(0.3),
                            blurRadius: isTablet ? 10 : 8,
                            offset: Offset(0, isTablet ? 5 : 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.task_alt,
                        color: Colors.white,
                        size: isTablet ? 30 : 24,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      "TodoReminder",
                      style: TextStyle(
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: screenHeight * 0.025),

                // Description text
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    "Stay organized and never miss a deadline.\nManage your todos with smart reminders.",
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),

                // Illustration area with circular gradient
                SizedBox(
                  height: isSmallScreen ? screenHeight * 0.30 : screenHeight * 0.35,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Main circular gradient background
                      Container(
                        width: isTablet ? 350 : screenWidth * 0.7,
                        height: isTablet ? 350 : screenWidth * 0.7,
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
                          width: isTablet ? 170 : screenWidth * 0.35,
                          height: isTablet ? 170 : screenWidth * 0.35,
                          decoration: BoxDecoration(
                            color: isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.1),
                                blurRadius: isTablet ? 25 : 20,
                                offset: Offset(0, isTablet ? 12 : 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isTablet ? 75 : screenWidth * 0.15,
                                height: isTablet ? 75 : screenWidth * 0.15,
                                decoration: BoxDecoration(
                                  
                                  borderRadius: BorderRadius.circular(isTablet ? 15 : 12),
                                ),
                                child: Icon(
                                  Icons.task_alt,
                                  color: const Color.fromARGB(255, 115, 225, 172),
                                  size: isTablet ? 85 : screenWidth * 0.175,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Floating orange dot - top right
                      Positioned(
                        top: isTablet ? 70 : screenHeight * 0.08,
                        right: isTablet ? 60 : screenWidth * 0.12,
                        child: Container(
                          width: isTablet ? 50 : screenWidth * 0.10,
                          height: isTablet ? 50 : screenWidth * 0.10,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
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
                        bottom: isTablet ? 80 : screenHeight * 0.09,
                        left: isTablet ? 70 : screenWidth * 0.15,
                        child: Container(
                          width: isTablet ? 40 : screenWidth * 0.075,
                          height: isTablet ? 40 : screenWidth * 0.075,
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

                SizedBox(height: isSmallScreen ? screenHeight * 0.04 : screenHeight * 0.07),
                // Google Sign In Button
                Container(
                  width: double.infinity,
                  height: isTablet ? 64 : 56,
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
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
                        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
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
                          width: isTablet ? 24 : 20,
                          height: isTablet ? 24 : 20,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.g_mobiledata,
                              size: isTablet ? 24 : 20,
                              color: const Color(0xFF4285F4),
                            );
                          },
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.03),

                // Terms text
                Text(
                  "By signing in, you agree to our Terms of Service and\nPrivacy Policy",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 12,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color.fromARGB(255, 77, 83, 92),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: screenHeight * 0.05),
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
