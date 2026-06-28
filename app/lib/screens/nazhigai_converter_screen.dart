import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jyotish.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

class NazhigaiConverterScreen extends StatefulWidget {
  const NazhigaiConverterScreen({super.key, required this.repository, this.initialDate});

  final CalendarRepository repository;
  final DateTime? initialDate;

  @override
  State<NazhigaiConverterScreen> createState() => _NazhigaiConverterScreenState();
}

class _NazhigaiConverterScreenState extends State<NazhigaiConverterScreen> {
  static const _amber = Color(0xFFF9A825);

  late DateTime _date;
  bool _toNazhigai = true;
  TimeOfDay _time = TimeOfDay.now();
  int _nazhigai = 1;
  int _vinadi = 0;

  NazhigaiResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
  }

  Future<void> _convert() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.convertNazhigai(
        date: _date,
        hour: _time.hour,
        minute: _time.minute,
        toNazhigai: _toNazhigai,
        nazhigai: _nazhigai,
        vinadi: _vinadi,
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
        title: const Text('நாழிகை மாற்றி', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_amber, Color(0xFFFFB300)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'சூரிய உதய/அஸ்தமன அடிப்படையில் நாழிகை கணக்கீடு',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('நேரம் → நாழிகை')),
              ButtonSegment(value: false, label: Text('நாழிகை → நேரம்')),
            ],
            selected: {_toNazhigai},
            onSelectionChanged: (s) => setState(() => _toNazhigai = s.first),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2025),
                lastDate: DateTime(2027, 12, 31),
              );
              if (picked != null) setState(() => _date = picked);
            },
            icon: const Icon(Icons.event),
            label: Text(DateFormat('dd MMM yyyy').format(_date)),
          ),
          const SizedBox(height: 12),
          if (_toNazhigai)
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(context: context, initialTime: _time);
                if (picked != null) setState(() => _time = picked);
              },
              icon: const Icon(Icons.schedule),
              label: Text('நேரம்: ${_time.format(context)}'),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: '$_nazhigai',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'நாழிகை (1-60)', border: OutlineInputBorder()),
                    onChanged: (v) => _nazhigai = int.tryParse(v) ?? 1,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: '$_vinadi',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'விநாடி', border: OutlineInputBorder()),
                    onChanged: (v) => _vinadi = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _convert,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.swap_horiz_rounded),
            label: const Text('மாற்று'),
            style: FilledButton.styleFrom(backgroundColor: _amber, foregroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 14)),
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

  Widget _resultCard(NazhigaiResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.displayTa, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _amber)),
            const SizedBox(height: 12),
            _row('பிரிவு', r.segmentTa),
            _row('சூரிய உதயம்', r.sunrise),
            _row('சூரிய அஸ்தமனம்', r.sunset),
            _row('பகல் நீளம்', r.dayDurationTa),
            _row('இரவு நீளம்', r.nightDurationTa),
            if (r.inputTime != null) _row('உள்ளீடு நேரம்', r.inputTime!),
            if (r.equivalentTime != null) _row('சமமான நேரம்', r.equivalentTime!),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
