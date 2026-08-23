import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C111D) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 10),
              
              // Logo & App Name
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0070F3), Color(0xFF7A5AF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0070F3).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 18),
                  Text(
                    'Callalyze',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? Colors.white : const Color(0xFF0C111D),
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 10),
                  Text(
                    'Call Analytics\nFor Your Business',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: isDark ? Colors.white70 : Colors.blueGrey.shade600,
                    ),
                  ).animate(delay: 350.ms).fadeIn(),
                ],
              ),

              // Central Dashboard Vector Illustration
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D2939).withOpacity(0.5) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155).withOpacity(0.2) : Colors.black12,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Mock Line Chart drawing
                    Positioned(
                      bottom: 20,
                      left: 10,
                      right: 10,
                      child: SizedBox(
                        height: 60,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildBar(15, isDark),
                            _buildBar(28, isDark),
                            _buildBar(42, isDark),
                            _buildBar(30, isDark),
                            _buildBar(55, isDark),
                            _buildBar(38, isDark),
                            _buildBar(62, isDark),
                          ],
                        ),
                      ),
                    ),
                    // Dashboard widgets overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0070F3).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Container(
                            width: 32,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Floating team avatars representation
                    Positioned(
                      top: 40,
                      left: 15,
                      child: Row(
                        children: [
                          _buildAvatarCircle(Colors.orange),
                          const SizedBox(width: 4),
                          _buildAvatarCircle(Colors.teal),
                          const SizedBox(width: 4),
                          _buildAvatarCircle(Colors.blue),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.05),

              // Horizontal Loading Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0070F3)),
                      backgroundColor: Colors.black12,
                    ),
                  ),
                ),
              ).animate(delay: 700.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height, bool isDark) {
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF0070F3).withOpacity(height > 40 ? 0.8 : 0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
      ),
    );
  }

  Widget _buildAvatarCircle(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}
