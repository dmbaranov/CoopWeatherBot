import 'dart:io';
import 'dart:convert';

class SwearwordsManager {
  late Map<String, String> swearwords;

  Future<void> initialize() async {
    var rawSwearwords = await File('assets/swearwords.json').readAsString();

    swearwords = Map<String, String>.from(json.decode(rawSwearwords));
  }

  String get(String key, [Map<String, String>? replacements]) {
    var rawString = swearwords[key] as String;

    if (replacements == null) {
      return rawString;
    }

    replacements.keys.forEach((replacementKey) {
      rawString = rawString.replaceAll('\$$replacementKey', replacements[replacementKey] as String);
    });

    return rawString;
  }
}
