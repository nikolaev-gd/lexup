class TextUtils {
  static String fixEncoding(String text) {
    return text
        .replaceAll('â', "'")
        .replaceAll('â', '"')
        .replaceAll('â', '"')
        .replaceAll('â', '–');
  }
}
