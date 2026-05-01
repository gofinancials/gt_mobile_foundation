import 'package:gt_mobile_foundation/foundation.dart';

/// Extensions on nullable [Iterable] for safer data manipulation.
extension IterableExtension<T> on Iterable<T>? {
  /// Returns the first element matching the [onValidate] condition, or `null` if none match or an error occurs.
  T? tryFirstWhere(OnBoolValidation<T> onValidate) {
    try {
      if (this == null || (this?.isEmpty ?? true)) return null;
      final matches = this!.where(onValidate);
      if (matches.isEmpty) return null;
      return matches.tryFirst;
    } catch (_) {
      return null;
    }
  }

  /// Returns the last element matching the [onValidate] condition, or `null` if none match or an error occurs.
  T? tryLastWhere(OnBoolValidation<T> onValidate) {
    try {
      if (this == null || (this?.isEmpty ?? true)) return null;
      final matches = this!.where(onValidate);
      if (matches.isEmpty) return null;
      return matches.tryLast;
    } catch (_) {
      return null;
    }
  }

  /// Returns the first element of the iterable, or `null` if it is empty or an error occurs.
  T? get tryFirst {
    if (this?.isEmpty ?? true) return null;
    try {
      return this?.first;
    } catch (_) {
      return null;
    }
  }

  /// Returns the last element of the iterable, or `null` if it is empty or an error occurs.
  T? get tryLast {
    if (this?.isEmpty ?? true) return null;
    try {
      return this?.last;
    } catch (_) {
      return null;
    }
  }

  /// Compares this iterable with [other] for equality.
  ///
  /// Returns `true` if they have the same length and their elements are equal in order.
  bool equals(dynamic other) {
    if (other is! List<T>?) return false;
    final thisSet = this ?? [];
    final otherSet = other ?? [];

    if (thisSet.length != otherSet.length) return false;

    return thisSet.indexed.every((it) => otherSet[it.$1] == it.$2);
  }

  /// Maps the elements of this iterable to a [List] using the [toElement] function safely.
  List<E> mapList<E>(MapCallback<E, T> toElement) {
    try {
      final data = this?.map(toElement);
      return data?.toList() ?? [];
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return [];
    }
  }

  /// Filters the elements of this iterable to a [List] using the [onValidate] function safely.
  List<T> whereList<E>(OnBoolValidation<T> onValidate) {
    try {
      final data = this?.where(onValidate);
      return data?.toList() ?? [];
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return [];
    }
  }

  /// Returns `true` if the iterable is not null and not empty.
  bool get hasValue {
    return this != null && (this ?? []).isNotEmpty;
  }
}

/// Extensions on nullable [List] for safer data manipulation.
extension ListExtension<T> on List<T>? {
  /// Tries to add an [object] to the list, catching any potential errors.
  void tryAdd(T object) {
    try {
      this?.add(object);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

  /// Returns a random element from the list, or `null` if it is empty or an error occurs.
  T? get random {
    try {
      if (!hasValue) return null;
      final data = [...this!];
      data.shuffle();
      return data.tryFirst;
    } catch (_) {
      return null;
    }
  }

  /// Returns the index of the first element matching [onValidate], or `-1` if not found or an error occurs.
  int tryIndexWhere(OnBoolValidation<T> onValidate) {
    try {
      if (this == null || (this?.isEmpty ?? true)) return -1;
      final index = this!.indexWhere(onValidate);
      return index;
    } catch (_) {
      return -1;
    }
  }

  /// Adds an [item] to the beginning of the list if it doesn't already exist.
  ///
  /// Returns the modified list or a new list containing only the [item] if the original was null.
  List<T> unshiftUnique(T item) {
    try {
      if (!hasValue) return [item];
      if (this!.contains(item)) return this!;
      return [item, ...this!];
    } catch (_) {
      return this ?? [];
    }
  }

  /// Adds an [item] to the end of the list if it doesn't already exist.
  ///
  /// Returns the modified list or a new list containing only the [item] if the original was null.
  List<T> addUnique(T item) {
    try {
      if (!hasValue) return [item];
      if (this!.contains(item)) return this!;
      return [...this!, item];
    } catch (_) {
      return this ?? [];
    }
  }

  /// Adds an [item] to the list, replacing it if it already exists.
  ///
  /// Returns the modified list or a new list containing only the [item] if the original was null.
  List<T> addOrReplace(T item) {
    try {
      if (!hasValue) return [item];
      final index = this?.indexOf(item) ?? -1;
      if (index == -1) return [...this!, item];
      final list = [...this!];
      list[index] = item;
      return list;
    } catch (_) {
      return this ?? [];
    }
  }

  /// Adds an [item] to the beginning of the list, replacing it if it already exists.
  ///
  /// Returns the modified list or a new list containing only the [item] if the original was null.
  List<T> unshiftOrReplace(T item) {
    try {
      if (!hasValue) return [item];
      final index = this?.indexOf(item) ?? -1;
      if (index == -1) return [item, ...this!];
      final list = [...this!];
      list[index] = item;
      return list;
    } catch (_) {
      return this ?? [];
    }
  }

  /// Inserts [interspersend] between each element of the list.
  ///
  /// Returns a new list with the interspersed elements, or `null` if the original list was null.
  List<T>? intersperse(T interspersend) {
    try {
      if (this == null) return null;
      if (this!.isEmpty) return [];
      if (this!.length == 1) return [this!.first, interspersend];
      final last = this!.last;
      this!.removeLast();
      final map2d = mapList((it) => [it, interspersend]);
      List<T> flatList = map2d.fold([], (p, n) => [...p, ...n]);
      return [...flatList, last];
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return this ?? [];
    }
  }

  /// Returns the list if it's not null, otherwise returns an empty list.
  List<T> get value => this ?? [];
}

/// Extensions on non-nullable [List] for data manipulation.
extension NonNullListExtension<T> on List<T> {
  /// Inserts [interspersend] between each element of the list.
  ///
  /// Returns a new list with the interspersed elements.
  List<T> intersperse(T interspersend) {
    try {
      if (isEmpty) return [];
      if (length == 1) return this;
      final lastItem = last;
      removeLast();
      final map2d = mapList((it) => [it, interspersend]);
      List<T> flatList = map2d.fold([], (p, n) => [...p, ...n]);
      return [...flatList, lastItem];
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return this;
    }
  }
}
