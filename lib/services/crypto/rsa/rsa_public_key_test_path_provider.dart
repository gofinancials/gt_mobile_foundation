import 'package:gt_mobile_foundation/foundation.dart';

/// {@category Services}
/// Returns a pre-supplied RSA public-key path for unit tests.
final class TestRsaPublicKeyPathProvider implements RsaPublicKeyPathProvider {
  final String path;

  const TestRsaPublicKeyPathProvider(this.path);

  @override
  Future<String> getPublicKeyPath({bool forceRefresh = false}) async => path;
}
