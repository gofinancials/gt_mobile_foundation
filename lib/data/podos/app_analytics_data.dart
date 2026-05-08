import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// Represents a structured analytics event containing an [event] type,
/// [description], execution timestamp, and optional [value].
class AppAnalyticsData extends Codable {
  final AppEvent event;
  final String? description;
  final DateTime executedAt;
  final dynamic value;

  AppAnalyticsData(this.event, {this.description, this.value})
    : executedAt = DateTime.now();

  @override
  Map<String, Object> toJson() {
    final data = {
      "description": description ?? event.name.toLowerCase(),
      "value": "$value",
      "executedAt": executedAt.millisecondsSinceEpoch,
    };
    return data;
  }
}
