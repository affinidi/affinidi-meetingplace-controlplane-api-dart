import 'package:logging/logging.dart' as logging;
import '../../core/logger/logger.dart';

class BasicLogger implements Logger {
  BasicLogger() : _logger = logging.Logger('BasicLogger') {
    logging.Logger.root.level = logging.Level.ALL;
    logging.Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  final logging.Logger _logger;

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.log(logging.Level.FINER, message, error, stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.log(logging.Level.SEVERE, message, error, stackTrace);
  }

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.log(logging.Level.INFO, message, error, stackTrace);
  }

  @override
  void warn(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.log(logging.Level.WARNING, message, error, stackTrace);
  }
}
