import 'package:equatable/equatable.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Data}
/// A Nigerian state with its capital, local government areas and towns.
///
/// Read from the bundled `states_lgs_towns.json` asset by
/// [AppNigerianStateUtility]. Towns are listed per state, not per LGA.
class NigerianState extends Equatable {
  /// The state's name, such as `Abia` or `Akwa Ibom`.
  final String name;

  /// The state's capital city, such as `Umuahia`.
  final String? capital;

  /// The names of the state's local government areas.
  final List<String> lgas;

  /// The names of the state's towns.
  final List<String> towns;

  const NigerianState({
    required this.name,
    this.capital,
    this.lgas = const [],
    this.towns = const [],
  });

  factory NigerianState.fromJson(Map json) {
    return NigerianState(
      name: json['name'] ?? '',
      capital: json['capital'],
      lgas: _parseNames(json['lgas']),
      towns: _parseNames(json['towns']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'capital': capital, 'lgas': lgas, 'towns': towns};
  }

  static List<String> _parseNames(dynamic names) {
    if (names is! List) return const [];
    return List.unmodifiable(names.whereType<String>());
  }

  @override
  List<Object?> get props => [name, capital, lgas, towns];
}
