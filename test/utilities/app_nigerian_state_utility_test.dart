import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gt_mobile_foundation/foundation.dart';

const _assetPath = 'assets/resources/states_lgs_towns.json';
const _assetKey = 'packages/gt_mobile_foundation/$_assetPath';

/// Serves the bundled asset from disk, since a package's assets are not
/// registered under its `packages/` key when the package itself is tested.
Future<ByteData?> _serveAsset(ByteData? message) async {
  final key = utf8.decode(message!.buffer.asUint8List());
  if (key != _assetKey) return null;

  final bytes = File(_assetPath).readAsBytesSync();
  return ByteData.sublistView(bytes);
}

bool _isIncomplete(NigerianState state) {
  final hasLists = state.lgas.isNotEmpty && state.towns.isNotEmpty;
  return state.name.isEmpty || !hasLists;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final binding = TestDefaultBinaryMessengerBinding.instance;
    final messenger = binding.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', _serveAsset);
  });

  group('NigerianState.fromJson', () {
    test('reads the name, capital, LGAs and towns', () {
      final json = {
        'name': 'Abia',
        'capital': 'Umuahia',
        'lgas': ['Aba North'],
        'towns': ['Abiriba'],
      };
      const expected = NigerianState(
        name: 'Abia',
        capital: 'Umuahia',
        lgas: ['Aba North'],
        towns: ['Abiriba'],
      );

      expect(NigerianState.fromJson(json), expected);
    });

    test('defaults missing lists to empty', () {
      final state = NigerianState.fromJson({'name': 'Abia'});

      expect(state.lgas, isEmpty);
      expect(state.towns, isEmpty);
    });

    test('drops entries that are not strings', () {
      final json = {
        'name': 'Abia',
        'lgas': ['Aba North', null, 4],
      };

      expect(NigerianState.fromJson(json).lgas, ['Aba North']);
    });

    test('round-trips through toJson', () {
      const state = NigerianState(name: 'Abia', capital: 'Umuahia');

      expect(NigerianState.fromJson(state.toJson()), state);
    });
  });

  group('AppNigerianStateUtility', () {
    test('fetches every state in the bundled asset', () async {
      final raw = File(_assetPath).readAsStringSync();
      final assetCount = (jsonDecode(raw) as List).length;

      final states = await AppNigerianStateUtility.fetchStates();

      expect(states, hasLength(assetCount));
      expect(states.first.name, 'Abia');
    });

    test('every state has a name, LGAs and towns', () async {
      final states = await AppNigerianStateUtility.fetchStates();

      expect(states.whereList(_isIncomplete), isEmpty);
    });

    test('searches states by name or capital, ignoring case', () async {
      final byName = await AppNigerianStateUtility.searchStates('akwa');
      final byCapital = await AppNigerianStateUtility.searchStates('UMUAHIA');

      expect(byName.map((it) => it.name), ['Akwa Ibom']);
      expect(byCapital.map((it) => it.name), ['Abia']);
    });

    test('returns every state for an empty search', () async {
      final states = await AppNigerianStateUtility.fetchStates();

      expect(await AppNigerianStateUtility.searchStates(''), states);
    });

    test('finds a state by name, ignoring case and spaces', () async {
      final state = await AppNigerianStateUtility.findState(' akwa ibom ');

      expect(state?.capital, 'Uyo');
    });

    test('finds no state for an unknown name', () async {
      expect(await AppNigerianStateUtility.findState('Atlantis'), isNull);
    });

    test('finds the state an LGA belongs to', () async {
      final state = await AppNigerianStateUtility.findStateByLga('nnewi north');

      expect(state?.name, 'Anambra');
    });

    test('fetches the LGAs of a state', () async {
      final lgas = await AppNigerianStateUtility.fetchLgas('Abia');

      expect(lgas, contains('Aba North'));
      expect(lgas, hasLength(17));
    });

    test('fetches no LGAs for an unknown state', () async {
      expect(await AppNigerianStateUtility.fetchLgas('Atlantis'), isEmpty);
    });

    test('searches the LGAs of a state', () async {
      final lgas = await AppNigerianStateUtility.searchLgas('Abia', 'aba');

      expect(lgas, ['Aba North', 'Aba South']);
    });

    test('fetches the towns of a state', () async {
      final towns = await AppNigerianStateUtility.fetchTowns('Abia');

      expect(towns, contains('Abiriba'));
    });

    test('searches the towns of a state', () async {
      final towns = await AppNigerianStateUtility.searchTowns('Abia', 'aroch');

      expect(towns, ['Arochukwu', 'Arochukwu Town']);
    });

    test('searches no towns for an unknown state', () async {
      final towns = await AppNigerianStateUtility.searchTowns('Atlantis', 'a');

      expect(towns, isEmpty);
    });
  });
}
