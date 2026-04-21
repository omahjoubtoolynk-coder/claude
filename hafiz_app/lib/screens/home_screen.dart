import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/daily_objective.dart';
import '../data/surahs_data.dart';
import 'learn_screen.dart';
import 'recite_screen.dart';
import 'progress_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final screens = [
      const _DashboardView(),
      const LearnScreen(),
      const ReciteScreen(),
      const ProgressScreen(),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: screens[provider.currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: provider.currentIndex,
        onTap: provider.setCurrentIndex,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Apprendre'),
          BottomNavigationBarItem(icon: Icon(Icons.mic_rounded), label: 'Réciter'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progrès'),
        ],
      ),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.userProfile;
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$greeting,', style: Theme.of(context).textTheme.bodyMedium),
                            Text(user?.name ?? 'Apprenant', style: Theme.of(context).textTheme.headlineMedium),
                          ],
                        ),
                      ),
                      _StreakBadge(streak: provider.streak),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _DailyCard(provider: provider),
                  const SizedBox(height: 24),
                  Text('Objectifs du jour', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _ObjectiveTile(objective: provider.todayObjectives[i]),
                childCount: provider.todayObjectives.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Continuer', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _ContinueSection(provider: provider),
                  const SizedBox(height: 20),
                  _QuoteCard(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF7B4F00), Color(0xFFFFD700)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🔥', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text('$streak jour${streak > 1 ? "s" : ""}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );
}

class _DailyCard extends StatelessWidget {
  final AppProvider provider;
  const _DailyCard({required this.provider});
  @override
  Widget build(BuildContext context) {
    final rate = provider.todayCompletionRate;
    final done = provider.todayObjectives.where((o) => o.isCompleted).length;
    final total = provider.todayObjectives.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.cardGradient1, AppColors.cardGradient2], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 86, height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: rate, strokeWidth: 7,
                  backgroundColor: AppColors.surface,
                  valueColor: AlwaysStoppedAnimation(rate == 1 ? AppColors.gold : AppColors.primary),
                ),
                Text('${(rate * 100).round()}%',
                    style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 17)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Progression du jour', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('$done/$total objectifs complétés', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text('${provider.todayVersesLearned} versets appris aujourd\'hui',
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w500, fontSize: 13)),
                Text('Total : ${provider.totalVersesLearned} versets mémorisés',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  final DailyObjective objective;
  const _ObjectiveTile({required this.objective});
  @override
  Widget build(BuildContext context) {
    final config = {
      ObjectiveType.learning: ('📚', AppColors.primary),
      ObjectiveType.revision: ('🔄', AppColors.warning),
      ObjectiveType.listening: ('🎧', Colors.blue),
      ObjectiveType.recitation: ('🎤', Colors.purple),
    };
    final (icon, color) = config[objective.type]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: objective.isCompleted ? AppColors.success.withOpacity(0.4) : Colors.transparent),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(objective.title,
                    style: TextStyle(
                      color: objective.isCompleted ? AppColors.textSecondary : AppColors.text,
                      fontWeight: FontWeight.w500,
                      decoration: objective.isCompleted ? TextDecoration.lineThrough : null,
                      fontSize: 13,
                    )),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: objective.progress, minHeight: 5,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation(color as Color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('${objective.completed}/${objective.target}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (objective.isCompleted) ...[const SizedBox(width: 6), const Icon(Icons.check_circle, color: AppColors.success, size: 18)],
        ],
      ),
    );
  }
}

class _ContinueSection extends StatelessWidget {
  final AppProvider provider;
  const _ContinueSection({required this.provider});
  @override
  Widget build(BuildContext context) {
    final inProgress = provider.surahsInProgress;
    if (inProgress.isEmpty) {
      return InkWell(
        onTap: () => provider.setCurrentIndex(1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              const Text('📖', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Commencer l\'apprentissage', style: Theme.of(context).textTheme.titleMedium),
                    Text('Choisissez une sourate', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: AppColors.textSecondary, size: 14),
            ],
          ),
        ),
      );
    }
    return Column(
      children: inProgress.map((surah) {
        final p = provider.getProgressForSurah(surah.number)!;
        return InkWell(
          onTap: () => provider.setCurrentIndex(1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.2)),
                  child: Center(child: Text('${surah.number}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surah.nameTranslit, style: Theme.of(context).textTheme.titleMedium),
                    Text('${p.versesLearned}/${surah.verseCount} versets', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                )),
                Text(surah.nameArabic, style: const TextStyle(fontSize: 18, color: AppColors.gold)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.12), AppColors.gold.withOpacity(0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        const Text('وَرَتِّلِ القُرآنَ تَرتِيلاً',
            style: TextStyle(fontSize: 20, color: AppColors.gold, height: 2), textAlign: TextAlign.center, textDirection: TextDirection.rtl),
        const SizedBox(height: 8),
        Text('« Récite le Coran lentement et distinctement »', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        const Text('Sourate Al-Muzzammil (73:4)', style: TextStyle(color: AppColors.gold, fontSize: 11)),
      ],
    ),
  );
}
