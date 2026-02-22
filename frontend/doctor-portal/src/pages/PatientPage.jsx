import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";

export default function PatientPage() {
  const { id } = useParams();
  const [patient, setPatient] = useState(null);

  useEffect(() => {
    async function load() {
      const res = await fetch(
        `http://localhost:5000/doctor/patients/by-qr?qr=${id}`
      );
      const data = await res.json();
      setPatient(data.patient || data);
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