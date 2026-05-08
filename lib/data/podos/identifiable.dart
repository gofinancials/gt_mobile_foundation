import 'package:equatable/equatable.dart';

/// {@category Data}
/// An abstract base class for any model that requires a unique [uuid].
class Identifiable extends Equatable {
  final String uuid;

  const Identifiable({required this.uuid});

  @override
  List<Object?> get props => [uuid];
}
