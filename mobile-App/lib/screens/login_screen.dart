import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/nexus_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String _selectedRole = 'PATIENT';
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  static const _roles = [
    {'role': 'PATIENT',  'label': 'Patient',   'icon': Icons.person_outline,           'desc': 'View records, book appointments & manage health'},
    {'role': 'DOCTOR',   'label': 'Doctor',     'icon': Icons.medical_services_outlined, 'desc': 'Access patient data & manage consultations'},
    {'role': 'PHARMACY', 'label': 'Pharmacist', 'icon': Icons.local_pharmacy_outlined,  'desc': 'Manage prescriptions & medicine orders'},
    {'role': 'LAB',      'label': 'Lab Staff',  'icon': Icons.science_outlined,         'desc': 'Upload & manage diagnostic lab reports'},
    {'role': 'ADMIN',    'label': 'Admin',      'icon': Icons.admin_panel_settings_outlined, 'desc': 'System administration & user approvals'},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_selectedRole);
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: NexusTheme.emergency),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = NexusTheme.roleColor(_selectedRole);
    return Scaffold(
      backgroundColor: NexusTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Logo
                Row(children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: NexusTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('NexusCare', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: NexusTheme.textDark, letterSpacing: -0.5)),
                    Text('Smart Health Management', style: TextStyle(fontSize: 12, color: NexusTheme.textMed)),
                  ]),
                ]),

                const SizedBox(height: 40),
                const Text('Welcome back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: NexusTheme.textDark, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text('Select your role to continue', style: TextStyle(fontSize: 15, color: NexusTheme.textMed)),

                const SizedBox(height: 32),

                // Role cards
                ..._roles.map((r) {
                  final isSelected = _selectedRole == r['role'];
                  final rColor = NexusTheme.roleColor(r['role'] as String);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRole = r['role'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? rColor.withOpacity(0.07) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? rColor : NexusTheme.divider,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(color: rColor.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))
                        ] : [],
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? rColor.withOpacity(0.15) : NexusTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(r['icon'] as IconData, color: isSelected ? rColor : NexusTheme.textMed, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r['label'] as String,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                              color: isSelected ? rColor : NexusTheme.textDark)),
                          Text(r['desc'] as String,
                            style: const TextStyle(fontSize: 12, color: NexusTheme.textMed), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: rColor, size: 22),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 28),

                // Login button
                Consumer<AuthProvider>(
                  builder: (_, auth, __) => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                      child: auth.isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text('Sign In as ${_roles.firstWhere((r) => r['role'] == _selectedRole)['label']}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                // Emergency QR shortcut
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NexusTheme.emergency.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NexusTheme.emergency.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: NexusTheme.emergency.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.qr_code_scanner, color: NexusTheme.emergency, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Emergency QR Scan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: NexusTheme.emergency)),
                      Text('Scan a patient QR for emergency data access', style: TextStyle(fontSize: 11, color: NexusTheme.textMed)),
                    ])),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/emergency-scan'),
                      child: const Text('Open', style: TextStyle(fontSize: 12, color: NexusTheme.emergency, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),

                const SizedBox(height: 24),
                Center(
                  child: Text('NexusCare v1.0 · Informatics Institute of Technology',
                    style: const TextStyle(fontSize: 11, color: NexusTheme.textLight)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
