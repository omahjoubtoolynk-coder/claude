import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../data/surahs_data.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Map<String, dynamic>> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await DatabaseService.instance.getWeeklyStats();
    if (mounted) setState(() => _weeklyStats = stats);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final maxVal = _weeklyStats.isEmpty
        ? 1.0
        : _weeklyStats
            .map((s) => (s['verses'] as int).toDouble())
            .reduce((a, b) => a > b ? a : b)
            .clamp(1.0, double.infinity);

    final surahsStarted = provider.progressList.where((p) => p.versesLearned > 0).length;
    final surahsCompleted = provider.progressList.where((p) {
      final surah = allSurahs.firstWhere(
        (s) => s.number == p.surahNumber,
        orElse: () => allSurahs.first,
      );
      return p.versesLearned >= surah.verseCount;
    }).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mes Progrès', style: Theme.of(context).textTheme.headlineMedium),
            Text('Votre parcours d\'apprentissage', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Row(
              children: [
                _StatCard(value: '${provider.totalVersesLearned}', label: 'Versets appris', icon: '📚', color: AppColors.primary),
                const SizedBox(width: 10),
                _StatCard(value: '${provider.streak}', label: 'Jours consécutifs', icon: '🔥', color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatCard(value: '$surahsStarted', label: 'Sourates commencées', icon: '📖', color: Colors.blue),
                const SizedBox(width: 10),
                _StatCard(value: '$surahsCompleted', label: 'Sourates terminées', icon: '★', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 24),
            Text('Activité des 7 derniers jours', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _weeklyStats.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : BarChart(
                      BarChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => const FlLine(
                            color: AppColors.surfaceVariant,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= _weeklyStats.length) return const SizedBox();
                                final wd = _weeklyStats[idx]['weekday'] as int;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    days[(wd - 1) % 7],
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: List.generate(_weeklyStats.length, (i) {
                          final val = (_weeklyStats[i]['verses'] as int).toDouble();
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: val,
                                width: 18,
                                borderRadius: BorderRadius.circular(4),
                                color: val > 0 ? AppColors.primary : AppColors.surfaceVariant,
                              ),
                            ],
                          );
                        }),
                        maxY: maxVal * 1.3,
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Text('Sourates en cours', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...provider.progressList.where((p) => p.versesLearned > 0).map((p) {
              final surah = allSurahs.firstWhere(
                (s) => s.number == p.surahNumber,
                orElse: () => allSurahs.first,
              );
              final pct = p.versesLearned / surah.verseCount;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                      child: Center(
                        child: Text(
                          '${surah.number}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                surah.nameTranslit,
                                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                '${p.versesLearned}/${surah.verseCount}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct == 1 ? AppColors.gold : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (provider.progressList.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'Commencez à apprendre pour voir votre progression ici',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String icon;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      );
}
