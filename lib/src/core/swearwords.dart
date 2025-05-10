import 'dart:convert';
import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:weather/src/core/chat_config.dart';
import 'package:weather/src/utils/logger.dart';

const swearwordsConfigs = ['sample', 'angry', 'basic', 'fun'];
const configsBasePath = 'assets/swearwords';
const defaultSwearwords = 'basic';

@singleton
class Swearwords {
  final Logger _logger;
  final ChatConfig _chatConfig;
  final Map<String, Map<String, dynamic>> _swearwordsTypeToSwearwords = {};

  Swearwords(this._logger, this._chatConfig);

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
    var chatSwearwords = _chatConfig.getSwearwordsConfig(chatId)?.swearwords ?? defaultConfig;
    var swearwords = _swearwordsTypeToSwearwords[chatSwearwords]!;

    var text = _getNestedProperty(swearwords, path.split('.')) ?? path;

    if (replacements == null) {
      return text;
    }

    replacements.keys.forEach((replacementKey) {
      text = text.replaceAll('\$$replacementKey', replacements[replacementKey]!);
    });

    return text;
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
