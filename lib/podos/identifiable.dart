import 'package:equatable/equatable.dart';

class Identifiable extends Equatable {
  final String uuid;

  const Identifiable({required this.uuid});

  @override
  List<Object?> get props => [uuid];
}
