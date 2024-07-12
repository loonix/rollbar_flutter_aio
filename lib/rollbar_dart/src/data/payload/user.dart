import 'package:meta/meta.dart';
import '../../../../common/rollbar_common.dart';

@sealed
@immutable
class User with EquatableSerializableMixin implements Equatable, Serializable {
  final String id;
  final String? username;
  final String? email;

  const User({
    required this.id,
    this.username,
    this.email,
  });

  factory User.fromMap(JsonMap map) => User(
        id: map['id'],
        username: map['username'],
        email: map['email'],
      );

  /// Converts the object into a Json encodable map.
  @override
  JsonMap toMap() => {
        'id': id,
        'username': username,
        'email': email,
      }.compact();
}
