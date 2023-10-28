import 'package:translator/translator.dart';

class Translatorapi {
  static Future<String> translate(
      String message, String fromLanguageCode, String toLanguageCode) async {
    final translation = await GoogleTranslator()
        .translate(message, from: 'auto', to: toLanguageCode);
    return translation.text;
  }
}
