import 'dart:convert';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:weather/src/injector/injection.dart';
import 'package:weather/src/utils/logger.dart';

const swearwordsConfigs = ['sample', 'angry', 'basic', 'fun'];
const configsBasePath = 'assets/swearwords';
const defaultSwearwords = 'basic';

@Order(2)
@singleton
class Swearwords {
  final Logger _logger;
  final Map<String, Map<String, dynamic>> _swearwordsTypeToSwearwords = {};
  final Map<String, Map<String, dynamic>> _chatIdsToSwearwords = {};

  Swearwords() : _logger = getIt<Logger>();

  String get defaultConfig => defaultSwearwords;

  @PostConstruct()
  void initialize() {
    swearwordsConfigs.forEach((config) {
      try {
        var file = File('$configsBasePath/swearwords.$config.json').readAsStringSync();

        _swearwordsTypeToSwearwords[config] = json.decode(file);
      } catch (e) {
        _logger.e('Cannot setup $config swearwords config', e);
      }
    });
  }

  String getText(String chatId, String path, [Map<String, String>? replacements]) {
    var swearwords = _chatIdsToSwearwords[chatId] ?? _swearwordsTypeToSwearwords[defaultSwearwords];

    if (swearwords == null) {
      return path;
    }

    var text = _getNestedProperty(swearwords, path.split('.')) ?? path;

    if (replacements == null) {
      return text;
    }

    replacements.keys.forEach((replacementKey) {
      text = text.replaceAll('\$$replacementKey', replacements[replacementKey]!);
    });

    return text;
  }

  Future<bool> canSetSwearwordsConfig(String config) async {
    return File('$configsBasePath/swearwords.$config.json').exists();
  }

  void setChatConfig(String chatId, String config) {
    _chatIdsToSwearwords[chatId] = _swearwordsTypeToSwearwords[config]!;
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
