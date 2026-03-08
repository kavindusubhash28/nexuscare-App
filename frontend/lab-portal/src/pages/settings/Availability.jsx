import { useEffect, useState } from "react";
import Card from "../../components/Card.jsx";
import Loading from "../../components/Loading.jsx";
import { api } from "../../services/api";
import { useLabGate } from "../../hooks/useLabGate";
import { useOutletContext } from "react-router-dom";

const DAYS = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"];

export default function Availability() {
  const { gate, message } = useLabGate();
  const { toast } = useOutletContext();

  const [schedule, setSchedule] = useState({});
  const [busy, setBusy] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (gate !== "active") return;
    let mounted = true;

    async function load() {
      setLoading(true);
      try {
        const res = await api.get("/api/lab/availability");
        if (!mounted) return;
        setSchedule(res.data?.schedule || {});
      } finally {
        if (mounted) setLoading(false);
      }
    }

    load();
    return () => (mounted = false);
  }, [gate]);

  function setDay(day, field, value) {
    setSchedule((prev) => ({
      ...prev,
      [day]: { ...(prev[day] || {}), [field]: value }
    }));
  }

  async function save() {
    setBusy(true);
    try {
      await api.put("/api/lab/availability", { schedule });
      toast.push("success", "Availability updated ✅");
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
        <div className="font-semibold">Availability</div>
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
          <div className="font-semibold text-gray-900">Lab Availability</div>
          <div className="text-sm text-gray-500">Set weekly schedule (saved as JSON in backend)</div>
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
          {DAYS.map((d) => (
            <div key={d} className="p-4 rounded-2xl border border-gray-200 bg-gray-50">
              <div className="font-semibold text-gray-900 uppercase">{d}</div>
              <div className="mt-3 grid grid-cols-2 gap-3">
                <input
                  className="px-3 py-2 rounded-xl border border-gray-200 bg-white"
                  placeholder="Open (e.g., 08:00)"
                  value={schedule?.[d]?.open || ""}
                  onChange={(e) => setDay(d, "open", e.target.value)}
                />
                <input
                  className="px-3 py-2 rounded-xl border border-gray-200 bg-white"
                  placeholder="Close (e.g., 17:00)"
                  value={schedule?.[d]?.close || ""}
                  onChange={(e) => setDay(d, "close", e.target.value)}
                />
              </div>
              <div className="mt-3">
                <textarea
                  className="w-full px-3 py-2 rounded-xl border border-gray-200 bg-white text-sm"
                  placeholder="Notes (optional)"
                  value={schedule?.[d]?.notes || ""}
                  onChange={(e) => setDay(d, "notes", e.target.value)}
                />
              </div>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}