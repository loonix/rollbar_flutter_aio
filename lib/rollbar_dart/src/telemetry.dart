import 'dart:convert';

import 'package:meta/meta.dart';
import '../../common/rollbar_common.dart';

import 'data/payload/breadcrumb.dart';
import 'persistence.dart';
import 'data/config.dart';

@sealed
@immutable
class Telemetry with Persistence<BreadcrumbRecord> implements Configurable {
  @override
  final Config config;

  Telemetry(this.config);

  void removeExpired() {
    final expiration = DateTime.now().toUtc() - config.persistenceLifetime;
    records.removeWhere((record) => record.timestamp < expiration);
  }

  bool add(Breadcrumb breadcrumb) => records.add(
        BreadcrumbRecord(breadcrumb: jsonEncode(breadcrumb.toMap())),
      );

  List<Breadcrumb> breadcrumbs() => records.sorted(by: Symbol('${(BreadcrumbRecord).toString()}.timestamp')).map((record) => jsonDecode(record.breadcrumb) as JsonMap).map(Breadcrumb.fromMap).toList();
}
