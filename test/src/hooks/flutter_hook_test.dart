// test/src/hooks/flutter_hook_test.dart
//
// SSWM-2896 was never reported to Rollbar even though FlutterHook.onError
// did fire: it passed the raw FlutterError straight into Rollbar.error(...).
// For a build-time "setState() or markNeedsBuild() called during build"
// error, that FlutterError's own diagnostics embed the actual offending
// Element (via describeElement()/describeWidget()) — which for a widget
// with an AnimationController transitively holds a live Ticker/Completer.
// Sending that object graph across the isolate boundary this eventually
// crosses throws "Illegal argument in isolate message: object is
// unsendable", asynchronously and un-awaited, so it only ever shows up as
// an unhandled exception in the log — the occurrence itself is lost.
import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rollbar_flutter_aio/src/hooks/flutter_hook.dart';

/// Stands in for anything reachable from a real build-time error's
/// diagnostics that Dart's isolate messaging can't serialize — the same
/// class of object as an AnimationController's internal Ticker/Completer.
class _LiveObjectStandIn {
  _LiveObjectStandIn() : completer = Completer<void>();
  final Completer<void> completer;
}

/// Whether [value] can actually be sent across an isolate message boundary.
/// A ReceivePort/SendPort pair enforces the same sendability rules as a real
/// Isolate.spawn, so this needs no real isolate to be a faithful check.
bool _isSendable(Object? value) {
  final port = ReceivePort();
  try {
    port.sendPort.send(value);
    return true;
  } catch (_) {
    return false;
  } finally {
    port.close();
  }
}

FlutterError _buildTimeErrorWithLiveDiagnostics() => FlutterError.fromParts([
      ErrorSummary('setState() or markNeedsBuild() called during build.'),
      DiagnosticsProperty(
          'The widget on which setState() or markNeedsBuild() was called was',
          _LiveObjectStandIn()),
    ]);

void main() {
  test(
      'sanity check: this shape of build-time FlutterError is not isolate-sendable as-is',
      () {
    expect(_isSendable(_buildTimeErrorWithLiveDiagnostics()), isFalse);
  });

  test(
      'FlutterHook.onError reports something isolate-sendable even for that exact shape of error',
      () {
    final details = FlutterErrorDetails(
        exception: _buildTimeErrorWithLiveDiagnostics(),
        stack: StackTrace.current,
        library: 'test');

    Object? reportedError;
    StackTrace? reportedStack;
    final hook = FlutterHook(
      dropBreadcrumb: (_) {},
      reportError: (error, [stack = StackTrace.empty]) {
        reportedError = error;
        reportedStack = stack;
      },
    );

    hook.onError(details);

    expect(reportedError, isNotNull);
    expect(_isSendable(reportedError), isTrue);
    expect(reportedStack, isNotNull);
  });

  test('the reported error still names the original exception type and message',
      () {
    final details = FlutterErrorDetails(
        exception: _buildTimeErrorWithLiveDiagnostics(),
        stack: StackTrace.current,
        library: 'test');

    Object? reportedError;
    final hook = FlutterHook(
      dropBreadcrumb: (_) {},
      reportError: (error, [stack = StackTrace.empty]) => reportedError = error,
    );

    hook.onError(details);

    expect(reportedError.toString(), contains('FlutterError'));
    expect(reportedError.toString(),
        contains('setState() or markNeedsBuild() called during build.'));
  });

  test('a silent error reports nothing', () {
    final details = FlutterErrorDetails(
        exception: _buildTimeErrorWithLiveDiagnostics(), silent: true);

    var breadcrumbDropped = false;
    var errorReported = false;
    final hook = FlutterHook(
      dropBreadcrumb: (_) => breadcrumbDropped = true,
      reportError: (error, [stack = StackTrace.empty]) => errorReported = true,
    );

    hook.onError(details);

    expect(breadcrumbDropped, isFalse);
    expect(errorReported, isFalse);
  });
}
