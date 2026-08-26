// test/public_api_surface_test.dart
//
// Regression guard for the package's public entry point
// (package:rollbar_flutter_aio/rollbar.dart) — types a consumer needs to
// call Breadcrumb.network(...) or Rollbar.log(..., level: ...) must be
// reachable from that single import, not from internal src/ paths that can
// move without a semver bump.
import 'package:flutter_test/flutter_test.dart';
import 'package:rollbar_flutter_aio/rollbar.dart';

void main() {
  test(
      'HttpMethod is reachable from the public barrel (needed for Breadcrumb.network)',
      () {
    final breadcrumb = Breadcrumb.network(
      Uri.parse('https://example.com'),
      method: HttpMethod.get,
      statusCode: 200,
    );
    expect(breadcrumb.type, 'network');
  });

  test(
      'Level is reachable from the public barrel (needed for Rollbar.log(level: ...))',
      () {
    expect(Level.warning.name, 'warning');
  });
}
