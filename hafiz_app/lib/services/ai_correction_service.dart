import 'dart:convert';
import 'package:http/http.dart' as http;

class AICorrectionService {
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY', defaultValue: '');

  static Future<String> correctRecitation({
    required String recognizedText,
    required String correctText,
    required String surahName,
    required int verseNumber,
  }) async {
    if (_apiKey.isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'Content-Type': 'application/json',
                'x-api-key': _apiKey,
                'anthropic-version': '2023-06-01',
              },
              body: jsonEncode({
                'model': 'claude-opus-4-7',
                'max_tokens': 600,
                'messages': [
                  {
                    'role': 'user',
                    'content':
                        'Tu es un maître en récitation coranique et tajweed. Un élève récite le verset $verseNumber de la sourate $surahName.\n\nVerset correct :\n$correctText\n\nRécitation reconnue :\n${recognizedText.isEmpty ? "(aucun texte détecté)" : recognizedText}\n\nDonne un retour bienveillant en français :\n1. Évaluation (Excellent / Bien / À améliorer)\n2. Erreurs spécifiques si nécessaire\n3. Un conseil tajweed pratique\n4. Un mot d\'encouragement islamique\n\nSois concis et pédagogique.',
                  }
                ],
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['content'][0]['text'];
        }
      } catch (_) {}
    }
    return _localFeedback(recognizedText, correctText);
  }

  static String _localFeedback(String recognized, String correct) {
    if (recognized.isEmpty) {
      return '🎙️ Votre récitation n\'a pas pu être capturée. Parlez plus fort et clairement près du microphone.\n\n💡 Conseil : Écoutez le verset plusieurs fois avant de réciter.\n\n🤲 Barak Allahou fik pour vos efforts !';
    }
    final similarity = _similarity(recognized, correct);
    if (similarity > 0.75) {
      return '✅ Excellente récitation ! Votre prononciation est très bonne.\n\n💡 Continuez à pratiquer pour perfectionner le tajweed.\n\n🌟 Macha Allah, continuez ainsi !';
    } else if (similarity > 0.4) {
      return '📚 Bonne récitation avec quelques points à améliorer.\n\n💡 Conseil : Réécoutez le verset et portez attention aux voyelles longues (mad).\n\n🤲 Allez, encore un effort !';
    } else {
      return '📚 Cette récitation nécessite plus de pratique.\n\n💡 Conseil : Mémorisez le verset visuellement puis écoutez-le plusieurs fois avant de réciter.\n\n🌱 Chaque grand hafiz a commencé par les mêmes premiers pas !';
    }
  }

  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final aSet = a.replaceAll(' ', '').split('');
    final bSet = b.replaceAll(' ', '').split('');
    int matches = 0;
    for (final ch in aSet) {
      if (bSet.contains(ch)) matches++;
    }
    return matches / bSet.length.clamp(1, 10000);
  }
}
