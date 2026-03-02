import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import { apiFetch } from "../api/client";

export default function PatientPage() {
  const { id } = useParams();
  const [patient, setPatient] = useState(null);

  useEffect(() => {
    async function load() {
      try {
        const data = await apiFetch(`/api/doctor/patients/by-qr?qr=${id}`);
        setPatient(data.patient || data);
      } catch (err) {
        console.error("Failed to load patient:", err);
      }
    }
    load();
  }, [id]);

  if (!patient) return <div>Loading...</div>;

  return (
    <div style={{ padding: 40 }}>
      <h2>Patient Profile</h2>
      <p><strong>ID:</strong> {patient.patient_id}</p>
      <p><strong>Name:</strong> {patient.name}</p>
      <p><strong>NIC:</strong> {patient.nic}</p>
      <p><strong>Gender:</strong> {patient.gender}</p>
      <p><strong>DOB:</strong> {patient.date_of_birth}</p>
    </div>
  );
}