import 'package:gt_mobile_foundation/gt_mobile_foundation.dart';

extension IterableExtension<T> on Iterable<T>? {
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

  T? get tryFirst {
    if (this?.isEmpty ?? true) return null;
    try {
      return this?.first;
    } catch (_) {
      return null;
    }
  }

  T? get tryLast {
    if (this?.isEmpty ?? true) return null;
    try {
      return this?.last;
    } catch (_) {
      return null;
    }
  }

  bool equals(dynamic other) {
    if (other is! List<T>?) return false;
    final thisSet = this ?? [];
    final otherSet = other ?? [];

    if (thisSet.length != otherSet.length) return false;

    return thisSet.indexed.every((it) => otherSet[it.$1] == it.$2);
  }

  List<E> mapList<E>(MapCallback<E, T> toElement) {
    try {
      final data = this?.map(toElement);
      return data?.toList() ?? [];
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return [];
    }
  }

  List<T> whereList<E>(OnBoolValidation<T> onValidate) {
    try {
      final data = this?.where(onValidate);
      return data?.toList() ?? [];
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
      return [];
    }
  }

  bool get hasValue {
    return this != null && (this ?? []).isNotEmpty;
  }
}

extension ListExtension<T> on List<T>? {
  void tryAdd(T object) {
    try {
      this?.add(object);
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t);
    }
  }

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

  int tryIndexWhere(OnBoolValidation<T> onValidate) {
    try {
      if (this == null || (this?.isEmpty ?? true)) return -1;
      final index = this!.indexWhere(onValidate);
      return index;
    } catch (_) {
      return -1;
    }
  }

  List<T> unshiftUnique(T item) {
    try {
      if (!hasValue) return [item];
      if (this!.contains(item)) return this!;
      return [item, ...this!];
    } catch (_) {
      return this ?? [];
    }
  }

  List<T> addUnique(T item) {
    try {
      if (!hasValue) return [item];
      if (this!.contains(item)) return this!;
      return [...this!, item];
    } catch (_) {
      return this ?? [];
    }
  }

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

  List<T> get value => this ?? [];
}

extension NonNullListExtension<T> on List<T> {
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
