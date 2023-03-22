import 'dart:io';
import 'dart:convert';

class SwearwordsManager {
  late Map<String, dynamic> _swearwords;

  Future<void> initialize() async {
    var rawSwearwords = await File('assets/swearwords.json').readAsString();

    _swearwords = Map<String, dynamic>.from(json.decode(rawSwearwords));
  }

  String get(String path, [Map<String, String>? replacements]) {
    var rawString = _getNestedProperty(_swearwords, path.split('.')) ?? path;

    if (replacements == null) {
      return rawString;
    }

    replacements.keys.forEach((replacementKey) {
      rawString = rawString.replaceAll('\$$replacementKey', replacements[replacementKey] as String);
    });

    return rawString;
  }

  String? _getNestedProperty(Map<String, dynamic> object, List<String> path) {
    if (path.length == 1) {
      return object[path[0]];
    }

    var firstItem = path.first;

    if (object[firstItem] != null) {
      return _getNestedProperty(object[firstItem], path.sublist(1));
    }

    return null;
  }
}
