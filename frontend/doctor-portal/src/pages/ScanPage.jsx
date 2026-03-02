import { useNavigate } from "react-router-dom";
import { useEffect, useRef, useState } from "react";
import { apiFetch } from "../api/client";

export default function ScanPage() {
  const navigate = useNavigate();
  const inputRef = useRef(null);

  const [value, setValue] = useState("");
  const [status, setStatus] = useState("Scan QR or type Patient ID (e.g., PT0001), then press Enter.");

  // Keep the input focused (useful for physical scanners)
  useEffect(() => {
    inputRef.current?.focus();
    const interval = setInterval(() => inputRef.current?.focus(), 800);
    return () => clearInterval(interval);
  }, []);

  async function lookupPatient(scannedValue) {
    const data = await apiFetch(`/api/doctor/patients/by-qr?qr=${encodeURIComponent(scannedValue)}`);

    // Support both response styles:
    // 1) { patient: { patient_id: "PT0001", ... }, emergency: {...} }
    // 2) { patient_id: "PT0001", ... }
    const patientId = data?.patient?.patient_id || data?.patient_id;

    if (!patientId) {
      throw new Error("Patient ID not found in response");
    }

    return { patientId, data };
  }

  async function handleKeyDown(e) {
    if (e.key !== "Enter") return;

    const scanned = value.trim();
    if (!scanned) return;

    setStatus("Searching patient...");
    setValue(""); // clear immediately so next scan can happen fast

    try {
      const { patientId, data } = await lookupPatient(scanned);

      setStatus("Patient found ✅ Redirecting...");
      // pass data if you want to avoid refetch on patient page
      navigate(`/doctor/patient/${patientId}`, { state: { data } });
    } catch (err) {
      setStatus(`❌ ${err.message}`);
    }
  }

  return (
    <div style={{ padding: 40, maxWidth: 720 }}>
      <h2>Doctor Portal</h2>
      <p style={{ marginTop: 8 }}>{status}</p>

      <label style={{ display: "block", marginTop: 16, marginBottom: 8 }}>
        Scan QR / Enter Patient ID
      </label>

      <input
        ref={inputRef}
        value={value}
        onChange={(e) => setValue(e.target.value)}
        onKeyDown={handleKeyDown}
        placeholder="Scan QR or type PT0001 and press Enter"
        style={{
          width: "100%",
          padding: 12,
          fontSize: 18,
          borderRadius: 8,
          border: "1px solid #ccc",
        }}
      />

      <div style={{ marginTop: 12, fontSize: 14, opacity: 0.8 }}>
        Tip: Click inside the input once, then scanning will work automatically.
      </div>
    </div>
  );
}