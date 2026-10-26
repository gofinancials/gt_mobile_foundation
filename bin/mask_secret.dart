// Masks (or reveals) a configuration value for the `CONF_*_MASKED` env keys.
//
//   dart run gt_mobile_foundation:mask_secret <value>            # value -> masked
//   dart run gt_mobile_foundation:mask_secret --decode <masked>  # masked -> value
//
// Imports the codec alone, not foundation.dart, which pulls in Flutter and so
// cannot run under `dart run`. Never paste the output into a committed file:
// env files are gitignored for a reason.
import 'dart:io';

import 'package:gt_mobile_foundation/utilities/app_secret_codec.dart';

void main(List<String> args) {
  final decoding =
      args.isNotEmpty && (args.first == '--decode' || args.first == '-d');
  final values = decoding ? args.skip(1).toList() : args;

  if (values.isEmpty) {
    stderr.writeln(
      'usage: dart run gt_mobile_foundation:mask_secret '
      '[--decode] <value> [<value>...]',
    );
    exitCode = 64;
    return;
  }

  for (final value in values) {
    try {
      stdout.writeln(
        decoding ? AppSecretCodec.decode(value) : AppSecretCodec.encode(value),
      );
    } on Object catch (error) {
      stderr.writeln('$error');
      exitCode = 65;
    }
  }
}
