import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Typedefs}
/// A [ValueNotifier] that holds a [Future] resulting in a [TaskResponse] of type [T].
/// Useful for tracking asynchronous operations and their loading/error states.
typedef TaskNotifier<T> = ValueNotifier<Future<TaskResponse<T>>?>;

/// {@category Typedefs}
/// Signature for a standard synchronous callback with no arguments.
typedef OnPressed = void Function();

/// {@category Typedefs}
/// Signature for an asynchronous callback with no arguments.
typedef OnPressedAsync = Future<void> Function();

/// {@category Typedefs}
/// Signature for a function that formats a numeric value into a string.
typedef ValueFormatter = String Function(num value);

/// {@category Typedefs}
/// Signature for a callback that generates a dynamic route from [RouteSettings].
typedef OnDynamicRoute = Route<dynamic> Function(RouteSettings settings);

/// {@category Typedefs}
/// Signature for a generic callback triggered when a value of type [T] changes.
typedef OnChanged<T> = void Function(T value);

/// {@category Typedefs}
/// Signature for a generic callback triggered when two values change.
typedef OnChanged2<T, K> = void Function(T value, K otherValue);

/// {@category Typedefs}
/// Signature for an asynchronous callback triggered when a value of type [T] changes.
typedef OnChangedAsync<T> = Future<void> Function(T value);

/// {@category Typedefs}
/// Signature for an asynchronous task that returns a [TaskResponse] of type [T].
typedef TaskCallResponse<T> = Future<TaskResponse<T>>;

/// {@category Typedefs}
/// Signature for an asynchronous operation returning type [T].
typedef FutureCall<T> = Future<T> Function();

/// {@category Typedefs}
/// Signature for a synchronous operation returning type [T].
typedef FunctionCall<T> = T Function();

/// {@category Typedefs}
/// Signature for a function that transforms dynamic input into a value of type [T].
typedef TransformCall<T> = T Function(dynamic input);

/// {@category Typedefs}
/// Signature for a validation callback that returns an error string, or null if valid.
typedef OnValidate<T> = String? Function(T value);

/// {@category Typedefs}
/// Signature for a validation callback that returns a boolean indicating validity.
typedef OnBoolValidation<T> = bool Function(T value);

/// {@category Typedefs}
/// Signature for a callback that maps an item of type [T] to type [E].
typedef MapCallback<E, T> = E Function(T e);

/// {@category Typedefs}
/// Signature for a builder that creates a [Widget] based on an index.
typedef ItemBuilder = Widget Function(BuildContext context, int index);

/// {@category Typedefs}
/// Signature for a builder that creates a [Widget] from a value of type [T].
typedef ValueBuilder<T> = Widget Function(T value);

/// {@category Typedefs}
/// Signature for a builder that creates a [Widget] from two generic values.
typedef ValueBuilder2<T, K> = Widget Function(T value, K value2);

/// {@category Typedefs}
/// Signature for a delegate function that performs a search and returns type [T].
typedef AppSearchDelegate<T> = T Function(String query);

/// {@category Typedefs}
/// Signature for an asynchronous task that takes input [K] and returns [TaskResponse] of [T].
typedef TaskCallWithInput<T, K> = TaskCallResponse<T> Function(K input);

/// {@category Typedefs}
/// A tuple containing two values of types [T] and [K].
typedef Tuple2<T, K> = (T, K);

/// {@category Typedefs}
/// Signature for a navigation callback invoked with a route name, optional context, and arguments.
typedef OnNavigate =
    Function(String routeName, {BuildContext? context, Object? arguments});

/// {@category Typedefs}
/// An alias for [Equatable] to abstract the underlying implementation.
typedef AppEquatable = Equatable;
