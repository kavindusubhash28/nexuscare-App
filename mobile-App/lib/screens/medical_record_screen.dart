import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/nexus_theme.dart';
import '../widgets/shared_widgets.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});
  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  List<dynamic> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await apiService.getMedicalRecords();
      setState(() { _records = data['medical_records'] ?? []; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: NexusAppBar(
      title: 'Medical Records',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: NexusTheme.primary))
        : _error != null
            ? _buildError()
            : _records.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
                    onRefresh: _load, color: NexusTheme.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _RecordCard(record: _records[i]),
                    ),
                  ),
  );

  Widget _buildError() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 48, color: NexusTheme.emergency),
    const SizedBox(height: 12),
    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: NexusTheme.textMed)),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load, child: const Text('Retry')),
  ]));

  Widget _buildEmpty() => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.folder_open, size: 64, color: NexusTheme.textLight),
    SizedBox(height: 16),
    Text('No medical records found', style: TextStyle(color: NexusTheme.textMed, fontSize: 16, fontWeight: FontWeight.w600)),
    SizedBox(height: 6),
    Text('Your doctor visits will appear here', style: TextStyle(color: NexusTheme.textLight)),
  ]));
}

class _RecordCard extends StatefulWidget {
  final Map<String, dynamic> record;
  const _RecordCard({required this.record});
  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _expanded ? NexusTheme.primary.withOpacity(0.4) : NexusTheme.divider),
          boxShadow: _expanded ? [BoxShadow(color: NexusTheme.primary.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: NexusTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.medical_information, color: NexusTheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['diagnosis'] ?? 'Unknown', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: NexusTheme.textDark)),
              Text(r['doctor_name'] ?? '', style: const TextStyle(fontSize: 12, color: NexusTheme.textMed)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(r['date'] ?? '', style: const TextStyle(fontSize: 11, color: NexusTheme.textLight)),
              const SizedBox(height: 4),
              Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: NexusTheme.textLight, size: 18),
            ]),
          ]),

          if (_expanded) ...[
            const Divider(height: 20, color: NexusTheme.divider),
            InfoRow(icon: Icons.local_hospital_outlined, label: 'Hospital / Clinic', value: r['hospital'] ?? 'N/A'),
            const Divider(height: 12, color: NexusTheme.divider),
            const Text('Doctor\'s Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NexusTheme.textMed)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: NexusTheme.surface, borderRadius: BorderRadius.circular(10)),
              child: Text(r['notes'] ?? '', style: const TextStyle(fontSize: 13, color: NexusTheme.textDark, height: 1.5)),
            ),
          ],
        ]),
      ),
    );
  }
}
