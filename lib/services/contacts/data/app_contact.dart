import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A contact the customer chose from their address book, in the shape a form
/// fills from.
class AppContact extends AppEquatable {
  /// The contact's name as the address book shows it.
  final String fullName;

  /// The contact's first phone number, or null when it has none.
  final String? phoneNumber;

  const AppContact({required this.fullName, this.phoneNumber});

  @override
  List<Object?> get props => [fullName, phoneNumber];
}
