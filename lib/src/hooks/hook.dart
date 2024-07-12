import 'dart:async';

import '../../rollbar_dart/rollbar.dart';

abstract class Hook {
  FutureOr<void> install(final Config config);

  FutureOr<void> uninstall();
}
