import 'package:flutter_native_contact_picker/flutter_native_contact_picker_platform_interface.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeContactPicker extends FlutterNativeContactPickerPlatform
    with MockPlatformInterfaceMixin {
  Contact? contact;
  Object? failure;

  @override
  Future<Contact?> selectContact() async {
    if (failure case final error?) throw error;
    return contact;
  }
}

void main() {
  late _FakeContactPicker picker;

  setUp(() {
    picker = _FakeContactPicker();
    FlutterNativeContactPickerPlatform.instance = picker;
  });

  group('AppContactServiceImpl.pickContact', () {
    test('returns the name and phone number chosen', () async {
      picker.contact = Contact(
        fullName: " Ada Obi ",
        phoneNumbers: [" 0801 234 5678 ", "0802"],
      );

      expect(
        await AppContactServiceImpl().pickContact(),
        const AppContact(fullName: "Ada Obi", phoneNumber: "0801 234 5678"),
      );
    });

    test('leaves out a phone number the contact does not have', () async {
      picker.contact = Contact(fullName: "Ada Obi", phoneNumbers: []);

      expect(
        await AppContactServiceImpl().pickContact(),
        const AppContact(fullName: "Ada Obi"),
      );
    });

    test('returns null when the customer backs out', () async {
      expect(await AppContactServiceImpl().pickContact(), isNull);
    });

    test('returns null when the picker fails', () async {
      picker.failure = Exception('multiple_requests');

      expect(await AppContactServiceImpl().pickContact(), isNull);
    });
  });

  group('AppContactServiceMock', () {
    test('returns a contact without a platform channel', () async {
      expect(await const AppContactServiceMock().pickContact(), isNotNull);
    });

    test('returns the contact it is given', () async {
      const contact = AppContact(fullName: "Tunde", phoneNumber: "0803");

      expect(
        await const AppContactServiceMock(contact: contact).pickContact(),
        contact,
      );
    });

    test('can act as a customer who backs out', () async {
      expect(
        await const AppContactServiceMock(contact: null).pickContact(),
        isNull,
      );
    });
  });
}
