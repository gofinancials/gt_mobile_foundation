import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Picks a contact from the device's address book.
abstract class AppContactService {
  /// Opens the platform's own contact picker and returns what the customer
  /// chose, or null when they backed out.
  ///
  /// A failed pick also returns null, so a caller has one outcome to handle
  /// besides a contact.
  Future<AppContact?> pickContact();
}
