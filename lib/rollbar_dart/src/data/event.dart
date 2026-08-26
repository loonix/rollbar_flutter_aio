import 'package:meta/meta.dart';
import '../../../../common/rollbar_common.dart';
import '../../../rollbar_dart/rollbar_dart.dart';

/// A library [Event].
///
/// An [Event] is anything that triggers a side-effect within the library, be
/// it changing state (eg. context), or communicating with the Rollbar API.
///
/// Each [Event] instance carries contextual information specific to its event.
@immutable
abstract class Event {}

/// A notification event.
///
/// A notification instructs the Rollbar SDK to notify the Rollbar API of an
/// event.
abstract class Notification implements Event {
  Level get level;

  /// Overrides Rollbar's default stack/exception-class grouping for this
  /// occurrence. Null (the default) leaves grouping untouched.
  String? get fingerprint;

  /// Overrides the occurrence's display title. Null (the default) leaves it
  /// to Rollbar. Truncated to 255 chars — Rollbar's documented limit.
  String? get title;

  /// Extra key/value data attached to this occurrence (Data.custom), visible
  /// and searchable in Rollbar directly — unlike breadcrumb extras, which
  /// only show up in the telemetry trail of whichever occurrence follows.
  JsonMap? get custom;
}

@sealed
class TelemetryEvent implements Event {
  final Breadcrumb breadcrumb;

  const TelemetryEvent(this.breadcrumb);

  @override
  String toString() => 'TelemetryEvent(breadcrumb: $breadcrumb)';
}

@sealed
class UserEvent implements Event {
  final User? user;

  const UserEvent(this.user);

  @override
  String toString() => 'UserEvent(user: $user)';
}

@sealed
class MessageEvent implements Notification, Event {
  @override
  final Level level;
  final String message;
  @override
  final String? fingerprint;
  @override
  final String? title;
  @override
  final JsonMap? custom;

  const MessageEvent(
    this.message, {
    this.level = Level.info,
    this.fingerprint,
    this.title,
    this.custom,
  });

  @override
  String toString() => 'MessageEvent(level: $level, message: $message)';
}

@sealed
class ErrorEvent implements Notification, Event {
  @override
  final Level level;
  final dynamic error;
  final String? description;
  final StackTrace stackTrace;
  @override
  final String? fingerprint;
  @override
  final String? title;
  @override
  final JsonMap? custom;

  const ErrorEvent(
    this.error,
    this.stackTrace, {
    this.description,
    this.level = Level.error,
    this.fingerprint,
    this.title,
    this.custom,
  });

  @override
  String toString() => 'ErrorEvent('
      'level: $level, '
      'error: $error, '
      'description: $description, '
      'stackTrace: $stackTrace)';
}

@sealed
class ContextSnapshot implements Event {}
