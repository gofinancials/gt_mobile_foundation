enum MediaOrigin { network, asset, file, memory, invalid }

enum MediaType {
  audio,
  video,
  image;

  const MediaType();

  bool get isAudio => this == .audio;
  bool get isVideo => this == .video;

  static MediaType fromString(String? value) {
    return switch (value) {
      "video" => video,
      "audio" => audio,
      _ => image,
    };
  }
}
