import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jyotish.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

class ChandrashtamamScreen extends StatefulWidget {
  const ChandrashtamamScreen({super.key, required this.repository, this.initialDate});

  final CalendarRepository repository;
  final DateTime? initialDate;

  @override
  State<ChandrashtamamScreen> createState() => _ChandrashtamamScreenState();
}

class _ChandrashtamamScreenState extends State<ChandrashtamamScreen> {
  static const _blue = Color(0xFF1565C0);

  List<JyotishRashi> _rashis = [];
  JyotishRashi? _birthRashi;
  late DateTime _date;

  ChandrashtamamResult? _result;
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
      final rashis = await widget.repository.getJyotishRashis();
      if (!mounted) return;
      setState(() {
        _rashis = rashis;
        _birthRashi = rashis.isNotEmpty ? rashis[3] : null;
      });
      _calculate();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _calculate() async {
    if (_birthRashi == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getChandrashtamam(
        birthRashiIndex: _birthRashi!.index,
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
        title: const Text('சந்திராஷ்டமம்', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_blue, Color(0xFF1976D2)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.nightlight_round, color: Colors.white, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'சந்திர பாலம் — 8-ம் ராசியில் சந்திரன்',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_birthRashi != null)
            DropdownButtonFormField<JyotishRashi>(
              value: _birthRashi,
              decoration: const InputDecoration(labelText: 'பிறந்த சந்திர ராசி', border: OutlineInputBorder()),
              items: _rashis.map((r) => DropdownMenuItem(value: r, child: Text(r.nameTa))).toList(),
              onChanged: (v) {
                setState(() => _birthRashi = v);
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

  Widget _resultCard(ChandrashtamamResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r.isActiveNow)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: const Text(
                  '⚠️ இப்போது சந்திராஷ்டமம் நேரம்',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ),
            Text('பிறந்த ராசி: ${r.birthRashiTa}', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('சந்திராஷ்டம ராசி: ${r.chandrashtamamRashiTa}'),
            const SizedBox(height: 8),
            Text(r.noteTa, style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const Divider(height: 24),
            const Text('இன்றைய சந்திர பயணம்', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...r.periods.map(
              (p) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  p.isChandrashtamam ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: p.isChandrashtamam ? Colors.redAccent : _blue,
                ),
                title: Text(p.rashiTa, style: TextStyle(fontWeight: p.isChandrashtamam ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(p.timeRange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
