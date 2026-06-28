import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// A [ValueNotifier] that manages the state of an [AsyncData] object.
class AsyncDataNotifier<T extends Equatable>
    extends ValueNotifier<AsyncData<T>> {
  AsyncDataNotifier(super.value);
}

/// {@category Data}
/// A [ValueNotifier] that manages the state of a [FutureData] object.
class FutureDataNotifier<T extends Equatable>
    extends ValueNotifier<FutureData<T>> {
  FutureDataNotifier(super.value);
  FutureDataNotifier.pristine() : super(FutureData.pristine());

  T? get data => value.data;
  TaskError? get error => value.error;
  bool get hasError => value.hasError;
  bool get isLoading => value.isLoading;
  bool get isPristine => value.isPristine;
  bool get hasData => value.hasData;
  DateTime? get updatedAt => value.updatedAt;
  String get updateTime => value.updateTime;

  void setLoading({T? data}) {
    value = value.copyWith(isLoading: true, data: data);
  }

  void setData(T data) {
    value = value.copyWith(data: data, isLoading: false);
  }

  void setError(TaskError error) {
    value = value.copyWith(error: error, isLoading: false);
  }

  void reset() {
    value = value.reset();
  }

  void updateWith({T? data, bool? isLoading, TaskError? error}) {
    value = value.copyWith(data: data, isLoading: isLoading, error: error);
  }
}

/// {@category Data}
/// A [ValueNotifier] that manages the state of a [FutureListData] object.
class FutureListDataNotifier<T extends Equatable>
    extends ValueNotifier<FutureListData<T>> {
  FutureListDataNotifier(super.value);
  FutureListDataNotifier.pristine() : super(FutureListData.pristine());

  List<T> get data => value.data;
  TaskError? get error => value.error;
  bool get hasError => value.hasError;
  bool get isLoading => value.isLoading;
  bool get isPristine => value.isPristine;
  bool get hasData => value.hasData;
  DateTime? get updatedAt => value.updatedAt;
  String get updateTime => value.updateTime;

  void setLoading({List<T>? data}) {
    value = value.copyWith(isLoading: true, data: data);
  }

  void setData(List<T> data) {
    value = value.copyWith(data: data, isLoading: false);
  }

  void setError(TaskError error) {
    value = value.copyWith(error: error, isLoading: false);
  }

  void reset() {
    value = value.reset();
  }

  void updateWith({List<T>? data, bool? isLoading, TaskError? error}) {
    value = value.copyWith(data: data, isLoading: isLoading, error: error);
  }

  /// Updates a single item in the list by replacing [oldItem] with [newItem].
  void updateSingleItem(T oldItem, T newItem) {
    value = value.updateSingleItem(oldItem, newItem);
  }

  /// Removes a single [item] from the list.
  void removeSingleItem(T item) {
    value = value.removeSingleItem(item);
  }
}

/// {@category Data}
/// A [ValueNotifier] that manages the state of a [PaginatedData] object.
class PaginatedDataNotifier<T extends Identifiable>
    extends ValueNotifier<PaginatedData<T>> {
  PaginatedDataNotifier(super.value);
  PaginatedDataNotifier.pristine() : super(PaginatedData.pristine());

  List<T> get data => value.data;
  TaskError? get error => value.error;
  bool get hasError => value.hasError;
  bool get isLoading => value.isLoading;
  bool get isPristine => value.isPristine;
  bool get hasData => value.hasData;
  DateTime? get updatedAt => value.updatedAt;
  String get updateTime => value.updateTime;

  void setLoading({List<T>? data}) {
    value = value.copyWith(isLoading: true, data: data);
  }

  void setData(List<T> data) {
    value = value.copyWith(data: data, isLoading: false);
  }

  void setError(TaskError error) {
    value = value.copyWith(error: error, isLoading: false);
  }

  void reset() {
    value = value.reset();
  }

  void updateWith({
    List<T>? data,
    bool? isLoading,
    TaskError? error,
    int? page,
    int? pages,
    int? limit,
    String? query,
  }) {
    value = value.copyWith(
      data: data,
      isLoading: isLoading,
      error: error,
      page: page,
      pages: pages,
      limit: limit,
      query: query,
    );
  }

  /// Updates a single item in the list by replacing [oldItem] with [newItem].
  void updateSingleItem(T oldItem, T newItem) {
    value = value.updateSingleItem(oldItem, newItem);
  }

  /// Removes a single [item] from the list.
  void removeSingleItem(T item) {
    value = value.removeSingleItem(item);
  }

  /// Adds a single [item] to the paginated data.
  void addSingleItem(T item, {bool unshift = true}) {
    value = value.addSingleItem(item, unshift: unshift);
  }

  /// Adds a [items] to the paginated data.
  void addData(PaginatedData<T> pageData, {bool ensureUnique = false}) {
    value = value.addData(pageData, ensureUnique: ensureUnique);
  }
}

/// {@category Data}
/// Base class representing the state of an asynchronous operation.
abstract class AsyncData<T extends Equatable> {
  /// Indicates whether the asynchronous operation is currently loading.
  bool get isLoading;

  /// Indicates whether the data is in its initial, unmodified state.
  bool get isPristine;

  /// Returns true if an error has occurred.
  bool get hasError;

  /// Returns true if valid data is available.
  bool get hasData;

  /// The error object, if an error occurred.
  TaskError? get error;

  /// The timestamp of the last update to the data.
  DateTime? get updatedAt;

  /// A convenience getter for the error message, if available.
  String? get errorMessage => error?.message;

  const AsyncData();

  /// Creates a copy of this [AsyncData] with the specified fields replaced.
  AsyncData<T> copyWith();

  @override
  toString() {
    return "error => $error, hasData => $hasData, isLoading => $isLoading, updatedAt => $updatedAt, isPristine => $isPristine, hasError => $hasError";
  }
}

/// {@category Data}
/// Represents the state of an asynchronous operation returning a single item of type [T].
class FutureData<T extends Equatable> extends AsyncData<T> {
  /// The actual data payload, or null if not available.
  final T? data;
  @override
  final bool isLoading;
  @override
  final bool isPristine;
  @override
  final TaskError? error;
  final DateTime? _updatedAt;

  const FutureData({
    this.data,
    this.isLoading = false,
    this.error,
    required DateTime updatedAt,
  }) : isPristine = false,
       _updatedAt = updatedAt;

  const FutureData.pristine({this.data, this.isLoading = false, this.error})
    : isPristine = true,
      _updatedAt = null;

  @override
  bool get hasError {
    return error != null;
  }

  @override
  bool get hasData {
    return data != null;
  }

  String get updateTime {
    return updatedAt?.toIso8601String() ?? '';
  }

  @override
  DateTime? get updatedAt => _updatedAt;

  @override
  FutureData<T> copyWith({T? data, bool? isLoading, TaskError? error}) {
    return FutureData(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      updatedAt: DateTime.now(),
    );
  }

  /// Resets the state back to a pristine condition.
  FutureData<T> reset() {
    return FutureData.pristine();
  }

  List<Object?> get props => [data, isLoading, error, updatedAt];
}

/// {@category Data}
/// Represents the state of an asynchronous operation returning a list of items of type [T].
class FutureListData<T extends Equatable> extends AsyncData<T> {
  /// The list of data items.
  final List<T> data;
  @override
  final bool isLoading;
  @override
  final TaskError? error;
  final DateTime? _updatedAt;
  @override
  final bool isPristine;

  const FutureListData({
    this.data = const [],
    this.isLoading = false,
    this.error,
    required DateTime updatedAt,
  }) : isPristine = false,
       _updatedAt = updatedAt;

  const FutureListData.pristine({
    this.data = const [],
    this.isLoading = false,
    this.error,
  }) : isPristine = true,
       _updatedAt = null;

  @override
  bool get hasError {
    return error != null;
  }

  @override
  bool get hasData {
    return data.isNotEmpty;
  }

  String get updateTime {
    return updatedAt?.toIso8601String() ?? '';
  }

  @override
  DateTime? get updatedAt => _updatedAt;

  @override
  FutureListData<T> copyWith({
    List<T>? data,
    bool? isLoading,
    TaskError? error,
  }) {
    return FutureListData(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      updatedAt: DateTime.now(),
    );
  }

  /// Resets the state back to a pristine condition.
  FutureListData<T> reset() {
    return FutureListData.pristine();
  }

  /// Updates a single item in the list by replacing [oldItem] with [newItem].
  FutureListData<T> updateSingleItem(T oldItem, T newItem) {
    if (!data.contains(oldItem)) return this;
    final index = data.indexOf(oldItem);
    final items = [...data];
    items[index] = newItem;
    return copyWith(data: items);
  }

  /// Removes a single [item] from the list.
  FutureListData<T> removeSingleItem(T item) {
    final items = [...data]..remove(item);
    return copyWith(data: items);
  }

  List<Object?> get props => [data, isLoading, error, updatedAt];
}

/// {@category Data}
/// Represents the state of a paginated asynchronous operation returning items of type [T].
class PaginatedData<T extends Identifiable> extends AsyncData<T> {
  /// The list of paginated data items.
  final List<T> data;
  @override
  final bool isLoading;
  @override
  final TaskError? error;

  /// The current page index.
  final int page;

  /// The total number of pages available.
  final int pages;

  /// The maximum number of items per page.
  final int limit;

  /// The search query associated with this paginated data, if any.
  final String? query;
  final DateTime? _updatedAt;
  final bool _isPristine;

  const PaginatedData({
    this.data = const [],
    this.isLoading = false,
    this.page = 0,
    this.pages = 0,
    this.limit = 0,
    this.error,
    this.query,
    required DateTime updatedAt,
  }) : _isPristine = false,
       _updatedAt = updatedAt;

  const PaginatedData.pristine({
    this.data = const [],
    this.isLoading = false,
    this.error,
  }) : _isPristine = true,
       query = null,
       page = 0,
       pages = 0,
       limit = 0,
       _updatedAt = null;

  @override
  bool get isPristine => _isPristine;

  /// Indicates whether there is a subsequent page available.
  bool get hasNext => page < pages;

  /// Gets the index for the next page. If there is no next page, returns the current page.
  int get next {
    if (!hasNext) return page;
    return page + 1;
  }

  @override
  bool get hasError {
    return error != null;
  }

  @override
  bool get hasData {
    return data.isNotEmpty;
  }

  @override
  toString() {
    return "<<hasNext => $hasNext, isLoading => $isLoading, hasData -> $hasData, data -> ${data.length}>>";
  }

  String get updateTime {
    return updatedAt?.toIso8601String() ?? '';
  }

  @override
  DateTime? get updatedAt => _updatedAt;

  @override
  PaginatedData<T> copyWith({
    List<T>? data,
    bool? isLoading,
    TaskError? error,
    String? query,
    int? page,
    int? pages,
    int? limit,
  }) {
    return PaginatedData(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      query: query,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      limit: limit ?? this.limit,
      updatedAt: DateTime.now(),
    );
  }

  /// Combines the current data with another [pageData], typically used when loading more items.
  ///
  /// If [ensureUnique] is true, duplicate items will be filtered out.
  PaginatedData<T> addData(
    PaginatedData<T> pageData, {
    bool ensureUnique = false,
  }) {
    if (this == pageData) return this;
    List<T> items = [...data, ...pageData.data];

    if (ensureUnique) {
      final seenUuids = <dynamic>{};
      final uniqueItems = <T>[];
      for (final item in items) {
        if (seenUuids.add(item.uuid)) {
          uniqueItems.add(item);
        }
      }
      items = uniqueItems;
    }

    return PaginatedData(
      data: items,
      isLoading: pageData.isLoading,
      error: pageData.error,
      page: pageData.page,
      pages: pageData.pages,
      limit: pageData.limit,
      query: pageData.query,
      updatedAt: DateTime.now(),
    );
  }

  /// Resets the state back to a pristine condition.
  PaginatedData<T> reset() {
    return PaginatedData.pristine();
  }

  /// Adds a single [item] to the paginated data.
  ///
  /// By default, the item is unshifted (added to the beginning) unless [unshift] is false.
  /// If [ensureUnique] is true, the item is replaced if it already exists, rather than duplicated.
  PaginatedData<T> addSingleItem(
    T item, {
    bool unshift = true,
    bool ensureUnique = false,
  }) {
    final index = _indexOf(data, item);
    if (!ensureUnique || index == -1) {
      final items = unshift ? [item, ...data] : [...data, item];
      return PaginatedData(data: items, updatedAt: DateTime.now());
    }
    final items = [...data];
    items[index] = item;
    return PaginatedData(data: items, updatedAt: DateTime.now());
  }

  /// Updates a single item by replacing [oldItem] with [newItem].
  /// If [oldItem] is not found, [newItem] is added to the data.
  PaginatedData<T> updateSingleItem(T oldItem, T newItem) {
    if (!data.contains(oldItem)) return addSingleItem(newItem);
    final items = _replace(data, oldItem);
    return PaginatedData(data: items, updatedAt: DateTime.now());
  }

  /// Removes a single [item] from the paginated data.
  PaginatedData<T> removeSingleItem(T item) {
    final items = [...data]..remove(item);
    return PaginatedData(data: items, updatedAt: DateTime.now());
  }

  int _indexOf(List<T> data, T item) {
    return data.tryIndexWhere((it) => it.uuid == item.uuid);
  }

  List<T> _replace(List<T> data, T item) {
    try {
      final index = _indexOf(data, item);
      if (index == -1) return [item, ...data];
      final items = [...data];
      items[index] = item;
      return [...items];
    } catch (_) {
      return data;
    }
  }

  List<Object?> get props => [
    data,
    isLoading,
    data.length,
    page,
    pages,
    limit,
    query,
  ];
}
