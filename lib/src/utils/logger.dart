import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as lg;

class Logger {
  final bool isProduction;
  late final lg.Logger _logger;

  Logger(this.isProduction) {
    _logger = lg.Logger(printer: lg.PrettyPrinter(methodCount: isProduction ? 0 : 6, printTime: true));

    i('Logger initialized in ${isProduction ? 'prod' : 'dev'} mode');
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

@module
abstract class LoggerModule {
  @dev
  Logger get devLogger => Logger(false);

  @prod
  Logger get prodLogger => Logger(true);
}
