import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart' as lg;

final logFile = File('logs.txt');

class Logger {
  final bool isProduction;
  late final lg.Logger _logger;

  Logger(this.isProduction) {
    var printer = isProduction ? lg.SimplePrinter(printTime: true, colors: false) : lg.PrettyPrinter(printTime: true);
    var output = isProduction ? lg.MultiOutput([lg.FileOutput(file: logFile), lg.ConsoleOutput()]) : lg.ConsoleOutput();

    _logger = lg.Logger(printer: printer, output: output);

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
