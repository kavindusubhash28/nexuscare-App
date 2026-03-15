import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/nexus_theme.dart';
import '../widgets/shared_widgets.dart';

class LabReportsScreen extends StatefulWidget {
  const LabReportsScreen({super.key});
  @override
  State<LabReportsScreen> createState() => _LabReportsScreenState();
}

class _LabReportsScreenState extends State<LabReportsScreen> {
  List<dynamic> _reports = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getLabReports();
      setState(() { _reports = data['lab_reports'] ?? []; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: NexusAppBar(title: 'Lab Reports', actions: [
      IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
    ]),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: NexusTheme.primary))
        : _reports.isEmpty
            ? const Center(child: Text('No lab reports found', style: TextStyle(color: NexusTheme.textMed)))
            : RefreshIndicator(
                onRefresh: _load, color: NexusTheme.primary,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _LabReportCard(report: _reports[i]),
                ),
              ),
  );
}

class _LabReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  const _LabReportCard({required this.report});
  @override
  State<_LabReportCard> createState() => _LabReportCardState();
}

class _LabReportCardState extends State<_LabReportCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r       = widget.report;
    final results = r['results'] as Map<String, dynamic>? ?? {};
    final isPending = (r['status'] ?? '') == 'PENDING';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _expanded ? const Color(0xFFE65100).withOpacity(0.4) : NexusTheme.divider),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science, color: Color(0xFFE65100), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r['test_name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: NexusTheme.textDark)),
              Text(r['lab_name'] ?? '', style: const TextStyle(fontSize: 12, color: NexusTheme.textMed)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(status: r['status'] ?? ''),
              const SizedBox(height: 4),
              Text(r['date'] ?? '', style: const TextStyle(fontSize: 11, color: NexusTheme.textLight)),
            ]),
          ]),

          if (_expanded && !isPending) ...[
            const Divider(height: 20, color: NexusTheme.divider),
            InfoRow(icon: Icons.person_outline, label: 'Ordered by', value: r['ordered_by'] ?? ''),
            const SizedBox(height: 12),
            const Text('Results', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NexusTheme.textDark)),
            const SizedBox(height: 8),
            ...results.entries.map<Widget>((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Expanded(child: Text(e.key, style: const TextStyle(fontSize: 13, color: NexusTheme.textMed))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: NexusTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(e.value.toString(),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NexusTheme.accentDark)),
                ),
              ]),
            )),
            if (r['file_url'] != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf, size: 16),
                  label: const Text('View Full Report PDF'),
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE65100)),
                ),
              ),
            ],
          ],

          if (_expanded && isPending) ...[
            const Divider(height: 20, color: NexusTheme.divider),
            const Row(children: [
              Icon(Icons.hourglass_top, color: NexusTheme.warning, size: 16),
              SizedBox(width: 8),
              Text('Results are being processed by the lab', style: TextStyle(color: NexusTheme.textMed, fontSize: 13)),
            ]),
          ],

          if (!isPending && !_expanded) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.keyboard_arrow_down, size: 16, color: NexusTheme.textLight),
              const SizedBox(width: 4),
              Text('${results.length} result${results.length != 1 ? 's' : ''} — tap to expand',
                  style: const TextStyle(fontSize: 12, color: NexusTheme.textLight)),
            ]),
          ],
        ]),
      ),
    );
  }
}
