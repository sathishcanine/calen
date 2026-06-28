import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/jyotish.dart';
import '../services/calendar_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/native_ad_widget.dart';

class NumerologyScreen extends StatefulWidget {
  const NumerologyScreen({super.key, required this.repository});

  final CalendarRepository repository;

  @override
  State<NumerologyScreen> createState() => _NumerologyScreenState();
}

class _NumerologyScreenState extends State<NumerologyScreen> {
  static const _red = Color(0xFFC62828);
  final _nameController = TextEditingController();
  DateTime _dob = DateTime(1990, 5, 15);
  NumerologyResult? _result;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _calculate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'பெயரை உள்ளிடவும்');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.repository.getNumerology(name: name, date: _dob);
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
        title: const Text('எண்கணிதம்', style: TextStyle(fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_red, Color(0xFFE53935)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.pin_rounded, color: Colors.white, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'பெயர் எண் மற்றும் பிறப்பு நட்சத்திர அடிப்படையில்',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'முழு பெயர் (ஆங்கில எழுத்துகள்)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dob,
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _dob = picked);
            },
            icon: const Icon(Icons.cake_outlined),
            label: Text('பிறந்த தேதி: ${DateFormat('dd-MM-yyyy').format(_dob)}'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _calculate,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.calculate_rounded),
            label: const Text('எண் கணக்கிடு'),
            style: FilledButton.styleFrom(backgroundColor: _red, padding: const EdgeInsets.symmetric(vertical: 14)),
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

  Widget _resultCard(NumerologyResult r) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _numberBubble('பெயர் எண்', r.nameNumber, _red),
                const SizedBox(width: 12),
                _numberBubble('விதி எண்', r.destinyNumber, const Color(0xFF6A1B9A)),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow('நட்சத்திரம்', r.birthNakshatraTa),
            _infoRow('ராசி', r.birthRashiTa),
            const Divider(height: 24),
            Text(r.interpretationTa, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 12),
            Text(r.summaryTa, style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45)),
          ],
        ),
      ),
    );
  }

  Widget _numberBubble(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
