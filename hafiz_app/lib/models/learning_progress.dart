class LearningProgress {
  final int surahNumber;
  final int versesLearned;
  final int lastVerseNumber;
  final DateTime lastReviewed;
  final int masteryLevel;

  const LearningProgress({
    required this.surahNumber,
    required this.versesLearned,
    required this.lastVerseNumber,
    required this.lastReviewed,
    required this.masteryLevel,
  });

  LearningProgress copyWith({
    int? versesLearned,
    int? lastVerseNumber,
    DateTime? lastReviewed,
    int? masteryLevel,
  }) =>
      LearningProgress(
        surahNumber: surahNumber,
        versesLearned: versesLearned ?? this.versesLearned,
        lastVerseNumber: lastVerseNumber ?? this.lastVerseNumber,
        lastReviewed: lastReviewed ?? this.lastReviewed,
        masteryLevel: masteryLevel ?? this.masteryLevel,
      );

  Map<String, dynamic> toMap() => {
        'surah_number': surahNumber,
        'verses_learned': versesLearned,
        'last_verse_number': lastVerseNumber,
        'last_reviewed': lastReviewed.toIso8601String(),
        'mastery_level': masteryLevel,
      };

  factory LearningProgress.fromMap(Map<String, dynamic> map) => LearningProgress(
        surahNumber: map['surah_number'],
        versesLearned: map['verses_learned'],
        lastVerseNumber: map['last_verse_number'],
        lastReviewed: DateTime.parse(map['last_reviewed']),
        masteryLevel: map['mastery_level'],
      );
}
