import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jyotish.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

class MarriagePoruthamScreen extends StatefulWidget {
  const MarriagePoruthamScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<MarriagePoruthamScreen> createState() => _MarriagePoruthamScreenState();
}

class _MarriagePoruthamScreenState extends State<MarriagePoruthamScreen> {
  static const _green = Color(0xFF2E8B57);

  List<JyotishNakshatra> _nakshatras = [];
  DateTime _p1Date = DateTime(1990, 1, 1);
  TimeOfDay _p1Time = const TimeOfDay(hour: 10, minute: 0);
  JyotishNakshatra? _p1Nakshatra;
  DateTime _p2Date = DateTime(1992, 6, 15);
  TimeOfDay _p2Time = const TimeOfDay(hour: 16, minute: 30);
  JyotishNakshatra? _p2Nakshatra;
  bool _useManualNakshatra = false;

  MarriagePoruthamResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final nakshatras = await widget.repository.getJyotishNakshatras();
      if (!mounted) return;
      setState(() {
        _nakshatras = nakshatras;
        _p1Nakshatra = nakshatras.isNotEmpty ? nakshatras.first : null;
        _p2Nakshatra = nakshatras.length > 10 ? nakshatras[10] : nakshatras.last;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _calculate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getMarriagePorutham(
        person1Date: _p1Date,
        person1Hour: _p1Time.hour,
        person1Minute: _p1Time.minute,
        person1Nakshatra: _useManualNakshatra ? _p1Nakshatra?.index : null,
        person2Date: _p2Date,
        person2Hour: _p2Time.hour,
        person2Minute: _p2Time.minute,
        person2Nakshatra: _useManualNakshatra ? _p2Nakshatra?.index : null,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool person1) async {
    final initial = person1 ? _p1Date : _p2Date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (person1) {
          _p1Date = picked;
        } else {
          _p2Date = picked;
        }
      });
    }
  }

  Future<void> _pickTime(bool person1) async {
    final initial = person1 ? _p1Time : _p2Time;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (person1) {
          _p1Time = picked;
        } else {
          _p2Time = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const NativeAdWidget(),
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('திருமண பொருத்தம்', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(),
          const SizedBox(height: 16),
          _personCard('ஆண் / மணமகன்', _p1Date, _p1Time, _p1Nakshatra, true),
          const SizedBox(height: 12),
          _personCard('பெண் / மணமகள்', _p2Date, _p2Time, _p2Nakshatra, false),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('நட்சத்திரத்தை கைமுறையாக தேர்வு செய்'),
            value: _useManualNakshatra,
            activeColor: _green,
            onChanged: (v) => setState(() => _useManualNakshatra = v),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _loading ? null : _calculate,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.favorite_rounded),
            label: const Text('பொருத்தம் பார்'),
            style: FilledButton.styleFrom(backgroundColor: _green, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_result != null) ...[const SizedBox(height: 20), _resultCard(_result!)],
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_green, Color(0xFF43A047)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'நட்சத்திர அடிப்படையில் 10 பொருத்தங்கள்',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _personCard(String title, DateTime date, TimeOfDay time, JyotishNakshatra? nakshatra, bool isP1) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _green)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isP1),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('dd-MM-yyyy').format(date)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _pickTime(isP1),
                  child: Text(time.format(context)),
                ),
              ],
            ),
            if (_useManualNakshatra && nakshatra != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<JyotishNakshatra>(
                value: nakshatra,
                decoration: const InputDecoration(labelText: 'நட்சத்திரம்', border: OutlineInputBorder()),
                items: _nakshatras
                    .map((n) => DropdownMenuItem(value: n, child: Text(n.nameTa)))
                    .toList(),
                onChanged: (v) => setState(() {
                  if (isP1) {
                    _p1Nakshatra = v;
                  } else {
                    _p2Nakshatra = v;
                  }
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultCard(MarriagePoruthamResult result) {
    final pct = result.maxScore == 0 ? 0.0 : result.totalScore / result.maxScore;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.totalScore} / ${result.maxScore} பொருத்தம்',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _green),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: pct, minHeight: 8, borderRadius: BorderRadius.circular(8), color: _green),
            const SizedBox(height: 12),
            Text('${result.person1NakshatraTa} (${result.person1RashiTa}) × ${result.person2NakshatraTa} (${result.person2RashiTa})'),
            const SizedBox(height: 8),
            Text(result.verdictTa, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Divider(height: 24),
            ...result.factors.map(
              (f) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  f.matched ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: f.matched ? _green : Colors.redAccent,
                ),
                title: Text(f.nameTa),
                subtitle: Text(f.noteTa, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
