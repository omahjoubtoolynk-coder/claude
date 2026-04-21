import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut)));
    _ctrl.forward();
    _init();
  }

  Future<void> _init() async {
    final provider = context.read<AppProvider>();
    await provider.initialize();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => provider.isOnboarded ? const HomeScreen() : const OnboardingScreen(),
    ));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Center(child: Text('☪', style: TextStyle(fontSize: 60))),
                  ),
                  const SizedBox(height: 24),
                  const Text('حافظ',
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.gold)),
                  const SizedBox(height: 8),
                  const Text('Votre compagnon du Coran',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                  const SizedBox(height: 60),
                  const SizedBox(width: 36, height: 36,
                      child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
