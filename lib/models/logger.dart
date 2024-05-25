import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:spotifyre/utils/platform.dart';

final _loggerFactory = spotifyreLogger();
final logEnv = {
  if (!kIsWeb) ...Platform.environment,
};

spotifyreLogger getLogger<T>(T owner) {
  _loggerFactory.owner = owner is String ? owner : owner.toString();
  return _loggerFactory;
}

Future<File> getLogsPath() async {
  String dir = (await getApplicationDocumentsDirectory()).path;
  if (kIsAndroid) {
    dir = (await getExternalStorageDirectory())?.path ?? "";
  }

  if (kIsMacOS) {
    dir = path.join((await getLibraryDirectory()).path, "Logs");
  }
  final file = File(path.join(dir, ".spotifyre_logs"));
  if (!await file.exists()) {
    await file.create();
  }
  return file;
}

class spotifyreLogger extends Logger {
  String? owner;
  spotifyreLogger([this.owner]) : super(filter: _spotifyreLogFilter());

  @override
  void log(Level level, dynamic message,
      {Object? error, StackTrace? stackTrace, DateTime? time}) async {
    if (!kIsWeb) {
      if (level == Level.error) {
        String dir = (await getApplicationDocumentsDirectory()).path;

        if (kIsAndroid) {
          dir = (await getExternalStorageDirectory())?.path ?? "";
        }

        if (kIsMacOS) {
          dir = path.join((await getLibraryDirectory()).path, "Logs");
        }

        await File(path.join(dir, ".spotifyre_logs")).writeAsString(
            "[${DateTime.now()}]\n$message\n$stackTrace",
            mode: FileMode.writeOnlyAppend);
      }
    }

    super.log(level, "[$owner] $message", error: error, stackTrace: stackTrace);
  }
}

class _spotifyreLogFilter extends DevelopmentFilter {
  @override
  bool shouldLog(LogEvent event) {
    if ((logEnv["DEBUG"] == "true" && event.level == Level.debug) ||
        (logEnv["VERBOSE"] == "true" && event.level == Level.trace) ||
        (logEnv["ERROR"] == "true" && event.level == Level.error)) {
      return true;
    }
    return super.shouldLog(event);
  }
}
