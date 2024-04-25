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
  final Map<String, Map<String, String>> _swearwordsTypeToSwearwords = {};

  Swearwords() : _logger = getIt<Logger>();

  String get defaultConfig => defaultSwearwords;

  @PostConstruct()
  void initialize() {
    swearwordsConfigs.forEach((config) {
      try {
        var file = File('$configsBasePath/swearwords.$config.json').readAsStringSync();

        _swearwordsTypeToSwearwords[config] = Map.castFrom(jsonDecode(file));
      } catch (e) {
        _logger.e('Cannot setup $config swearwords config', e);
      }
    });
  }

  String getText(String swearwordsType, String path, [Map<String, String>? replacements]) {
    Map<String, String> swearwords = _swearwordsTypeToSwearwords[swearwordsType] ?? _swearwordsTypeToSwearwords[defaultSwearwords]!;
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
