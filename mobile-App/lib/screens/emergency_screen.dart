import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../theme/nexus_theme.dart';
import '../widgets/shared_widgets.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Map<String, dynamic>? _profile;
  bool _loading    = true;
  bool _isPublic   = false;
  bool _toggling   = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getPublicEmergencyProfile('NEX000001');
      setState(() {
        _profile  = data['emergency_data'];
        _isPublic = true;
        _loading  = false;
      });
    } catch (_) {
      setState(() { _isPublic = false; _loading = false; });
    }
  }

  Future<void> _toggleVisibility() async {
    setState(() => _toggling = true);
    try {
      await apiService.updateEmergencyVisibility(!_isPublic);
      setState(() { _isPublic = !_isPublic; _toggling = false; });
      if (!_isPublic) _profile = null;
      else _load();
    } catch (_) { setState(() => _toggling = false); }
  }

  String get _qrData =>
      'nexuscare://emergency/NEX000001?token=pub_emergency_qr_token';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: NexusAppBar(
      title: 'Emergency QR Profile',
      actions: [
        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _showEditDialog),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: NexusTheme.emergency))
        : RefreshIndicator(
            onRefresh: _load, color: NexusTheme.emergency,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                // Visibility toggle card
                _buildVisibilityCard(),
                const SizedBox(height: 20),

                // QR Code
                if (_isPublic) ...[
                  _buildQrCard(),
                  const SizedBox(height: 20),
                ],

                // Emergency data
                if (_profile != null) _buildProfileData(),
              ]),
            ),
          ),
  );

  Widget _buildVisibilityCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: _isPublic
            ? [NexusTheme.emergency.withOpacity(0.85), NexusTheme.emergency]
            : [const Color(0xFF546E7A), const Color(0xFF37474F)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: (_isPublic ? NexusTheme.emergency : const Color(0xFF37474F)).withOpacity(0.3),
          blurRadius: 16, offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          _isPublic ? '🟢 Emergency QR Active' : '🔴 Emergency QR Disabled',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          _isPublic
              ? 'Any emergency responder can scan your QR to access critical information instantly.'
              : 'Enable to allow emergency responders to scan your QR for critical data.',
          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
        ),
      ])),
      const SizedBox(width: 16),
      _toggling
          ? const SizedBox(width: 48, height: 28, child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
          : Switch(
              value: _isPublic,
              onChanged: (_) => _toggleVisibility(),
              activeColor: Colors.white,
              activeTrackColor: Colors.white30,
            ),
    ]),
  );

  Widget _buildQrCard() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: NexusTheme.divider),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.qr_code_2, color: NexusTheme.emergency, size: 18),
        const SizedBox(width: 6),
        const Text('Patient Emergency QR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: NexusTheme.textDark)),
      ]),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NexusTheme.emergency.withOpacity(0.3), width: 2),
        ),
        child: QrImageView(
          data: _qrData,
          version: QrVersions.auto,
          size: 200,
          foregroundColor: NexusTheme.textDark,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
        ),
      ),
      const SizedBox(height: 14),
      const Text('ID: NEX000001', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NexusTheme.textMed)),
      const SizedBox(height: 6),
      const Text('Show this QR or keep it on your lock screen', style: TextStyle(fontSize: 12, color: NexusTheme.textLight)),
      const SizedBox(height: 14),
      OutlinedButton.icon(
        icon: const Icon(Icons.download, size: 16),
        label: const Text('Save to Device'),
        onPressed: () {},
        style: OutlinedButton.styleFrom(foregroundColor: NexusTheme.emergency,
            side: const BorderSide(color: NexusTheme.emergency)),
      ),
    ]),
  );

  Widget _buildProfileData() {
    final p = _profile!;
    final allergies    = (p['allergies']    as List? ?? []);
    final conditions   = (p['chronic_conditions'] as List? ?? []);
    final medications  = (p['current_medications'] as List? ?? []);
    final contacts     = (p['emergency_contacts']  as List? ?? []);

    return Column(children: [
      _section('Critical Information', Icons.priority_high, NexusTheme.emergency, [
        InfoRow(icon: Icons.water_drop, label: 'Blood Type', value: p['blood_type'] ?? 'Unknown', iconColor: NexusTheme.emergency),
        if ((p['critical_notes'] ?? '').isNotEmpty)
          InfoRow(icon: Icons.warning_amber, label: 'Critical Notes', value: p['critical_notes'], iconColor: NexusTheme.warning),
      ]),
      const SizedBox(height: 14),

      _section('Allergies', Icons.no_food, const Color(0xFFE65100), [
        if (allergies.isEmpty)
          const Text('No known allergies', style: TextStyle(color: NexusTheme.textMed, fontSize: 13))
        else
          Wrap(spacing: 8, runSpacing: 6, children: allergies.map<Widget>((a) => Chip(
            label: Text(a.toString()),
            backgroundColor: const Color(0xFFE65100).withOpacity(0.1),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
            side: const BorderSide(color: Color(0xFFE65100), width: 0.5),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          )).toList()),
      ]),
      const SizedBox(height: 14),

      _section('Chronic Conditions', Icons.health_and_safety, NexusTheme.warning, [
        if (conditions.isEmpty)
          const Text('None recorded', style: TextStyle(color: NexusTheme.textMed, fontSize: 13))
        else
          ...conditions.map<Widget>((c) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.circle, size: 6, color: NexusTheme.warning),
              const SizedBox(width: 8),
              Text(c.toString(), style: const TextStyle(fontSize: 13, color: NexusTheme.textDark)),
            ]),
          )),
      ]),
      const SizedBox(height: 14),

      _section('Current Medications', Icons.medication, NexusTheme.primary, [
        if (medications.isEmpty)
          const Text('None recorded', style: TextStyle(color: NexusTheme.textMed, fontSize: 13))
        else
          ...medications.map<Widget>((m) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              const Icon(Icons.medication, size: 14, color: NexusTheme.primary),
              const SizedBox(width: 8),
              Text(m.toString(), style: const TextStyle(fontSize: 13, color: NexusTheme.textDark)),
            ]),
          )),
      ]),
      const SizedBox(height: 14),

      _section('Emergency Contacts', Icons.contact_phone, NexusTheme.accent, [
        if (contacts.isEmpty)
          const Text('No contacts added', style: TextStyle(color: NexusTheme.textMed, fontSize: 13))
        else
          ...contacts.map<Widget>((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.person_outline, size: 16, color: NexusTheme.accent),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${c['relation']} · ${c['phone']}', style: const TextStyle(fontSize: 12, color: NexusTheme.textMed)),
              ])),
            ]),
          )),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: NexusTheme.divider),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
      const Divider(height: 16, color: NexusTheme.divider),
      ...children,
    ]),
  );

  void _showEditDialog() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Update Emergency Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        const Text('In the full implementation, this form allows you to update blood type, allergies, conditions, medications, and emergency contacts.', style: TextStyle(color: NexusTheme.textMed, height: 1.5)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NexusTheme.emergency),
            onPressed: () async {
              Navigator.pop(context);
              await apiService.updateEmergencyProfile({
                'blood_type': 'B+',
                'allergies': ['Penicillin', 'Sulfa drugs'],
                'chronic_conditions': ['Hypertension', 'Type 2 Diabetes'],
                'critical_notes': 'Patient is diabetic — check glucose levels in emergencies.',
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency profile updated ✓'), backgroundColor: Color(0xFF00897B)),
                );
              }
            },
            child: const Text('Save Emergency Profile'),
          ),
        ),
      ]),
    ),
  );
}
