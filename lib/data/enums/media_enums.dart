/// Specifies the origin of a media asset.
enum MediaOrigin {
  /// Media loaded from a network URL.
  network,

  /// Media loaded from an app asset.
  asset,

  /// Media loaded from a local file.
  file,

  /// Media loaded from memory (e.g. Uint8List).
  memory,

  /// Invalid or unknown media origin.
  invalid,
}

/// Specifies the type of media.
enum MediaType {
  /// Audio media type.
  audio,

  /// Video media type.
  video,

  /// Image media type.
  image;

  const MediaType();

  /// Returns `true` if this media type is [audio].
  bool get isAudio => this == MediaType.audio;

  /// Returns `true` if this media type is [video].
  bool get isVideo => this == MediaType.video;

  /// Parses a string representation into a [MediaType].
  /// Defaults to [image] if the string doesn't match known types.
  static MediaType fromString(String? value) {
    return switch (value) {
      "video" => video,
      "audio" => audio,
      _ => image,
    };
  }
}
