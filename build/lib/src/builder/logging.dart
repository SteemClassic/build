import 'dart:async';

import 'package:logging/logging.dart';

const Symbol logKey = #buildLog;

final _default = Logger('build.fallback');

/// The log instance for the currently running BuildStep.
///
/// Will be `null` when not running within a build.
Logger get log => Zone.current[logKey] as Logger ?? _default;

/// Runs [fn] in an error handling [Zone].
///
/// Any calls to [print] will be logged with `log.warning`, and any errors will
/// be logged with `log.severe`.
///
/// Completes with the first error or result of `fn`, whichever comes first.
Future<T> scopeLogAsync<T>(Future<T> fn(), Logger log) {
  var done = Completer<T>();
  runZoned(fn,
      zoneSpecification:
          ZoneSpecification(print: (self, parent, zone, message) {
        log.warning(message);
      }),
      zoneValues: {logKey: log},
      onError: (Object e, StackTrace s) {
        log.severe('', e, s);
        if (done.isCompleted) return;
        done.completeError(e, s);
      }).then((result) {
    if (done.isCompleted) return;
    done.complete(result);
  });
  return done.future;
}
