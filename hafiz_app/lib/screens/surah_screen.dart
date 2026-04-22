import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../data/surahs_data.dart';
import '../providers/app_provider.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import 'recite_screen.dart';

class SurahScreen extends StatefulWidget {
  final SurahInfo surah;
  const SurahScreen({super.key, required this.surah});
  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<QuranVerse> _verses = [];
  bool _loading = true;
  int? _playingVerse;
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _load();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingVerse = null);
      }
    });
  }

  Future<void> _load() async {
    final verses = await QuranService.getSurahVerses(widget.surah.number);
    if (mounted) setState(() { _verses = verses; _loading = false; });
  }

  Future<void> _playVerse(QuranVerse verse) async {
    if (_playingVerse == verse.number) {
      await _player.stop();
      setState(() => _playingVerse = null);
      return;
    }
    setState(() => _playingVerse = verse.number);
    try {
      await _player.setUrl(verse.audioUrl);
      await _player.play();
    } catch (_) {
      setState(() => _playingVerse = null);
    }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final progress = provider.getProgressForSurah(widget.surah.number);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.surah.nameTranslit),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(widget.surah.nameArabic,
                  style: const TextStyle(fontSize: 20, color: AppColors.gold)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.surah.nameFrench,
                              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                          Text('${widget.surah.verseCount} versets • ${widget.surah.revelationType}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          if (progress != null && progress.versesLearned > 0)
                            Text('${progress.versesLearned} versets appris',
                                style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                        ],
                      )),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ReciteScreen(surah: widget.surah))),
                        icon: const Icon(Icons.mic, size: 16),
                        label: const Text('Réciter'),
                        style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _verses.isEmpty
                      ? const Center(child: Text('Impossible de charger les versets.\nVérifiez votre connexion.',
                          textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _verses.length,
                          itemBuilder: (ctx, i) {
                            final verse = _verses[i];
                            final isLearned = progress != null && verse.number <= progress.lastVerseNumber;
                            final isPlaying = _playingVerse == verse.number;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isLearned ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: isLearned ? AppColors.primary.withOpacity(0.3) : Colors.transparent),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 30, height: 30,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.gold.withOpacity(0.15)),
                                          child: Center(child: Text('${verse.number}',
                                              style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold))),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () => _playVerse(verse),
                                          icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle,
                                              color: isPlaying ? AppColors.error : AppColors.gold, size: 28),
                                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(width: 8),
                                        if (!isLearned)
                                          GestureDetector(
                                            onTap: () => provider.recordVerseLearned(widget.surah.number, verse.number),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(20)),
                                              child: const Text('Appris', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                                            ),
                                          )
                                        else
                                          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(verse.text,
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 22, color: AppColors.text, height: 1.8)),
                                    const SizedBox(height: 8),
                                    Text(verse.translation,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5, fontStyle: FontStyle.italic)),
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
