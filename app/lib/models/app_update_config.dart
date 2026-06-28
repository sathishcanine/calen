class AppUpdateConfig {
  const AppUpdateConfig({
    required this.title,
    required this.whatsNewItems,
    required this.storeUrl,
    this.buttonText = 'புதுப்பிக்கவும் / Update Now',
  });

  final String title;
  final List<String> whatsNewItems;
  final String storeUrl;
  final String buttonText;

  factory AppUpdateConfig.fromRemoteData({
    required Map<String, dynamic> updateData,
    required String defaultStoreUrl,
  }) {
    final title = (updateData['title'] as String?)?.trim();
    final whatsNew = (updateData['whats_new'] as String?) ?? '';
    final storeUrl = (updateData['store_url'] as String?)?.trim();
    final buttonText = (updateData['button_text'] as String?)?.trim();

    return AppUpdateConfig(
      title: title?.isNotEmpty == true ? title! : 'புதிய பதிப்பு கிடைக்கிறது',
      whatsNewItems: _parseWhatsNew(whatsNew),
      storeUrl: storeUrl?.isNotEmpty == true ? storeUrl! : defaultStoreUrl,
      buttonText: buttonText?.isNotEmpty == true
          ? buttonText!
          : 'புதுப்பிக்கவும் / Update Now',
    );
  }

  static List<String> _parseWhatsNew(String raw) {
    if (raw.trim().isEmpty) return [];

    final items = raw.split(RegExp(r',(?=#\d+)')).map((s) => s.trim()).toList();
    return items
        .map((item) => item.replaceFirst(RegExp(r'^#\d+\s*'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
