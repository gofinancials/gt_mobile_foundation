/// {@category Data}
/// Base interface for defining callable use cases within the application layer.
abstract class UsecaseModel<T> {
  T call();
}
