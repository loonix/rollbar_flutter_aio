import 'dart:async';

import 'package:meta/meta.dart';
import '../../../rollbar_dart/rollbar_dart.dart';

@sealed
abstract class Notifier {
  // notifier version to be updated with each new release: [todo] automate
  static const version = '1.3.1';
  static const name = 'rollbar-dart';

  FutureOr<Context> notify(Context state, final Event event);
}
