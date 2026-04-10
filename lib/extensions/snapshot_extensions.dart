import 'package:gt_mobile_foundation/foundation.dart';
import 'package:flutter/material.dart';

extension SnapshotExtension on AsyncSnapshot {
  bool get isLoading {
    return connectionState == ConnectionState.waiting;
  }

  bool get isLoaded {
    return !isLoading && !hasError && hasData;
  }

  bool get isEmpty {
    if ((data is Iterable?) || (data is Iterable)) {
      return !hasData || !(data as Iterable?).hasValue;
    }
    return !hasData;
  }
}

extension HttpSnapshotExtension<T> on AsyncSnapshot<NetworkResponse<T>> {
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

  bool get hasFailure {
    return !isLoading && (hasError || (data?.isFailure ?? true));
  }
}
