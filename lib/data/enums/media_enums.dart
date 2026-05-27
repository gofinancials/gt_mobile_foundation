/// Defines the origin or source location of a media file.
enum AppMediaOrigin {
  /// The media is hosted on the internet and accessed via a URL.
  network,

  /// The media is bundled with the application as a local asset.
  asset,

  /// The media is stored locally on the device's file system.
  file,

  /// The media is stored in memory as a byte array (Uint8List).
  memory,

  /// The media origin is unknown or invalid.
  invalid,
}

/// Represents the specific type or format of a media file.
enum AppMediaType {
  /// An image file (e.g., JPEG, PNG, WEBP).
  image,

  /// A Microsoft Word document.
  docx,

  /// A Portable Document Format (PDF) file.
  pdf,

  /// A Comma-Separated Values file.
  csv,

  /// An audio file (e.g., MP3, WAV).
  audio,

  /// A standard video file (e.g., MP4).
  video,

  /// A video hosted on YouTube.
  youtube;

  /// Returns `true` if the media type is a YouTube video.
  bool get isYoutubeMedia => this == AppMediaType.youtube;

  /// Returns `true` if the media type is an audio file.
  bool get isAudioMedia => this == AppMediaType.audio;

  /// Returns `true` if the media type is a standard video file.
  bool get isVideoMedia => this == AppMediaType.video;

  /// Returns `true` if the media type is an image.
  bool get isImage => this == AppMediaType.image;

  /// Returns `true` if the media type is a Word document.
  bool get isDoc => this == AppMediaType.docx;

  /// Returns `true` if the media type is a PDF.
  bool get isPdf => this == AppMediaType.pdf;

  /// Returns `true` if the media type is a CSV file.
  bool get isCsv => this == AppMediaType.csv;

  /// Parses a string representation into an [AppMediaType].
  /// Defaults to [image] if the string does not match a known type.
  static AppMediaType fromString(String? value) {
    return switch (value) {
      "youtube" => youtube,
      "video" => video,
      "audio" => audio,
      "docx" => docx,
      "pdf" => pdf,
      "csv" => csv,
      _ => image,
    };
  }
}
