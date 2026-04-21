import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/learning_progress.dart';
import '../models/daily_objective.dart';
import '../services/database_service.dart';
import '../data/surahs_data.dart';

class AppProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  List<LearningProgress> _progressList = [];
  List<DailyObjective> _todayObjectives = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  int _streak = 0;
  int _totalVersesLearned = 0;
  int _todayVersesLearned = 0;

  UserProfile? get userProfile => _userProfile;
  List<LearningProgress> get progressList => _progressList;
  List<DailyObjective> get todayObjectives => _todayObjectives;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;
  int get streak => _streak;
  int get totalVersesLearned => _totalVersesLearned;
  int get todayVersesLearned => _todayVersesLearned;
  bool get isOnboarded => _userProfile != null;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await DatabaseService.instance.initDatabase();
    await _loadUserProfile();
    if (_userProfile != null) {
      await _loadProgress();
      await _loadTodayObjectives();
      await _calculateStats();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    if (name != null) {
      _userProfile = UserProfile(
        name: name,
        level: prefs.getString('user_level') ?? 'débutant',
        dailyGoal: prefs.getInt('daily_goal') ?? 3,
        startDate: DateTime.tryParse(prefs.getString('start_date') ?? '') ?? DateTime.now(),
      );
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', profile.name);
    await prefs.setString('user_level', profile.level);
    await prefs.setInt('daily_goal', profile.dailyGoal);
    await prefs.setString('start_date', profile.startDate.toIso8601String());
    _userProfile = profile;
    await _loadProgress();
    await _generateObjectives();
    await _loadTodayObjectives();
    notifyListeners();
  }

  Future<void> _loadProgress() async {
    _progressList = await DatabaseService.instance.getAllProgress();
  }

  Future<void> _loadTodayObjectives() async {
    _todayObjectives = await DatabaseService.instance.getTodayObjectives();
    if (_todayObjectives.isEmpty) {
      await _generateObjectives();
      _todayObjectives = await DatabaseService.instance.getTodayObjectives();
    }
  }

  Future<void> _generateObjectives() async {
    if (_userProfile == null) return;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final objectives = <DailyObjective>[];

    objectives.add(DailyObjective(
      id: '${dateStr}_learn',
      date: dateStr,
      type: ObjectiveType.learning,
      title: 'Apprendre ${_userProfile!.dailyGoal} nouveaux versets',
      target: _userProfile!.dailyGoal,
      completed: 0,
    ));

    final learnedCount = _progressList.fold(0, (sum, p) => sum + p.versesLearned);
    if (learnedCount > 0) {
      final revisionTarget = (learnedCount * 0.1).ceil().clamp(3, 15);
      objectives.add(DailyObjective(
        id: '${dateStr}_review',
        date: dateStr,
        type: ObjectiveType.revision,
        title: 'Réviser $revisionTarget versets',
        target: revisionTarget,
        completed: 0,
      ));
    }

    objectives.add(DailyObjective(
      id: '${dateStr}_listen',
      date: dateStr,
      type: ObjectiveType.listening,
      title: 'Écouter 1 sourate complète',
      target: 1,
      completed: 0,
    ));

    objectives.add(DailyObjective(
      id: '${dateStr}_recite',
      date: dateStr,
      type: ObjectiveType.recitation,
      title: 'Réciter 1 verset avec correction',
      target: 1,
      completed: 0,
    ));

    await DatabaseService.instance.saveObjectives(objectives);
  }

  Future<void> markObjectiveProgress(String objectiveId, int progress) async {
    final idx = _todayObjectives.indexWhere((o) => o.id == objectiveId);
    if (idx != -1) {
      _todayObjectives[idx] = _todayObjectives[idx].copyWith(
        completed: (_todayObjectives[idx].completed + progress)
            .clamp(0, _todayObjectives[idx].target),
      );
      await DatabaseService.instance.updateObjective(_todayObjectives[idx]);
      notifyListeners();
    }
  }

  Future<void> recordVerseLearned(int surahNumber, int verseNumber) async {
    var progress = _progressList.firstWhere(
      (p) => p.surahNumber == surahNumber,
      orElse: () => LearningProgress(
        surahNumber: surahNumber,
        versesLearned: 0,
        lastVerseNumber: 0,
        lastReviewed: DateTime.now(),
        masteryLevel: 0,
      ),
    );

    if (verseNumber > progress.lastVerseNumber) {
      progress = progress.copyWith(
        versesLearned: progress.versesLearned + 1,
        lastVerseNumber: verseNumber,
        lastReviewed: DateTime.now(),
      );
      final idx = _progressList.indexWhere((p) => p.surahNumber == surahNumber);
      if (idx != -1) {
        _progressList[idx] = progress;
      } else {
        _progressList.add(progress);
      }
      await DatabaseService.instance.saveProgress(progress);
      _todayVersesLearned++;

      final learnObj = _todayObjectives.firstWhere(
        (o) => o.type == ObjectiveType.learning,
        orElse: () => _todayObjectives.first,
      );
      await markObjectiveProgress(learnObj.id, 1);
      await _calculateStats();
      notifyListeners();
    }
  }

  Future<void> recordRecitationDone() async {
    final obj = _todayObjectives.firstWhere(
      (o) => o.type == ObjectiveType.recitation,
      orElse: () => _todayObjectives.first,
    );
    await markObjectiveProgress(obj.id, 1);
  }

  Future<void> recordListeningDone() async {
    final obj = _todayObjectives.firstWhere(
      (o) => o.type == ObjectiveType.listening,
      orElse: () => _todayObjectives.first,
    );
    await markObjectiveProgress(obj.id, 1);
  }

  Future<void> _calculateStats() async {
    _totalVersesLearned = _progressList.fold(0, (sum, p) => sum + p.versesLearned);
    _streak = await DatabaseService.instance.calculateStreak();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  LearningProgress? getProgressForSurah(int surahNumber) {
    try {
      return _progressList.firstWhere((p) => p.surahNumber == surahNumber);
    } catch (_) {
      return null;
    }
  }

  double get todayCompletionRate {
    if (_todayObjectives.isEmpty) return 0;
    final completed = _todayObjectives.where((o) => o.isCompleted).length;
    return completed / _todayObjectives.length;
  }

  List<SurahInfo> get surahsInProgress => allSurahs
      .where((s) {
        final p = getProgressForSurah(s.number);
        return p != null && p.versesLearned > 0 && p.versesLearned < s.verseCount;
      })
      .take(3)
      .toList();
}
