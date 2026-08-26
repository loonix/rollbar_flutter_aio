// test/rollbar_dart/data_marshaller_fingerprint_test.dart
//
// Rollbar's own grouping algorithm hashes stack frames + exception class and
// ignores line numbers (see docs.rollbar.com/docs/grouping-algorithm) — so
// occurrences that are the same underlying bug but from different call sites
// (e.g. the same "setState called during build" assertion from different
// forms) collapse into one Item. A custom fingerprint is the only way for a
// caller to force those apart (or force unrelated-looking ones together).
// Before this change, Data/DataMarshaller had nowhere to carry one.
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

  group('fingerprint', () {
    test(
        'is omitted from the payload when the event has none (default, unchanged)',
        () {
      final data = marshaller()
          .marshall(context: context(), event: const MessageEvent('hello'));
      expect(data.fingerprint, isNull);
      expect(data.toMap().containsKey('fingerprint'), isFalse);
    });

    test('is carried verbatim from a MessageEvent to the payload', () {
      final data = marshaller().marshall(
          context: context(),
          event: const MessageEvent('hello', fingerprint: 'custom-fp'));
      expect(data.fingerprint, 'custom-fp');
      expect(data.toMap()['fingerprint'], 'custom-fp');
    });

    test('is carried verbatim from an ErrorEvent to the payload', () {
      final data = marshaller().marshall(
        context: context(),
        event: const ErrorEvent('boom', StackTrace.empty,
            fingerprint: 'custom-fp'),
      );
      expect(data.fingerprint, 'custom-fp');
    });

    test('round-trips through toMap()/fromMap()', () {
      final data = marshaller().marshall(
          context: context(),
          event: const MessageEvent('hello', fingerprint: 'custom-fp'));
      final rebuilt = Data.fromMap(data.toMap());
      expect(rebuilt.fingerprint, 'custom-fp');
    });

    test(
        'an empty string fingerprint is treated as no fingerprint (Rollbar requires non-empty)',
        () {
      final data = marshaller().marshall(
          context: context(),
          event: const MessageEvent('hello', fingerprint: ''));
      expect(data.fingerprint, isNull);
    });
  });

  group('title', () {
    test(
        'is omitted from the payload when the event has none (default, unchanged)',
        () {
      final data = marshaller()
          .marshall(context: context(), event: const MessageEvent('hello'));
      expect(data.title, isNull);
      expect(data.toMap().containsKey('title'), isFalse);
    });

    test('is carried verbatim from an ErrorEvent to the payload', () {
      final data = marshaller().marshall(
        context: context(),
        event: const ErrorEvent('boom', StackTrace.empty, title: 'Boom title'),
      );
      expect(data.title, 'Boom title');
    });

    test(
        'longer than 255 chars is truncated (Rollbar\'s documented title limit)',
        () {
      final longTitle = 'x' * 300;
      final data = marshaller().marshall(
          context: context(), event: MessageEvent('hello', title: longTitle));
      expect(data.title!.length, 255);
    });
  });
}
