import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/ad_config.dart';
import '../models/raasi_palan.dart';
import '../services/ad_service.dart';
import '../services/budget_rating_service.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/budget/budget_rating_dialog.dart';
import '../widgets/native_ad_widget.dart';
import '../widgets/zodiac_sign_icon.dart';
import 'raasi_sign_selector_screen.dart';

class RaasiPalanDetailScreen extends StatefulWidget {
  const RaasiPalanDetailScreen({
    super.key,
    required this.raasi,
    required this.type,
    required this.typeTitle,
    required this.repository,
  });

  final RaasiData raasi;
  final RaasiPalanType type;
  final String typeTitle;
  final CalendarRepository repository;

  @override
  State<RaasiPalanDetailScreen> createState() => _RaasiPalanDetailScreenState();
}

class _RaasiPalanDetailScreenState extends State<RaasiPalanDetailScreen> {
  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.tamilarworld.tamilar_calendar';

  RaasiPalanContent _content = RaasiPalanContent.empty;
  bool _loading = true;
  bool _handlingBack = false;

  RaasiData get raasi => widget.raasi;
  RaasiPalanType get type => widget.type;

  String get _typeLabel {
    switch (type) {
      case RaasiPalanType.today:
        return 'இன்றைய ராசிபலன்';
      case RaasiPalanType.weekly:
        return 'வார ராசிபலன்';
      case RaasiPalanType.monthly:
        return 'மாத ராசிபலன்';
      case RaasiPalanType.yearly:
        return 'ஆண்டு ராசிபலன்';
    }
  }

  Color get _typeColor {
    switch (type) {
      case RaasiPalanType.today:
        return const Color(0xFF4A148C);
      case RaasiPalanType.weekly:
        return const Color(0xFF0077B6);
      case RaasiPalanType.monthly:
        return const Color(0xFFE65100);
      case RaasiPalanType.yearly:
        return const Color(0xFFAD1457);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final content = await widget.repository.getRaasiPalan(
      period: type.apiPeriod,
      signIndex: raasi.index,
    );
    if (!mounted) return;
    setState(() {
      _content = content;
      _loading = false;
    });
  }

  String get _shareText {
    final buf = StringBuffer()
      ..writeln('${raasi.nameTa} ராசி - $_typeLabel')
      ..writeln();

    void addSection(String title, String raw) {
      final plain = RaasiPalanContent.plainForShare(raw).trim();
      if (plain.isEmpty) return;
      buf
        ..writeln(title)
        ..writeln(plain)
        ..writeln();
    }

    if (type == RaasiPalanType.yearly) {
      addSection('கிரக சஞ்சார பலன்கள்', _content.grahamSancharamTa);
      addSection('பொதுப் பலன்கள்', _content.generalTa);
      addSection('⭐ நட்சத்திர பலன்கள்', _content.nakshatraPalanTa);
      addSection('🌟 இந்த ஆண்டின் சிறப்புகள்', _content.specialTa);
      addSection('⚠️ கவனமாக இருக்க வேண்டியவை', _content.cautionsTa);
      if (!_content.hasAnyContent) {
        buf.writeln('பலன் விரைவில் சேர்க்கப்படும்…');
      }
    } else {
      final body =
          RaasiPalanContent.plainForShare(_content.generalTa).trim();
      if (body.isEmpty) {
        buf.writeln('பலன் விரைவில் சேர்க்கப்படும்…');
      } else {
        buf.writeln(body);
      }
    }

    buf
      ..writeln()
      ..writeln('— தமிழர் உலகம்');
    return buf.toString().trim();
  }

  Future<void> _share() async {
    if (_loading) return;
    await SharePlus.instance.share(
      ShareParams(
        text: _shareText,
        subject: '${raasi.nameTa} - $_typeLabel',
      ),
    );
  }

  Future<void> _openPlayStore() async {
    final uri = Uri.parse(_playStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _finishBack() async {
    if (!mounted) return;
    await AdService.instance.showInterstitialOncePerSession(
      onFinished: () {
        if (mounted) Navigator.pop(context);
      },
    );
  }

  Future<void> _handleBack() async {
    if (_handlingBack) return;
    _handlingBack = true;
    try {
      final hasRated = await BudgetRatingService.instance.hasAcceptedRating();
      if (!hasRated) {
        if (!mounted) return;
        final choice = await showBudgetRatingDialog(context);
        if (!mounted) return;
        if (choice == BudgetRatingChoice.yes) {
          await BudgetRatingService.instance.markRatingAccepted();
          await _openPlayStore();
          if (!mounted) return;
          await _finishBack();
          return;
        }
        if (choice == BudgetRatingChoice.maybe) {
          await _finishBack();
          return;
        }
        return;
      }

      await _finishBack();
    } finally {
      _handlingBack = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          title: Text(widget.typeTitle),
          backgroundColor: AppColors.cream,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          actions: [
            IconButton(
              tooltip: 'பகிர்',
              onPressed: _loading ? null : _share,
              icon: const Icon(Icons.share_rounded),
            ),
          ],
        ),
        floatingActionButton: _loading
            ? null
            : FloatingActionButton.extended(
                onPressed: _share,
                backgroundColor: _typeColor,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.share_rounded),
                label: const Text('பகிர்'),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: NativeAdWidget(
          adUnitId: AdConfig.raasiPalanNativeUnitId,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  children: [
                    _buildTitleCard(context),
                    const SizedBox(height: 16),
                    if (!_content.hasAnyContent)
                      _emptyState(context)
                    else if (type == RaasiPalanType.yearly)
                      ..._buildYearlySections(context)
                    else
                      _buildTextCard(context, _content.generalTa),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.card(),
      child: Text(
        'பலன் விரைவில் சேர்க்கப்படும்…',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildTitleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AppDecorations.card(),
      child: Row(
        children: [
          ZodiacSignIcon(
            index: raasi.index,
            size: 56,
            borderRadius: 10,
            showGoldenBg: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.star_rounded, color: _typeColor, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${raasi.nameTa} ராசி - $_typeLabel',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  raasi.nameEn,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildYearlySections(BuildContext context) {
    final sections = <(String, String)>[
      ('கிரக சஞ்சார பலன்கள்', _content.grahamSancharamTa),
      ('பொதுப் பலன்கள்', _content.generalTa),
      ('⭐ நட்சத்திர பலன்கள்', _content.nakshatraPalanTa),
      ('🌟 இந்த ஆண்டின் சிறப்புகள்', _content.specialTa),
      ('⚠️ கவனமாக இருக்க வேண்டியவை', _content.cautionsTa),
    ];

    final widgets = <Widget>[];
    for (final (title, raw) in sections) {
      if (raw.trim().isEmpty) continue;
      if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
      widgets.add(_buildSectionCard(context, title: title, body: raw));
    }
    return widgets;
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _typeColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildRichBody(context, body),
        ],
      ),
    );
  }

  Widget _buildTextCard(BuildContext context, String raw) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card(),
      child: _buildRichBody(context, raw),
    );
  }

  Widget _buildRichBody(BuildContext context, String raw) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          height: 1.55,
        ) ??
        const TextStyle(height: 1.55, color: AppColors.textPrimary);

    final paragraphs = RaasiPalanContent.paragraphsOf(raw);
    final blocks = paragraphs.isEmpty ? <String>[raw.trim()] : paragraphs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          Text.rich(
            TextSpan(
              children: RaasiPalanContent.richSpans(blocks[i], base: base),
            ),
          ),
          if (i < blocks.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}
