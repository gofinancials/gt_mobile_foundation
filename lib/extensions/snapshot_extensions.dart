import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

/// {@category Extensions}
/// Extension on [AsyncSnapshot] providing convenience getters for stream/future states.
extension SnapshotExtension on AsyncSnapshot {
  /// Returns `true` if the connection state is currently waiting.
  bool get isLoading {
    return connectionState == ConnectionState.waiting;
  }

  /// Returns `true` if the snapshot has finished loading with data and no errors.
  bool get isLoaded {
    return !isLoading && !hasError && hasData;
  }

  /// Returns `true` if the snapshot has no data, or if its iterable data is empty.
  bool get isEmpty {
    if ((data is Iterable?) || (data is Iterable)) {
      return !hasData || !(data as Iterable?).hasValue;
    }
    return !hasData;
  }
}

/// {@category Extensions}
/// Extension specifically on [AsyncSnapshot] holding a [TaskResponse] to quickly
/// determine success or failure states.
extension HttpSnapshotExtension<T> on AsyncSnapshot<TaskResponse<T>> {
  /// Returns `true` if the snapshot successfully loaded with a valid response payload.
  bool get hasResponse {
    final firstCondition = !isLoading && hasData;
    bool secondCondition = this.data != null;
    if (!secondCondition) return false;
    final data = this.data;
    final hasContent = data?.data != null;
    if (hasContent && data!.data is Iterable) {
      secondCondition = (data.data as Iterable).isNotEmpty;
      return firstCondition && secondCondition;
    } else {
      secondCondition = hasContent;
    }

    return firstCondition && secondCondition;
  }

  /// Returns `true` if the snapshot resulted in an error or a failed [TaskResponse].
  bool get hasFailure {
    return !isLoading && (hasError || (data?.isFailure ?? true));
  }
}
