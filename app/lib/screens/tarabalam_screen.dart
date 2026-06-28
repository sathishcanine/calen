import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jyotish.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

class TarabalamScreen extends StatefulWidget {
  const TarabalamScreen({super.key, required this.repository, this.initialDate});

  final CalendarRepository repository;
  final DateTime? initialDate;

  @override
  State<TarabalamScreen> createState() => _TarabalamScreenState();
}

class _TarabalamScreenState extends State<TarabalamScreen> {
  static const _purple = Color(0xFF6A1B9A);

  List<JyotishNakshatra> _nakshatras = [];
  JyotishNakshatra? _birthNakshatra;
  late DateTime _date;

  TarabalamResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    try {
      final nakshatras = await widget.repository.getJyotishNakshatras();
      if (!mounted) return;
      setState(() {
        _nakshatras = nakshatras;
        _birthNakshatra = nakshatras.isNotEmpty ? nakshatras.first : null;
      });
      _calculate();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _calculate() async {
    if (_birthNakshatra == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getTarabalam(
        birthNakshatraIndex: _birthNakshatra!.index,
        date: _date,
      );
      if (mounted) setState(() => _result = result);
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
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        title: const Text('தாரா பலன்கள்', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_purple, Color(0xFF8E24AA)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.stars_rounded, color: Colors.white, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'தாரா பலம் — உங்கள் நட்சத்திரத்திற்கு ஏற்ற காலம்',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_birthNakshatra != null)
            DropdownButtonFormField<JyotishNakshatra>(
              value: _birthNakshatra,
              decoration: const InputDecoration(labelText: 'பிறந்த நட்சத்திரம்', border: OutlineInputBorder()),
              items: _nakshatras.map((n) => DropdownMenuItem(value: n, child: Text(n.nameTa))).toList(),
              onChanged: (v) {
                setState(() => _birthNakshatra = v);
                _calculate();
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2025),
                lastDate: DateTime(2027, 12, 31),
              );
              if (picked != null) {
                setState(() => _date = picked);
                _calculate();
              }
            },
            icon: const Icon(Icons.event),
            label: Text(DateFormat('dd MMM yyyy').format(_date)),
          ),
          if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          if (_result != null) ...[const SizedBox(height: 16), _resultCard(_result!)],
        ],
      ),
    );
  }

  Widget _resultCard(TarabalamResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('நட்சத்திரம்: ${r.birthNakshatraTa}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(r.noteTa, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const Divider(height: 24),
            const Text('சாதக தாரா காலங்கள்', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.auspicious)),
            const SizedBox(height: 8),
            if (r.favorablePeriods.isEmpty)
              const Text('இன்று சாதக தாரா காலம் இல்லை')
            else
              ...r.favorablePeriods.map(
                (p) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.check_circle, color: AppColors.auspicious),
                  title: Text(p.transitNakshatraTa),
                  subtitle: Text('${p.timeRange}${p.taraNameTa.isNotEmpty ? ' · ${p.taraNameTa}' : ''}'),
                ),
              ),
            const Divider(height: 24),
            const Text('பாதக காலங்கள்', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.inauspicious)),
            const SizedBox(height: 8),
            ...r.unfavorablePeriods.take(6).map(
                  (p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.remove_circle_outline, color: AppColors.inauspicious),
                    title: Text(p.transitNakshatraTa),
                    subtitle: Text(p.timeRange),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
