import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  int _page = 0;
  String _level = 'débutant';
  int _goal = 3;
  bool _saving = false;

  @override
  void dispose() { _pageCtrl.dispose(); _nameCtrl.dispose(); super.dispose(); }

  void _next() {
    if (_page == 0 && _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer votre prénom')));
      return;
    }
    if (_page < 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await context.read<AppProvider>().saveUserProfile(UserProfile(
      name: _nameCtrl.text.trim(), level: _level, dailyGoal: _goal, startDate: DateTime.now(),
    ));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? AppColors.gold : AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [_namePage(), _levelPage(), _goalPage()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _next,
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_page < 2 ? 'Continuer' : 'Commencer'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _namePage() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('☪', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 32),
        Text('Bienvenue dans Hafiz', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Votre compagnon pour apprendre et mémoriser le Coran', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 48),
        TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            labelText: 'Votre prénom',
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold)),
            prefixIcon: const Icon(Icons.person, color: AppColors.gold),
          ),
        ),
      ],
    ),
  );

  Widget _levelPage() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📖', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 32),
        Text('Quel est votre niveau ?', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Cela nous aide à personnaliser votre programme', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 40),
        ...['débutant', 'intermédiaire', 'avancé'].map((lvl) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => setState(() => _level = lvl),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _level == lvl ? AppColors.primary.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _level == lvl ? AppColors.primary : Colors.transparent),
              ),
              child: Row(
                children: [
                  Icon(_level == lvl ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _level == lvl ? AppColors.primary : AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Text('${lvl[0].toUpperCase()}${lvl.substring(1)}',
                      style: TextStyle(
                        color: _level == lvl ? AppColors.text : AppColors.textSecondary,
                        fontWeight: _level == lvl ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 16,
                      )),
                ],
              ),
            ),
          ),
        )),
      ],
    ),
  );

  Widget _goalPage() => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🎯', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 32),
        Text('Objectif quotidien', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Text('Combien de versets voulez-vous apprendre par jour ?', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: 40),
        Wrap(
          spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
          children: [1, 3, 5, 7, 10].map((g) => InkWell(
            onTap: () => setState(() => _goal = g),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: _goal == g ? AppColors.gold : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$g', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _goal == g ? AppColors.background : AppColors.text)),
                  Text('verset${g > 1 ? "s" : ""}', style: TextStyle(fontSize: 11, color: _goal == g ? AppColors.background : AppColors.textSecondary)),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    ),
  );
}
