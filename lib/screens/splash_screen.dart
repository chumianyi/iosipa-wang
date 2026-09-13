import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '88',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 600.ms)
                  .rotate(duration: 900.ms, begin: -0.5, end: 0),
              const SizedBox(height: 24),
              const Text(
                'iosipa.wang',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, delay: 400.ms),
              const SizedBox(height: 48),
              const Text(
                '加载中...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(delay: 800.ms, duration: 900.ms)
                  .then()
                  .fadeOut(duration: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}
