import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { apiFetch } from "../api/client";

export default function DoctorDashboard() {
  const navigate = useNavigate();
  const [stats, setStats] = useState({
    todayAppointments: 0,
    patientsSeenToday: 0,
    pendingLabs: 0,
    issuedPrescriptions: 0,
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function loadStats() {
      try {
        const doctorId = localStorage.getItem("doctor_id") || "DOC001"; // Fallback for now
        const data = await apiFetch(`/api/doctor/dashboard?doctor_id=${doctorId}`);
        setStats(data);
      } catch (err) {
        console.error("Failed to load dashboard stats:", err);
      } finally {
        setLoading(false);
      }
    }
    loadStats();
  }, []);

  function logout() {
    localStorage.removeItem("access_token");
    localStorage.removeItem("role");
    localStorage.removeItem("doctor_id");
    navigate("/doctor/login");
  }

  return (
    <div style={{ padding: 40 }}>
      <h2>Doctor Dashboard</h2>
      <p>Welcome to NexusCare Doctor Portal.</p>

      {loading ? (
        <p>Loading stats...</p>
      ) : (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))", gap: 20, marginTop: 20 }}>
          <div style={{ padding: 20, border: "1px solid #ccc", borderRadius: 8 }}>
            <h3>{stats.todayAppointments}</h3>
            <p>Today's Appointments</p>
          </div>
          <div style={{ padding: 20, border: "1px solid #ccc", borderRadius: 8 }}>
            <h3>{stats.patientsSeenToday}</h3>
            <p>Patients Seen Today</p>
          </div>
          <div style={{ padding: 20, border: "1px solid #ccc", borderRadius: 8 }}>
            <h3>{stats.pendingLabs}</h3>
            <p>Pending Labs</p>
          </div>
          <div style={{ padding: 20, border: "1px solid #ccc", borderRadius: 8 }}>
            <h3>{stats.issuedPrescriptions}</h3>
            <p>Issued Prescriptions</p>
          </div>
        </div>
      )}

      <div style={{ display: "flex", gap: 12, marginTop: 20 }}>
        <button onClick={() => navigate("/doctor/scan")}>Scan Patient</button>
        <button onClick={() => navigate("/doctor/appointments")}>Appointments</button>
        <button onClick={logout}>Logout</button>
      </div>
    </div>
  );
}