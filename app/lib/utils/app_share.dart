/// Shared Play Store link + Tamil install line for all share sheets.
class AppShare {
  AppShare._();

  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.tamilarworld.tamilar_calendar';

  /// One-line Tamil CTA + store URL (prepended with blank line when appended).
  static const installFooter =
      'முருகன் காலண்டரை இலவசமாக நிறுவுங்கள்: $playStoreUrl';

  /// Appends the install footer to [body] (skips if already present).
  static String withInstallFooter(String body) {
    final trimmed = body.trim();
    if (trimmed.contains(playStoreUrl)) return trimmed;
    if (trimmed.isEmpty) return installFooter;
    return '$trimmed\n\n$installFooter';
  }
}
