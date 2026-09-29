import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// A mock implementation of [AppContactService] for testing.
///
/// Returns [contact] from every pick, so a widget test can fill a form from a
/// contact without a platform channel. Pass `null` to act as a customer who
/// backs out.
class AppContactServiceMock implements AppContactService {
  final AppContact? contact;

  const AppContactServiceMock({
    this.contact = const AppContact(
      fullName: "Ada Obi",
      phoneNumber: "08012345678",
    ),
  });

  @override
  Future<AppContact?> pickContact() async => contact;
}
