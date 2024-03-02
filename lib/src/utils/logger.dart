import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as lg;

@singleton
class Logger {
  late final lg.Logger _logger;

  Logger() {
    _logger = lg.Logger(printer: lg.PrettyPrinter(methodCount: 6, printTime: true));

    i('Logger initialized');
  }

  void i(message) {
    _logger.i(message);
  }

  void w(message) {
    _logger.w(message);
  }

  void e(message, [Object? error]) {
    _logger.e(message, error: error);
  }
}
