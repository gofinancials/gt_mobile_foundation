import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Implementation of [AppContactService] using the native picker from the
/// `flutter_native_contact_picker` package.
///
/// Only the contact the customer chooses crosses into the app, so neither
/// platform asks for contacts permission and the address book is never read.
class AppContactServiceImpl implements AppContactService {
  final FlutterNativeContactPicker _picker = FlutterNativeContactPicker();

  @override
  Future<AppContact?> pickContact() async {
    try {
      final contact = await _picker.selectContact();
      if (contact == null) return null;

      return AppContact(
        fullName: contact.fullName?.trim() ?? "",
        phoneNumber: contact.phoneNumbers?.firstOrNull?.trim(),
      );
    } catch (e, t) {
      AppLogger.severe("$e", stackTrace: t, error: e);
      return null;
    }
  }
}
