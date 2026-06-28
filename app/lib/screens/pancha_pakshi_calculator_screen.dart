import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pancha_pakshi.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

/// பஞ்ச பட்சி சாஸ்திரம் / கணக்கீடு
class PanchaPakshiCalculatorScreen extends StatefulWidget {
  const PanchaPakshiCalculatorScreen({
    super.key,
    required this.repository,
    required this.initialDate,
  });

  final CalendarRepository repository;
  final DateTime initialDate;

  @override
  State<PanchaPakshiCalculatorScreen> createState() => _PanchaPakshiCalculatorScreenState();
}

class _PanchaPakshiCalculatorScreenState extends State<PanchaPakshiCalculatorScreen> {
  static const _blue = Color(0xFF1565C0);
  static const _gold = Color(0xFFF9A825);

  List<PanchaPakshiNakshatra> _nakshatras = [];
  List<PanchaPakshiPakshaOption> _pakshaOptions = [];
  List<int> _years = [];

  PanchaPakshiNakshatra? _nakshatra;
  PanchaPakshiPakshaOption? _paksha;
  late DateTime _date;

  PanchaPakshiResult? _result;
  bool _loadingMeta = true;
  bool _calculating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    setState(() {
      _loadingMeta = true;
      _error = null;
    });
    try {
      final nakshatras = await widget.repository.getPanchaPakshiNakshatras();
      final paksha = await widget.repository.getPanchaPakshiPakshaOptions();
      final years = await widget.repository.getPanchaPakshiYears();
      if (!mounted) return;
      setState(() {
        _nakshatras = nakshatras;
        _pakshaOptions = paksha;
        _years = years;
        final magam = nakshatras.where((n) => n.nameTa == 'மகம்').toList();
        _nakshatra = magam.isNotEmpty ? magam.first : (nakshatras.isNotEmpty ? nakshatras.first : null);
        _paksha = paksha.firstWhere(
          (p) => p.id == 'valarpirai',
          orElse: () => paksha.first,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loadingMeta = false);
    }
  }

  Future<void> _pickDate() async {
    final minYear = _years.isNotEmpty ? _years.first : 2025;
    final maxYear = _years.isNotEmpty ? _years.last : 2027;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(minYear),
      lastDate: DateTime(maxYear, 12, 31),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _calculate() async {
    if (_nakshatra == null || _paksha == null) return;
    setState(() {
      _calculating = true;
      _error = null;
    });
    try {
      final result = await widget.repository.calculatePanchaPakshi(
        nakshatraIndex: _nakshatra!.index,
        birthPakshaId: _paksha!.id,
        date: _date,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        title: const Text('பஞ்ச பட்சி சாஸ்திரம் / கணக்கீடு', style: TextStyle(fontSize: 14)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMeta),
        ],
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.flutter_dash, size: 72, color: _gold.withValues(alpha: 0.9)),
                        const SizedBox(height: 8),
                        Text(
                          'வல்லூறு · ஆந்தை · காகம் · கோழி · மயில்',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'பஞ்ச பட்சி சாஸ்திரம் கணக்கிடுவதற்கு சரியான நட்சத்திரம் மற்றும் பிறையை நீங்கள் தேர்வு செய்தல் வேண்டும்',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('ஜென்ம நட்சத்திரம் :'),
                  _DropdownField<PanchaPakshiNakshatra>(
                    value: _nakshatra,
                    items: _nakshatras,
                    label: (n) => n.nameTa,
                    onChanged: (v) => setState(() => _nakshatra = v),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('பிறந்த பிறை :'),
                  _DropdownField<PanchaPakshiPakshaOption>(
                    value: _paksha,
                    items: _pakshaOptions,
                    label: (p) => p.labelTa,
                    onChanged: (v) => setState(() => _paksha = v),
                  ),
                  const SizedBox(height: 12),
                  _FieldLabel('தேதி :'),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('dd-MM-yyyy').format(_date),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 20, color: _blue),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'நீங்கள் பட்சி பார்க்க விரும்பும் தேதியைத் தேர்ந்தெடுக்கவும் (குறிப்பு: ${_years.first} முதல் ${_years.last} வரை மட்டுமே பட்சி பார்க்க முடியும்)',
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700, height: 1.35),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _calculating ? null : _calculate,
                      style: FilledButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _calculating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('கணக்கிடுக', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 24),
                    _ResultCard(result: _result!),
                  ],
                ],
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
  });

  final T? value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(label(e), style: const TextStyle(fontSize: 15))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final PanchaPakshiResult result;

  Color _activityColor(String activity) {
    switch (activity) {
      case 'அரசு':
        return const Color(0xFF2E7D32);
      case 'ஊண்':
        return const Color(0xFFF9A825);
      case 'நடை':
        return const Color(0xFF1565C0);
      case 'துயில்':
        return const Color(0xFF757575);
      default:
        return const Color(0xFFC62828);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'பஞ்ச பட்சி',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
            ),
          ),
          const SizedBox(height: 12),
          _InfoLine('ஜென்ம நட்சத்திரம்', result.nakshatraTa),
          _InfoLine('பிறந்த பிறை', result.birthPakshaTa),
          _InfoLine('பஞ்ச பட்சி', result.birdTa),
          _InfoLine('கிழமை', result.weekdayTa),
          const SizedBox(height: 8),
          Text(
            'அன்றைய பிறை: ${result.observationPakshaTa}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const Divider(height: 24),
          ...result.sections.map((section) => _SectionTable(section: section, colorFor: _activityColor)),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
          children: [
            TextSpan(text: '$label : ', style: TextStyle(color: Colors.red.shade700)),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SectionTable extends StatelessWidget {
  const _SectionTable({required this.section, required this.colorFor});

  final PanchaPakshiSection section;
  final Color Function(String) colorFor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.periodTa,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(1.1), 1: FlexColumnWidth(1)},
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: const [
                  Padding(padding: EdgeInsets.all(8), child: Text('நேரம்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Padding(padding: EdgeInsets.all(8), child: Text('பட்சிகளின் தொழில்', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              ...section.slots.map(
                (slot) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(slot.time, style: const TextStyle(fontSize: 12))),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        slot.activityTa,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorFor(slot.activityTa),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
