import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

enum _Tier { basic, premium }

void main() {
  group('AppJson.asMap', () {
    test('passes a string-keyed map through', () {
      expect(AppJson.asMap({'a': 1}), {'a': 1});
    });

    test('normalises the object-keyed map a decoded envelope hands back', () {
      final Map<Object?, Object?> decoded = {'a': 1, 2: 'b'};

      expect(AppJson.asMap(decoded), {'a': 1, '2': 'b'});
    });

    test('a non-map value becomes the caller fallback', () {
      expect(AppJson.asMap('not a map'), isEmpty);
      expect(AppJson.asMap(null), isEmpty);
      expect(AppJson.asMap(7, fallback: const {'a': 1}), {'a': 1});
    });
  });

  group('AppJson.asNum', () {
    test('reads a number as itself', () {
      expect(AppJson.asNum(1500), 1500);
      expect(AppJson.asNum(1500.5), 1500.5);
    });

    test('survives a thousands separator', () {
      expect(AppJson.asNum('1,500'), 1500);
    });

    test('survives a currency prefix', () {
      expect(AppJson.asNum('NGN 1,500.50'), 1500.50);
    });

    test('keeps a minus sign, which extractAmount drops', () {
      expect(AppJson.asNum('-1,500'), -1500);
      expect(AppHelpers.extractAmount('-1,500'), 1500);
    });

    test('an unreadable value becomes the caller fallback', () {
      expect(AppJson.asNum('abc'), 0);
      expect(AppJson.asNum(null, fallback: -1), -1);
    });
  });

  group('AppJson.asInt', () {
    test('truncates a double', () {
      expect(AppJson.asInt(1500.9), 1500);
    });

    test('reads a numeric string', () {
      expect(AppJson.asInt('1500'), 1500);
    });

    test('an unreadable value becomes the caller fallback', () {
      expect(AppJson.asInt('abc', fallback: 7), 7);
    });
  });

  group('AppJson.asFlag', () {
    test('reads every spelling the gateway sends', () {
      expect(AppJson.asFlag(true), isTrue);
      expect(AppJson.asFlag(false), isFalse);
      expect(AppJson.asFlag(1), isTrue);
      expect(AppJson.asFlag(0), isFalse);
      expect(AppJson.asFlag('true'), isTrue);
      expect(AppJson.asFlag('TRUE'), isTrue);
      expect(AppJson.asFlag('1'), isTrue);
      expect(AppJson.asFlag('false'), isFalse);
      expect(AppJson.asFlag('0'), isFalse);
    });

    test('absence is not the same answer as false', () {
      expect(AppJson.asFlag(null), isNull);
      expect(AppJson.asFlag('maybe'), isNull);
    });
  });

  group('AppJson.asEnum', () {
    test('matches the wire name, ignoring case and space', () {
      expect(AppJson.asEnum(_Tier.values, 'premium'), _Tier.premium);
      expect(AppJson.asEnum(_Tier.values, ' PREMIUM '), _Tier.premium);
    });

    test('a name this app does not know is null', () {
      expect(AppJson.asEnum(_Tier.values, 'platinum'), isNull);
      expect(AppJson.asEnum(_Tier.values, null), isNull);
    });
  });

  group('AppJson.decodeList', () {
    test('decodes the map entries and ignores malformed ones', () {
      final value = [
        {'name': 'a'},
        'not a map',
        <Object?, Object?>{'name': 'b'},
        null,
      ];

      expect(AppJson.decodeList(value, (json) => json['name']), ['a', 'b']);
    });

    test('a non-list value decodes to empty', () {
      expect(AppJson.decodeList({'a': 1}, (json) => json), isEmpty);
    });
  });

  group('AppJson.payload', () {
    test('reads the record nested under each key the gateway uses', () {
      for (final key in AppJson.payloadKeys) {
        expect(
          AppJson.payload({
            key: {'id': 1},
          }),
          {'id': 1},
        );
      }
    });

    test('decodes a record sent as a JSON string', () {
      expect(AppJson.payload({'data': '{"id": 1}'}), {'id': 1});
    });

    test('a string that is not JSON counts as absent', () {
      expect(AppJson.payload({'data': 'unparseable'}), {'data': 'unparseable'});
    });

    test('a reply nesting nothing is its own payload', () {
      expect(AppJson.payload({'id': 1}), {'id': 1});
    });
  });

  group('AppJson.successFlag', () {
    for (final key in AppJson.successKeys) {
      test('reads the $key spelling', () {
        expect(AppJson.successFlag({key: true}), isTrue);
        expect(AppJson.successFlag({key: false}), isFalse);
      });
    }

    test('a reply that reported neither way is null, not false', () {
      expect(AppJson.successFlag({'data': 1}), isNull);
      expect(AppJson.successFlag({}), isNull);
    });

    test('reads a numeric flag', () {
      expect(AppJson.successFlag({'isSuccessful': 1}), isTrue);
      expect(AppJson.successFlag({'isSuccessful': 0}), isFalse);
    });

    test('an unrecognised string is a refusal unless strict', () {
      expect(AppJson.successFlag({'isSuccessful': 'maybe'}), isFalse);
      expect(
        AppJson.successFlag({'isSuccessful': 'maybe'}, strict: true),
        isNull,
      );
    });
  });

  group('AppJson.message', () {
    for (final key in AppJson.messageKeys) {
      test('reads the $key spelling', () {
        expect(
          AppJson.message({key: 'Insufficient funds'}),
          'Insufficient funds',
        );
      });
    }

    test('prefers the earlier spelling when a reply carries both', () {
      expect(
        AppJson.message({'responseMessage': 'first', 'message': 'second'}),
        'first',
      );
    });

    test('a reply with no message reads as empty', () {
      expect(AppJson.message({'data': 1}), isEmpty);
    });
  });

  group('AppJson lookups by key', () {
    test('valueAt returns the first key present, even when null', () {
      expect(AppJson.valueAt({'b': 2}, ['a', 'b']), 2);
      expect(AppJson.valueAt({'a': null, 'b': 2}, ['a', 'b']), isNull);
      expect(AppJson.valueAt({'c': 3}, ['a', 'b']), isNull);
    });

    test('stringAt skips a key whose value is empty', () {
      expect(AppJson.stringAt({'a': '', 'b': ' name '}, ['a', 'b']), 'name');
      expect(AppJson.stringAt({'a': ''}, ['a']), isEmpty);
    });

    test('numAt skips a key that carries no number', () {
      expect(AppJson.numAt({'a': 'abc', 'b': '1,500'}, ['a', 'b']), 1500);
      expect(AppJson.numAt({'a': 'abc'}, ['a']), 0);
    });

    test('flagAt skips a key that carries no answer', () {
      expect(AppJson.flagAt({'a': 'maybe', 'b': true}, ['a', 'b']), isTrue);
      expect(AppJson.flagAt({'a': 'maybe'}, ['a']), isNull);
    });
  });
}
