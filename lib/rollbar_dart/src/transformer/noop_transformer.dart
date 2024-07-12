import 'package:meta/meta.dart';
import '../../../rollbar_dart/rollbar_dart.dart';

@sealed
@immutable
class NoopTransformer implements Transformer {
  const NoopTransformer(Config _);

  @override
  Data transform(Data data, {required Event event}) => data;
}
