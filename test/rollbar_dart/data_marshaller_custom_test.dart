// test/rollbar_dart/data_marshaller_custom_test.dart
//
// Data.custom already existed on the payload model, but DataMarshaller never
// populated it — the only way to attach extra data to an occurrence was the
// breadcrumb trail. This pins the direct path through Rollbar.log/error.
import 'package:flutter_test/flutter_test.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/src/data/config.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/src/data/context.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/src/data/event.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/src/data/payload/data.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/src/marshaller/data_marshaller.dart';

void main() {
  const config = Config(accessToken: 'test-token', environment: 'test');

  DataMarshaller marshaller() => const DataMarshaller(config);
  Context context() => Context(config);

  test(
      'custom is omitted from the payload when the event has none (default, unchanged)',
      () {
    final data = marshaller()
        .marshall(context: context(), event: const MessageEvent('hello'));
    expect(data.custom, isNull);
    expect(data.toMap().containsKey('custom'), isFalse);
  });

  test('custom map is carried verbatim from a MessageEvent to the payload', () {
    final data = marshaller().marshall(
        context: context(),
        event:
            const MessageEvent('hello', custom: {'form_id': 'f-1', 'step': 2}));
    expect(data.custom, {'form_id': 'f-1', 'step': 2});
    expect(data.toMap()['custom'], {'form_id': 'f-1', 'step': 2});
  });

  test('custom map is carried verbatim from an ErrorEvent to the payload', () {
    final data = marshaller().marshall(
        context: context(),
        event: const ErrorEvent('boom', StackTrace.empty,
            custom: {'run_id': 'r-1'}));
    expect(data.custom, {'run_id': 'r-1'});
  });

  test('an empty custom map is treated as no custom data', () {
    final data = marshaller().marshall(
        context: context(), event: const MessageEvent('hello', custom: {}));
    expect(data.custom, isNull);
  });

  test('custom round-trips through toMap()/fromMap()', () {
    final data = marshaller().marshall(
        context: context(),
        event: const MessageEvent('hello', custom: {'a': 1}));
    final rebuilt = Data.fromMap(data.toMap());
    expect(rebuilt.custom, {'a': 1});
  });
}
