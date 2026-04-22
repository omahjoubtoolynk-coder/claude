import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/surahs_data.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'surah_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = allSurahs.where((s) =>
      s.nameTranslit.toLowerCase().contains(_search.toLowerCase()) ||
      s.nameFrench.toLowerCase().contains(_search.toLowerCase()) ||
      s.nameArabic.contains(_search) ||
      s.number.toString() == _search
    ).toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Apprendre', style: Theme.of(context).textTheme.headlineMedium),
                Text('114 sourates • ${provider.totalVersesLearned} versets mémorisés',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une sourate...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true, fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textSecondary), onPressed: () { _ctrl.clear(); setState(() => _search = ''); })
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final surah = filtered[i];
                final progress = provider.getProgressForSurah(surah.number);
                final pct = progress != null && surah.verseCount > 0
                    ? progress.versesLearned / surah.verseCount : 0.0;
                return InkWell(
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => SurahScreen(surah: surah))),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pct > 0 ? AppColors.primary.withOpacity(0.2) : AppColors.surfaceVariant,
                          ),
                          child: Center(child: Text('${surah.number}',
                              style: TextStyle(color: pct > 0 ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold, fontSize: 13))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(surah.nameTranslit,
                                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600, fontSize: 15)),
                              Row(
                                children: [
                                  Text(surah.nameFrench,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const Text(' • ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text('${surah.verseCount} v.',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  const Text(' • ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                  Text(surah.revelationType,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                              if (pct > 0) ...[const SizedBox(height: 4),
                                ClipRRect(borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(value: pct, minHeight: 3,
                                    backgroundColor: AppColors.background,
                                    valueColor: AlwaysStoppedAnimation(pct == 1 ? AppColors.gold : AppColors.primary)))],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(surah.nameArabic,
                            style: const TextStyle(fontSize: 18, color: AppColors.gold)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
