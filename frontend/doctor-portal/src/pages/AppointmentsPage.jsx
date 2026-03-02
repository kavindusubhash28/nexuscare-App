import { useNavigate } from "react-router-dom";
import { useEffect, useState } from "react";
import { apiFetch } from "../api/client";

export default function AppointmentsPage() {
    const navigate = useNavigate();
    const [appointments, setAppointments] = useState([]);
    const [loading, setLoading] = useState(true);
    const [filter, setFilter] = useState("all");

    useEffect(() => {
        async function loadAppointments() {
            setLoading(true);
            try {
                const doctorId = localStorage.getItem("doctor_id") || "DOC001";
                const data = await apiFetch(`/api/doctors/${doctorId}/appointments?filter=${filter}`);
                setAppointments(data);
            } catch (err) {
                console.error("Failed to load appointments:", err);
            } finally {
                setLoading(false);
            }
        }
        loadAppointments();
    }, [filter]);

    return (
        <div style={{ padding: 40 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <h2>Doctor Appointments</h2>
                <button onClick={() => navigate("/doctor/dashboard")}>Back to Dashboard</button>
            </div>

            <div style={{ marginTop: 20, marginBottom: 20, display: "flex", gap: 10 }}>
                <button onClick={() => setFilter("all")} style={{ fontWeight: filter === "all" ? "bold" : "normal" }}>All</button>
                <button onClick={() => setFilter("today")} style={{ fontWeight: filter === "today" ? "bold" : "normal" }}>Today</button>
                <button onClick={() => setFilter("upcoming")} style={{ fontWeight: filter === "upcoming" ? "bold" : "normal" }}>Upcoming</button>
                <button onClick={() => setFilter("completed")} style={{ fontWeight: filter === "completed" ? "bold" : "normal" }}>Completed</button>
            </div>

            {loading ? (
                <p>Loading appointments...</p>
            ) : (
                <table style={{ width: "100%", borderCollapse: "collapse", marginTop: 10 }}>
                    <thead>
                        <tr style={{ textAlign: "left", borderBottom: "2px solid #ccc" }}>
                            <th style={{ padding: 12 }}>ID</th>
                            <th style={{ padding: 12 }}>Patient</th>
                            <th style={{ padding: 12 }}>Date</th>
                            <th style={{ padding: 12 }}>Time</th>
                            <th style={{ padding: 12 }}>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        {appointments.map((apt) => (
                            <tr key={apt.appointment_id} style={{ borderBottom: "1px solid #eee" }}>
                                <td style={{ padding: 12 }}>{apt.appointment_id}</td>
                                <td style={{ padding: 12 }}>{apt.patient_name}</td>
                                <td style={{ padding: 12 }}>{apt.date}</td>
                                <td style={{ padding: 12 }}>{apt.time}</td>
                                <td style={{ padding: 12 }}>
                                    <span style={{
                                        padding: "4px 8px",
                                        borderRadius: 4,
                                        backgroundColor: apt.status === "Conducted" ? "#dcfce7" : apt.status === "Waiting" ? "#fef9c3" : "#f3f4f6",
                                        fontSize: 12
                                    }}>
                                        {apt.status}
                                    </span>
                                </td>
                            </tr>
                        ))}
                        {appointments.length === 0 && (
                            <tr>
                                <td colSpan="5" style={{ padding: 20, textAlign: "center", color: "#666" }}>No appointments found.</td>
                            </tr>
                        )}
                    </tbody>
                </table>
            )}
        </div>
    );
}
