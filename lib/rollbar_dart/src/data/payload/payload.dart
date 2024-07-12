import 'package:meta/meta.dart';
import '../../../../common/rollbar_common.dart';

import 'data.dart';

/// Represents the payload to be sent to Rollbar. A successfully constructed
/// Payload matches Rollbar's spec, and can be POSTed to the correct endpoint
/// when serialized as JSON.
@sealed
@immutable
class Payload with EquatableSerializableMixin implements Equatable, Serializable {
  final Data data;

  const Payload({required this.data});

  factory Payload.fromMap(JsonMap map) => Payload(
        data: Data.fromMap(map['data']),
      );

  @override
  JsonMap toMap() => {
        'data': data.toMap(),
      };
}
