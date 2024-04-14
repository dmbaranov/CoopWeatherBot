import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as lg;

final logFile = File('logs.txt');

class Logger {
  final bool isProduction;
  late final lg.Logger _logger;
  static Logger? _instance;

  Logger._internal(this.isProduction) {
    var printer = isProduction ? lg.SimplePrinter(printTime: true, colors: false) : lg.PrettyPrinter(printTime: true, methodCount: 4);
    var output = isProduction ? lg.MultiOutput([lg.FileOutput(file: logFile), lg.ConsoleOutput()]) : lg.ConsoleOutput();
    var filter = CustomLogFilter();

    _logger = lg.Logger(printer: printer, output: output, filter: filter);
    _logger.i('Logger initialized in ${isProduction ? 'prod' : 'dev'} mode');
  }

  factory Logger({required bool isProduction}) {
    _instance ??= Logger._internal(isProduction);
    return _instance!;
  }

  void i(message) {
    _logger.i(message);
  }

  void w(message) {
    _logger.w(message);
  }

  void e(message, [Object? error]) {
    _logger.e(message, error: error);
    if (isProduction) {
      _logger.e(StackTrace.current);
    }
  }
}

class CustomLogFilter extends lg.LogFilter {
  @override
  bool shouldLog(lg.LogEvent event) {
    // https: //github.com/simc/logger/issues/48
    return true;
  }
}

@module
abstract class LoggerModule {
  @dev
  Logger get devLogger => Logger(isProduction: false);

  @prod
  Logger get prodLogger => Logger(isProduction: true);
}
