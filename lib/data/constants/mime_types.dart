/// {@category Data}
/// Contains a set of common MIME type strings used for file and network operations.
///
/// Values match what [AppMimeResolver] returns, so they can be compared
/// directly with resolved types.
class AppMimeTypes {
  static const any = "*/*";
  static const octetStream = "application/octet-stream";

  static const image = "image/*";
  static const jpeg = "image/jpeg";
  static const png = "image/png";
  static const webp = "image/webp";
  static const gif = "image/gif";
  static const heic = "image/heic";
  static const heif = "image/heif";
  static const avif = "image/avif";
  static const bmp = "image/bmp";
  static const tiff = "image/tiff";
  static const svg = "image/svg+xml";

  static const audio = "audio/*";
  static const mp3 = "audio/mpeg";
  static const aac = "audio/aac";
  static const m4a = "audio/mp4";
  static const wav = "audio/x-wav";
  static const ogg = "audio/ogg";
  static const amr = "audio/amr";

  static const video = "video/*";
  static const mp4 = "video/mp4";
  static const mov = "video/quicktime";
  static const webm = "video/webm";

  static const txt = "text/plain";
  static const csv = "text/csv";
  static const html = "text/html";
  static const json = "application/json";
  static const xml = "application/xml";
  static const pdf = "application/pdf";
  static const rtf = "application/rtf";
  static const zip = "application/zip";
  static const doc = "application/msword";
  static const docx =
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  static const xls = "application/vnd.ms-excel";
  static const xlsx =
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  static const ppt = "application/vnd.ms-powerpoint";
  static const pptx =
      "application/vnd.openxmlformats-officedocument.presentationml.presentation";
}
