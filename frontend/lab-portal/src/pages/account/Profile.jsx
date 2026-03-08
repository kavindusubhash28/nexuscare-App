import { useEffect, useState } from "react";
import Card from "../../components/Card.jsx";
import Loading from "../../components/Loading.jsx";
import { api } from "../../services/api";
import { useLabGate } from "../../hooks/useLabGate";
import { useOutletContext } from "react-router-dom";

export default function Profile() {
  const { gate, message } = useLabGate();
  const { toast } = useOutletContext();

  const [form, setForm] = useState({ lab_name: "", phone: "", address: "", reg_no: "" });
  const [loading, setLoading] = useState(false);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (gate !== "active") return;
    let mounted = true;

    async function load() {
      setLoading(true);
      try {
        const res = await api.get("/api/lab/profile");
        if (!mounted) return;
        setForm({
          lab_name: res.data?.lab_name || "",
          phone: res.data?.phone || "",
          address: res.data?.address || "",
          reg_no: res.data?.reg_no || ""
        });
      } finally {
        if (mounted) setLoading(false);
      }
    }

    load();
    return () => (mounted = false);
  }, [gate]);

  async function save() {
    setBusy(true);
    try {
      await api.put("/api/lab/profile", form);
      toast.push("success", "Profile updated ✅");
    } catch (e) {
      toast.push("error", e?.response?.data?.error || e?.message || "Save failed");
    } finally {
      setBusy(false);
    }
  }

  if (gate === "checking") return <Loading label="Checking access..." />;

  if (gate !== "active") {
    return (
      <Card className="p-6">
        <div className="font-semibold">My Profile</div>
        <div className="mt-2 text-sm text-gray-600">
          Locked: {message || "Waiting for admin approval."}
        </div>
      </Card>
    );
  }

  return (
    <Card className="p-6">
      <div className="flex items-center justify-between flex-wrap gap-4">
        <div>
          <div className="font-semibold text-gray-900">Lab Profile</div>
          <div className="text-sm text-gray-500">Update lab info</div>
        </div>
        <button
          onClick={save}
          disabled={busy}
          className="px-4 py-2 rounded-xl bg-teal-700 text-white font-semibold hover:bg-teal-800 disabled:opacity-60"
        >
          {busy ? "Saving..." : "Save"}
        </button>
      </div>

      {loading ? (
        <Loading />
      ) : (
        <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
          <Field
            label="Lab Name"
            value={form.lab_name}
            onChange={(v) => setForm((p) => ({ ...p, lab_name: v }))}
          />
          <Field
            label="Phone"
            value={form.phone}
            onChange={(v) => setForm((p) => ({ ...p, phone: v }))}
          />
          <Field
            label="Registration No"
            value={form.reg_no}
            onChange={(v) => setForm((p) => ({ ...p, reg_no: v }))}
          />
          <Field
            label="Address"
            value={form.address}
            onChange={(v) => setForm((p) => ({ ...p, address: v }))}
            textarea
          />
        </div>
      )}
    </Card>
  );
}

function Field({ label, value, onChange, textarea }) {
  return (
    <div>
      <div className="text-xs font-semibold text-gray-600">{label}</div>
      {textarea ? (
        <textarea
          className="mt-2 w-full px-4 py-3 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-teal-200"
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
      ) : (
        <input
          className="mt-2 w-full px-4 py-3 rounded-xl border border-gray-200 outline-none focus:ring-2 focus:ring-teal-200"
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
      )}
    </div>
  );
}