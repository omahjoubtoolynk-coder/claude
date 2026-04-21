import 'dart:convert';
import 'package:http/http.dart' as http;

class QuranVerse {
  final int number;
  final String text;
  final String translation;
  final String audioUrl;

  const QuranVerse({
    required this.number,
    required this.text,
    required this.translation,
    required this.audioUrl,
  });
}

class QuranService {
  static const _baseUrl = 'https://api.alquran.cloud/v1';
  static const _audioBase =
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy';

  static final Map<int, List<QuranVerse>> _cache = {};

  static Future<List<QuranVerse>> getSurahVerses(int surahNumber) async {
    if (_cache.containsKey(surahNumber)) return _cache[surahNumber]!;
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$_baseUrl/surah/$surahNumber/ar.uthmani')),
        http.get(Uri.parse('$_baseUrl/surah/$surahNumber/fr.hamidullah')),
      ]);
      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final arabicData =
            jsonDecode(responses[0].body)['data']['ayahs'] as List;
        final frenchData =
            jsonDecode(responses[1].body)['data']['ayahs'] as List;
        final verses = List.generate(arabicData.length, (i) {
          final verseNum = arabicData[i]['numberInSurah'] as int;
          return QuranVerse(
            number: verseNum,
            text: arabicData[i]['text'],
            translation: frenchData[i]['text'],
            audioUrl: '$_audioBase/$surahNumber/$verseNum.mp3',
          );
        });
        _cache[surahNumber] = verses;
        return verses;
      }
    } catch (_) {}
    return [];
  }
}
