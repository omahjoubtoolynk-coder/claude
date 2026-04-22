import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/surahs_data.dart';
import '../providers/app_provider.dart';
import '../services/quran_service.dart';
import '../services/ai_correction_service.dart';
import '../theme/app_theme.dart';

class ReciteScreen extends StatefulWidget {
  final SurahInfo? surah;
  const ReciteScreen({super.key, this.surah});
  @override
  State<ReciteScreen> createState() => _ReciteScreenState();
}

class _ReciteScreenState extends State<ReciteScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _listening = false;
  String _recognized = '';
  String _feedback = '';
  bool _loadingFeedback = false;
  bool _loadingVerses = false;
  List<QuranVerse> _verses = [];
  int _verseIndex = 0;
  SurahInfo? _selectedSurah;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _selectedSurah = widget.surah ?? allSurahs.first;
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.stop();
    _initStt();
    _loadVerses();
  }

  Future<void> _initStt() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      _sttAvailable = await _stt.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadVerses() async {
    if (_selectedSurah == null) return;
    setState(() { _loadingVerses = true; _verses = []; _verseIndex = 0; });
    final verses = await QuranService.getSurahVerses(_selectedSurah!.number);
    if (mounted) setState(() { _verses = verses; _loadingVerses = false; });
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stt.stop();
      setState(() { _listening = false; });
      _pulseCtrl.stop();
      _pulseCtrl.reset();
      if (_recognized.isNotEmpty || _verses.isNotEmpty) await _getFeedback();
    } else {
      setState(() { _recognized = ''; _feedback = ''; _listening = true; });
      _pulseCtrl.repeat(reverse: true);
      await _stt.listen(
        onResult: (r) => setState(() => _recognized = r.recognizedWords),
        localeId: 'ar_SA',
        cancelOnError: true,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      );
    }
  }

  Future<void> _getFeedback() async {
    if (_verses.isEmpty || _selectedSurah == null) return;
    setState(() { _loadingFeedback = true; _feedback = ''; });
    final verse = _verses[_verseIndex];
    final result = await AICorrectionService.correctRecitation(
      recognizedText: _recognized,
      correctText: verse.text,
      surahName: _selectedSurah!.nameTranslit,
      verseNumber: verse.number,
    );
    if (mounted) {
      setState(() { _feedback = result; _loadingFeedback = false; });
      context.read<AppProvider>().recordRecitationDone();
    }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _stt.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final currentVerse = _verses.isNotEmpty ? _verses[_verseIndex] : null;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Réciter', style: Theme.of(context).textTheme.headlineMedium),
            Text('Enregistrez votre récitation et obtenez une correction', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            // Surah selector
            InkWell(
              onTap: _showSurahPicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.book, color: AppColors.gold, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_selectedSurah?.nameTranslit ?? 'Choisir une sourate',
                        style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w500))),
                    if (_selectedSurah != null)
                      Text(_selectedSurah!.nameArabic, style: const TextStyle(color: AppColors.gold, fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            // Verse selector
            if (_verses.isNotEmpty) ...[const SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    onPressed: _verseIndex > 0 ? () => setState(() { _verseIndex--; _recognized = ''; _feedback = ''; }) : null,
                    icon: const Icon(Icons.chevron_left), color: AppColors.gold,
                  ),
                  Expanded(child: Center(
                    child: Text('Verset ${_verseIndex + 1} / ${_verses.length}',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  )),
                  IconButton(
                    onPressed: _verseIndex < _verses.length - 1 ? () => setState(() { _verseIndex++; _recognized = ''; _feedback = ''; }) : null,
                    icon: const Icon(Icons.chevron_right), color: AppColors.gold,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Verse display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.cardGradient1, AppColors.cardGradient2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gold.withOpacity(0.2)),
              ),
              child: _loadingVerses
                  ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
                  : currentVerse == null
                      ? const Text('Sélectionnez une sourate', textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary))
                      : Column(
                          children: [
                            Text(currentVerse.text,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 24, color: AppColors.text, height: 1.8)),
                            const SizedBox(height: 12),
                            Text(currentVerse.translation,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                          ],
                        ),
            ),
            const SizedBox(height: 20),
            // Record button
            Center(
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, child) => Transform.scale(
                  scale: _listening ? _pulse.value : 1.0,
                  child: GestureDetector(
                    onTap: _sttAvailable ? _toggleListening : null,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listening ? AppColors.error : AppColors.primary,
                        boxShadow: [BoxShadow(
                          color: (_listening ? AppColors.error : AppColors.primary).withOpacity(0.4),
                          blurRadius: _listening ? 20 : 10, spreadRadius: _listening ? 4 : 2,
                        )],
                      ),
                      child: Icon(_listening ? Icons.stop : Icons.mic,
                          color: Colors.white, size: 36),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(
              _sttAvailable ? (_listening ? 'Appuyez pour arrêter' : 'Appuyez pour réciter')
                  : 'Microphone non disponible',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )),
            // Recognized text
            if (_recognized.isNotEmpty) ...[const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Votre récitation reconnue :', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(_recognized, textDirection: TextDirection.rtl, textAlign: TextAlign.right,
                        style: const TextStyle(color: AppColors.text, fontSize: 18, height: 1.6)),
                  ],
                ),
              ),
            ],
            // Feedback
            if (_loadingFeedback) ...[const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator(color: AppColors.gold)),
              const SizedBox(height: 8),
              const Center(child: Text('Analyse en cours...', style: TextStyle(color: AppColors.textSecondary))),
            ],
            if (_feedback.isNotEmpty && !_loadingFeedback) ...[const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.gold.withOpacity(0.1), AppColors.gold.withOpacity(0.03)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
                      SizedBox(width: 6),
                      Text('Correction IA', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                    ]),
                    const SizedBox(height: 10),
                    Text(_feedback, style: const TextStyle(color: AppColors.text, height: 1.6)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSurahPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView.builder(
        itemCount: allSurahs.length,
        itemBuilder: (ctx, i) {
          final s = allSurahs[i];
          return ListTile(
            leading: Text('${s.number}', style: const TextStyle(color: AppColors.textSecondary)),
            title: Text(s.nameTranslit, style: const TextStyle(color: AppColors.text)),
            trailing: Text(s.nameArabic, style: const TextStyle(color: AppColors.gold, fontSize: 16)),
            onTap: () {
              setState(() { _selectedSurah = s; _recognized = ''; _feedback = ''; });
              Navigator.pop(ctx);
              _loadVerses();
            },
          );
        },
      ),
    );
  }
}
