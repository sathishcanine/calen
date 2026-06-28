import 'package:flutter/material.dart';

import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

/// பஞ்ச பட்சி informational article / bird grid detail.
class PanchaPakshiArticleScreen extends StatefulWidget {
  const PanchaPakshiArticleScreen({
    super.key,
    required this.repository,
    required this.articleId,
  });

  final CalendarRepository repository;
  final int articleId;

  @override
  State<PanchaPakshiArticleScreen> createState() => _PanchaPakshiArticleScreenState();
}

class _PanchaPakshiArticleScreenState extends State<PanchaPakshiArticleScreen> {
  Map<String, dynamic>? _content;
  String _title = '';
  String _kind = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.repository.getPanchaPakshiArticle(widget.articleId);
      if (mounted) {
        setState(() {
          _title = detail.titleTa;
          _kind = detail.kind;
          _content = detail.content;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: Text(_title.isEmpty ? 'பஞ்ச பட்சி சாஸ்திரம்' : _title, style: const TextStyle(fontSize: 15)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildBody() {
    final c = _content ?? {};
    final children = <Widget>[];

    final subtitle = c['subtitle_ta'] as String?;
    if (subtitle != null && subtitle.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    for (final p in (c['paragraphs_ta'] as List<dynamic>? ?? [])) {
      children.add(_BulletParagraph(text: p as String));
    }

    for (final item in (c['list_items_ta'] as List<dynamic>? ?? [])) {
      children.add(_BulletParagraph(text: item as String));
    }

    for (final bird in (c['birds_ta'] as List<dynamic>? ?? [])) {
      children.add(Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Text(bird as String, style: const TextStyle(fontSize: 14)),
      ));
    }

    final strengthRows = c['strength_rows'] as List<dynamic>?;
    if (strengthRows != null && strengthRows.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_StrengthTable(rows: strengthRows));
    }

    final friendRows = c['friend_rows'] as List<dynamic>?;
    if (friendRows != null && friendRows.isNotEmpty) {
      children.add(const SizedBox(height: 12));
      children.add(_FriendTable(rows: friendRows));
    }

    if (_kind == 'bird_grid') {
      children.add(const SizedBox(height: 16));
      children.add(const Text(
        'பகல்பொழுது (காலை 06.01 AM முதல் மாலை 06.00 PM வரை)',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ));
      children.add(_WeekGrid(rows: c['day_rows'] as List<dynamic>? ?? []));
      children.add(const SizedBox(height: 20));
      children.add(const Text(
        'இரவுப்பொழுது (மாலை 06.01 PM முதல் காலை 06.00 AM வரை)',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ));
      children.add(_WeekGrid(rows: c['night_rows'] as List<dynamic>? ?? []));
    }

    final footer = c['footer_ta'] as String?;
    if (footer != null) {
      children.add(const SizedBox(height: 16));
      children.add(Text(footer, style: const TextStyle(fontSize: 13, height: 1.45)));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _BulletParagraph extends StatelessWidget {
  const _BulletParagraph({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.wb_sunny, size: 18, color: Color(0xFFF9A825)),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.45))),
        ],
      ),
    );
  }
}

class _StrengthTable extends StatelessWidget {
  const _StrengthTable({required this.rows});

  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {0: FlexColumnWidth(0.4), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1.2)},
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            _Cell('வ.எண்', bold: true),
            _Cell('பட்சிகளின் தொழில்', bold: true),
            _Cell('பட்சிகளின் பலம்', bold: true),
          ],
        ),
        ...rows.asMap().entries.map((e) {
          final row = e.value as Map<String, dynamic>;
          return TableRow(
            children: [
              _Cell('${e.key + 1}.'),
              _Cell(row['activity_ta'] as String? ?? ''),
              _Cell(row['strength_ta'] as String? ?? ''),
            ],
          );
        }),
      ],
    );
  }
}

class _FriendTable extends StatelessWidget {
  const _FriendTable({required this.rows});

  final List<dynamic> rows;

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade100),
          children: const [
            _Cell('பட்சி', bold: true),
            _Cell('மித்துரு', bold: true),
            _Cell('சத்துரு', bold: true),
          ],
        ),
        ...rows.map((r) {
          final row = r as Map<String, dynamic>;
          return TableRow(
            children: [
              _Cell(row['bird_ta'] as String? ?? ''),
              _Cell(row['friend_ta'] as String? ?? ''),
              _Cell(row['enemy_ta'] as String? ?? ''),
            ],
          );
        }),
      ],
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.rows});

  final List<dynamic> rows;

  static const _headers = [
    '06.01-08.24',
    '08.25-10.48',
    '10.49-01.12',
    '01.13-03.36',
    '03.37-06.00',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.grey.shade300),
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade100),
            children: [
              const _Cell('கிழமை', bold: true),
              ..._headers.map((h) => _Cell(h, bold: true)),
            ],
          ),
          ...rows.map((r) {
            final row = r as Map<String, dynamic>;
            final slots = row['slots'] as List<dynamic>? ?? [];
            return TableRow(
              children: [
                _Cell(row['weekday_ta'] as String? ?? '', bold: true),
                ...List.generate(5, (i) {
                  if (i >= slots.length) return const _Cell('');
                  final slot = slots[i] as Map<String, dynamic>;
                  return _Cell(slot['activity_ta'] as String? ?? '');
                }),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.bold = false});

  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      ),
    );
  }
}
