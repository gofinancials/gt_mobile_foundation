import 'package:gt_mobile_foundation/foundation.dart';

/// A simple stack data structure for tracking changes.
class ChangeStack<T> {
  final List<T> _storage;

  ChangeStack() : _storage = <T>[];

  ChangeStack.of(Iterable<T> elements) : _storage = List<T>.of(elements);

  /// Pushes a new [member] onto the stack.
  void push(T member) => _storage.add(member);

  /// Removes and returns the top member of the stack.
  T pop() => _storage.removeLast();

  /// Returns the top member of the stack without removing it.
  T? get peek => _storage.tryLast;

  bool get isEmpty => _storage.isEmpty;
  bool get isNotEmpty => _storage.isNotEmpty;

  @override
  String toString() => "${_storage.reversed}";

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChangeStack) return false;
    return [...other._storage] == [..._storage];
  }

  @override
  int get hashCode => _storage.hashCode;
}

/// A model that manages undo and redo functionality for a list of [Identifiable] objects.
class ChangeModel<T extends Identifiable> {
  final ChangeStack<List<T>> _undoStack;
  final ChangeStack<List<T>> _redoStack;
  final List<T> _changes;

  ChangeModel()
    : _undoStack = ChangeStack(),
      _redoStack = ChangeStack(),
      _changes = [];

  const ChangeModel._({
    required ChangeStack<List<T>> undoStack,
    required ChangeStack<List<T>> redoStack,
    required List<T> changes,
  }) : _undoStack = undoStack,
       _redoStack = redoStack,
       _changes = changes;

  ChangeModel<T> _copyWith({
    ChangeStack<List<T>>? undoStack,
    ChangeStack<List<T>>? redoStack,
    List<T>? changes,
  }) {
    return ChangeModel<T>._(
      undoStack: undoStack ?? _undoStack,
      redoStack: redoStack ?? _redoStack,
      changes: changes ?? _changes,
    );
  }

  _commitChange(T? change) {
    if (change == null) return;
    final changeIndex = _changes.indexWhere((it) => it.uuid == change.uuid);
    if (changeIndex != -1) _changes.removeAt(changeIndex);
    _changes.add(change);
  }

  /// Clears all changes and returns a new empty [ChangeModel].
  clear() => ChangeModel<T>();

  /// Records a change from [current] state to a new [change] state.
  ChangeModel<T> makeChange(T change, T current) {
    if (change == current) return this;
    return makeBatchChanges([change], [current]);
  }

  /// Records multiple changes at once.
  ChangeModel<T> makeBatchChanges(List<T> changes, List<T> currents) {
    if (changes.isEmpty) return this;

    for (final change in changes) {
      _commitChange(change);
    }
    _undoStack.push(currents);

    return _copyWith(
      undoStack: _undoStack,
      changes: _changes,
      redoStack: ChangeStack(),
    );
  }

  /// Reverts the last set of changes.
  undo() {
    if (!canUndo) return this;
    final previousStates = _undoStack.pop();
    final currentStates = <T>[];

    for (final previousState in previousStates) {
      final currentState = _changes.firstWhere(
        (it) => it.uuid == previousState.uuid,
        orElse: () => previousState,
      );
      currentStates.add(currentState);
      _commitChange(previousState);
    }
    _redoStack.push(currentStates);

    return _copyWith(
      undoStack: _undoStack,
      changes: _changes,
      redoStack: _redoStack,
    );
  }

  /// Reapplies the last reverted set of changes.
  redo() {
    if (!canRedo) return this;
    final nextStates = _redoStack.pop();
    final currentStates = <T>[];

    for (final nextState in nextStates) {
      final currentState = _changes.firstWhere(
        (it) => it.uuid == nextState.uuid,
        orElse: () => nextState,
      );
      currentStates.add(currentState);
      _commitChange(nextState);
    }
    _undoStack.push(currentStates);

    return _copyWith(
      undoStack: _undoStack,
      changes: _changes,
      redoStack: _redoStack,
    );
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasChanges => _changes.isNotEmpty;
  List<T> get changes => _changes;
  List<T>? get undoLatest => _undoStack.peek;
  List<T>? get redoLatest => _redoStack.peek;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChangeModel) return false;
    return other._undoStack == _undoStack &&
        other._redoStack == _redoStack &&
        [...other._changes] == [..._changes];
  }

  @override
  int get hashCode =>
      undoLatest.hashCode ^ redoLatest.hashCode ^ changes.hashCode;

  @override
  String toString() {
    return """
      canRedo -> $canRedo;
      canUndo -> $canUndo;
      hasChanges -> $hasChanges;
      changes -> $changes;
      undoLatest -> $undoLatest;
      redoLatest -> $redoLatest;
      undoStack -> $_undoStack;
      redoStack -> $_redoStack;
    """;
  }
}
