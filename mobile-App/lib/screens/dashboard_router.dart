import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'patient_dashboard.dart';
import 'doctor_dashboard.dart';
import 'admin_dashboard.dart';
import 'pharmacy_dashboard.dart';
import 'lab_dashboard.dart';

/// Routes to the correct dashboard based on the user's role.
class DashboardRouter extends StatelessWidget {
  const DashboardRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role ?? 'PATIENT';
    return switch (role) {
      'DOCTOR'   => const DoctorDashboard(),
      'ADMIN'    => const AdminDashboard(),
      'PHARMACY' => const PharmacyDashboard(),
      'LAB'      => const LabDashboard(),
      _          => const PatientDashboard(),
    };
  }
}

