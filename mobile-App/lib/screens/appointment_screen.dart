import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/nexus_theme.dart';
import '../widgets/shared_widgets.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<dynamic>   _slots       = [];
  bool            _loading     = true;
  String?         _selectedDate;
  String?         _selectedSlotId;
  String?         _selectedTime;
  Map<String, dynamic>? _selectedDoctor;
  bool            _booking     = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load({String? date}) async {
    setState(() => _loading = true);
    try {
      final data = await apiService.getAvailability(date: date);
      setState(() { _slots = data['availability'] ?? []; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _book() async {
    if (_selectedDoctor == null || _selectedTime == null) return;
    setState(() => _booking = true);
    try {
      await apiService.bookAppointment({
        'doctor_id':   _selectedDoctor!['doctor_id'],
        'doctor_name': _selectedDoctor!['doctor_name'],
        'date':        _selectedDoctor!['date'],
        'time':        _selectedTime,
      });
      if (mounted) {
        setState(() { _booking = false; _selectedSlotId = null; _selectedTime = null; _selectedDoctor = null; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Appointment confirmed!'), backgroundColor: Color(0xFF00897B)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: NexusTheme.emergency),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const NexusAppBar(title: 'Book Appointment'),
    body: Column(children: [
      // Date filter
      _buildDateBar(),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: NexusTheme.primary))
            : _slots.isEmpty
                ? const Center(child: Text('No available slots for this date', style: TextStyle(color: NexusTheme.textMed)))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _buildDoctorCard(_slots[i]),
                  ),
      ),

      // Book button
      if (_selectedTime != null)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          color: Colors.white,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Booking: ${_selectedDoctor?['doctor_name']} on ${_selectedDoctor?['date']} at $_selectedTime',
              style: const TextStyle(fontSize: 13, color: NexusTheme.textMed),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _booking ? null : _book,
                child: _booking
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Appointment'),
              ),
            ),
          ]),
        ),
    ]),
  );

  Widget _buildDateBar() {
    final dates = ['2026-03-18', '2026-03-19', '2026-03-20', '2026-03-21', '2026-03-22'];
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = dates[i];
          final parts = d.split('-');
          final isSelected = _selectedDate == d;
          return GestureDetector(
            onTap: () { setState(() => _selectedDate = d); _load(date: d); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? NexusTheme.primary : NexusTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? NexusTheme.primary : NexusTheme.divider),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(parts[2], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isSelected ? Colors.white : NexusTheme.textDark)),
                Text(_monthAbbr(int.parse(parts[1])), style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : NexusTheme.textMed)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> slot) {
    final isSelected  = _selectedSlotId == slot['slot_id'];
    final timeSlots   = (slot['time_slots'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? NexusTheme.primary.withOpacity(0.4) : NexusTheme.divider),
        boxShadow: isSelected ? [BoxShadow(color: NexusTheme.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: NexusTheme.primary.withOpacity(0.1),
            child: const Icon(Icons.person, color: NexusTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(slot['doctor_name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: NexusTheme.textDark)),
            Text(slot['specialization'] ?? '', style: const TextStyle(fontSize: 12, color: NexusTheme.primary)),
            Text('${timeSlots.length} slots on ${slot['date']}', style: const TextStyle(fontSize: 11, color: NexusTheme.textMed)),
          ])),
        ]),
        const SizedBox(height: 14),
        const Text('Available Times', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NexusTheme.textMed)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: timeSlots.map<Widget>((t) {
            final isTimeSelected = _selectedSlotId == slot['slot_id'] && _selectedTime == t;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedSlotId  = slot['slot_id'];
                _selectedTime    = t;
                _selectedDoctor  = slot;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isTimeSelected ? NexusTheme.primary : NexusTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isTimeSelected ? NexusTheme.primary : NexusTheme.divider),
                ),
                child: Text(t, style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: isTimeSelected ? Colors.white : NexusTheme.textDark,
                )),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }

  String _monthAbbr(int m) => ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];
}
