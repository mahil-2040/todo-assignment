import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';

class ThemeToggleButton extends StatefulWidget {
  final double size;
  final Color? lightColor;
  final Color? darkColor;

  const ThemeToggleButton({
    super.key,
    this.size = 24,
    this.lightColor,
    this.darkColor,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Scale down animation
    await _scaleController.forward();
    
    // Rotate and toggle theme
    _rotationController.forward().then((_) {
      _rotationController.reset();
    });
    
    // Toggle theme
    if (mounted) {
      context.read<ThemeProvider>().toggleTheme();
    }
    
    // Scale back up
    await _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDark(context);
        
        return GestureDetector(
          onTap: _onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 2 * 3.14159,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF64748B),
                                const Color(0xFF475569),
                                const Color(0xFF334155),
                              ]
                            : [
                                const Color(0xFFFF8A50),
                                const Color(0xFFFF6B35),
                                const Color(0xFFE55A2B),
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFFFF6B35))
                              .withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark ? Icons.nightlight_round : Icons.wb_sunny,
                      color: Colors.white,
                      size: widget.size * 0.6,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
