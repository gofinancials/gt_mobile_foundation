import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

abstract class AsyncData<T extends Equatable> {
  bool get isLoading;
  bool get isPristine;
  bool get hasError;
  bool get hasData;
  TaskError? get error;
  DateTime? get updatedAt;

  String? get errorMessage => error?.message;

  const AsyncData();

  AsyncData<T> copyWith();

  @override
  toString() {
    return "error => $error, hasData => $hasData, isLoading => $isLoading, updatedAt => $updatedAt, isPristine => $isPristine, hasError => $hasError";
  }
}

class FutureData<T extends Equatable> extends AsyncData<T> {
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
      error: this.error,
      updatedAt: DateTime.now(),
    );
  }

  FutureData<T> reset({required bool isLoading}) {
    return FutureData(
      data: null,
      isLoading: isLoading,
      updatedAt: DateTime.now(),
    );
  }

  List<Object?> get props => [data, isLoading, error, updatedAt];
}

class FutureListData<T extends Equatable> extends AsyncData<T> {
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
      error: this.error,
      updatedAt: DateTime.now(),
    );
  }

  FutureListData<T> reset({required bool isLoading}) {
    return FutureListData(
      data: [],
      isLoading: isLoading,
      updatedAt: DateTime.now(),
    );
  }

  FutureListData<T> updateSingleItem(T oldItem, T newItem) {
    if (!data.contains(oldItem)) return this;
    final index = data.indexOf(oldItem);
    final items = [...data];
    items[index] = newItem;
    return copyWith(data: items);
  }

  FutureListData<T> removeSingleItem(T item) {
    data.remove(item);
    return copyWith(data: data);
  }

  List<Object?> get props => [data, isLoading, error, updatedAt];
}

class PaginatedData<T extends Identifiable> extends AsyncData<T> {
  final List<T> data;
  @override
  final bool isLoading;
  @override
  final TaskError? error;
  final int page;
  final int pages;
  final int limit;
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

  bool get hasNext => page < pages;

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

  PaginatedData<T> addData(
    PaginatedData<T> pageData, {
    bool ensureUnique = false,
  }) {
    if (this == pageData) return this;
    List<T> items = [...data, ...pageData.data];

    if (ensureUnique) {
      List<T> uniqueItems = [];
      for (final item in items) {
        final index = _indexOf(uniqueItems, item);
        if (index != -1) continue;
        uniqueItems.add(item);
      }
      items = [...uniqueItems];
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

  PaginatedData<T> updateSingleItem(T oldItem, T newItem) {
    if (!data.contains(oldItem)) return addSingleItem(newItem);
    final items = _replace(data, oldItem);
    return PaginatedData(data: items, updatedAt: DateTime.now());
  }

  PaginatedData<T> removeSingleItem(T item) {
    data.remove(item);
    return PaginatedData(data: data, updatedAt: DateTime.now());
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
