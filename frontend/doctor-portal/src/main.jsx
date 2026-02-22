import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import ScanPage from "./pages/ScanPage";
import PatientPage from "./pages/PatientPage";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Navigate to="/doctor/scan" />} />
        <Route path="/doctor/scan" element={<ScanPage />} />
        <Route path="/doctor/patient/:id" element={<PatientPage />} />
      </Routes>
    </BrowserRouter>
  </React.StrictMode>
);