import 'dart:io';
import 'dart:convert';

class SwearwordsManager {
  Map<String, String> swearwords;

  SwearwordsManager() {
    initSwearwords();
  }

  Future<void> initSwearwords() async {
    var rawSwearwords = await File('assets/swearwords.json').readAsString();

    swearwords = Map<String, String>.from(json.decode(rawSwearwords));
  }

  String get(String key, [Map<String, String> replacements]) {
    var rawString = swearwords[key];

    if (replacements == null) return rawString;

    replacements.keys.forEach((replacementKey) {
      rawString = rawString.replaceAll('\$$replacementKey', replacements[replacementKey]);
    });

    return rawString;
  }
}
