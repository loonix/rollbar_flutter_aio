// test/rollbar_dart/rollbar_fingerprint_api_test.dart
//
// Confirms fingerprint/title reach the actual sent payload through the
// public Rollbar.error/log API, not just through DataMarshaller in
// isolation. Uses AsyncSandbox (same seam the package's own
// rollbar_flutter_test.dart uses) so no Isolate/native platform channel is
// needed.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/rollbar_dart.dart';
import 'package:rollbar_flutter_aio/rollbar_dart/src/sandbox/async_sandbox.dart';

void main() {
  late List<Map<String, dynamic>> sentPayloads;

  Future<void> runWith(FutureOr<void> Function() body) async {
    final config = Config(
      accessToken: 'test-token',
      environment: 'test',
      sandbox: AsyncSandbox.new,
      sender: (_) => _CapturingSender(sentPayloads),
    );
    await Rollbar.run(config);
    await body();
  }

  setUp(() {
    sentPayloads = [];
  });

  test(
      'Rollbar.error (no fingerprint/title support) leaves the payload unchanged (default)',
      () async {
    await runWith(() => Rollbar.error('boom'));
    final data = sentPayloads.single['data'] as Map<String, dynamic>;
    expect(data.containsKey('fingerprint'), isFalse);
    expect(data.containsKey('title'), isFalse);
  });

  test('Rollbar.log carries a custom fingerprint through to the sent payload',
      () async {
    await runWith(() => Rollbar.log('boom',
        level: Level.error, fingerprint: 'array-field-setstate-during-build'));
    final data = sentPayloads.single['data'] as Map<String, dynamic>;
    expect(data['fingerprint'], 'array-field-setstate-during-build');
  });

  test('Rollbar.log carries a custom title through to the sent payload',
      () async {
    await runWith(
        () => Rollbar.log('boom', title: 'Array field: setState during build'));
    final data = sentPayloads.single['data'] as Map<String, dynamic>;
    expect(data['title'], 'Array field: setState during build');
  });

  test('Rollbar.log at critical level also accepts fingerprint/title',
      () async {
    await runWith(() => Rollbar.log('boom',
        level: Level.critical, fingerprint: 'fp', title: 'title'));
    final data = sentPayloads.single['data'] as Map<String, dynamic>;
    expect(data['level'], 'critical');
    expect(data['fingerprint'], 'fp');
    expect(data['title'], 'title');
  });
}

class _CapturingSender implements Sender {
  _CapturingSender(this._sink);
  final List<Map<String, dynamic>> _sink;

  @override
  Future<bool> send(Map<String, dynamic> payload) async {
    _sink.add(payload);
    return true;
  }

  @override
  Future<bool> sendString(String payload) async => true;
}
