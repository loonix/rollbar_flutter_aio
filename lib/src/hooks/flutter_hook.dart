import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import '../../common/rollbar_common.dart';
import '../../rollbar_dart/rollbar.dart';

import '../extension/diagnostics.dart';
import 'hook.dart';

@sealed
class FlutterHook implements Hook {
  FlutterHook({
    this.dropBreadcrumb = Rollbar.drop,
    this.reportError = Rollbar.error,
  });

  FlutterExceptionHandler? _originalOnError;
  final FutureOr<void> Function(Breadcrumb) dropBreadcrumb;
  final FutureOr<void> Function(dynamic, [StackTrace]) reportError;

  void onError(FlutterErrorDetails error) {
    if (!error.silent) {
      dropBreadcrumb(
        Breadcrumb.error(
          error.exceptionAsString(),
          extra: {
            'summary': error.summary.toDescription(),
            'context': error.context?.toDescription(),
            'info': error.information,
            'diagnostics': error.diagnostics,
            'library': error.library
          }.compact(),
        ),
      );

      // error.exception may retain live framework objects: a build-time
      // "setState()/markNeedsBuild() called during build" FlutterError
      // embeds the actual offending Element via describeElement(), which
      // for a widget with an AnimationController reaches down to a live
      // Ticker/Completer. Sending that graph across the isolate boundary
      // Rollbar.error eventually crosses throws "Illegal argument in
      // isolate message: object is unsendable" — asynchronously, from this
      // un-awaited call, so it only ever shows up as an unhandled exception
      // in the log. The occurrence itself is silently never sent. Wrapping
      // it in a plain string before it crosses that boundary fixes this for
      // every build-time error, not just this one shape of it.
      reportError(_SafeException(error.exception, error.exceptionAsString()),
          error.stack ?? StackTrace.empty);
    }

    if (_originalOnError != null) {
      _originalOnError!(error);
    }
  }

  @override
  void install(_) {
    _originalOnError = FlutterError.onError;
    FlutterError.onError = onError;
  }

  @override
  void uninstall() {
    if (FlutterError.onError == onError) {
      FlutterError.onError = _originalOnError;
      _originalOnError = null;
    }
  }
}

/// A plain, isolate-sendable stand-in for [original]. Keeps the original
/// type name in the message — Rollbar.log reports [runtimeType] as the
/// occurrence's exception type, which would otherwise become
/// "_SafeException" for every single build-time error reported this way.
class _SafeException extends Error {
  _SafeException(Object original, String message)
      : _message = '${original.runtimeType}: $message';

  final String _message;

  @override
  String toString() => _message;
}
