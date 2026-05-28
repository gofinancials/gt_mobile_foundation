/// {@category Data}
/// Base class for all model objects that can be serialized to JSON.
abstract class Codable {
  const Codable();

  dynamic toJson();
}

abstract class MapCodable extends Codable {
  const MapCodable();

  @override
  Map<String, dynamic> toJson();
}

abstract class ListCodable extends Codable {
  const ListCodable();

  @override
  List toJson();
}
