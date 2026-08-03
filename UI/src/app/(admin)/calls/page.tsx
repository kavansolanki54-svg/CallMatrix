"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Phone, PhoneIncoming, PhoneOutgoing, PhoneMissed, Play, Clock, Calendar } from "lucide-react";

export default function CallsPage() {
  const [calls, setCalls] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);

  const fetchCalls = async () => {
    setLoading(true);
    try {
      const res = await callService.getCalls(page, 10, search);
      if (res?.success && res.data) {
        setCalls(res.data.items || res.data);
      } else {
        setCalls([
          { callId: 1, phoneNumber: "+1 (555) 234-5678", agentName: "Alex Vance", type: "Incoming", duration: "04:15", timestamp: "2026-08-02 14:22", status: "Answered" },
          { callId: 2, phoneNumber: "+1 (555) 876-5432", agentName: "Sarah Connor", type: "Outgoing", duration: "01:45", timestamp: "2026-08-02 13:05", status: "Completed" },
          { callId: 3, phoneNumber: "+1 (555) 345-6789", agentName: "John Matrix", type: "Missed", duration: "00:00", timestamp: "2026-08-02 11:40", status: "Missed" },
        ]);
      }
    } catch (err) {
      console.error("Failed to fetch call telemetry", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCalls();
  }, [page, search]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Call Telemetry & Analytics</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">Monitor mobile agent calls, recordings, and call dispositions</p>
      </div>

      <div className="p-4 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search by agent or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-400 font-semibold uppercase text-xs">
              <tr>
                <th className="px-6 py-4">Type</th>
                <th className="px-6 py-4">Phone Number</th>
                <th className="px-6 py-4">Agent</th>
                <th className="px-6 py-4">Duration</th>
                <th className="px-6 py-4">Date & Time</th>
                <th className="px-6 py-4 text-right">Recording</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-400">Loading call logs...</td>
                </tr>
              ) : calls.map((call) => (
                <tr key={call.callId} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition">
                  <td className="px-6 py-4">
                    <span className="flex items-center gap-1.5 font-medium text-xs">
                      {call.type === "Incoming" ? <PhoneIncoming className="w-4 h-4 text-emerald-500" /> :
                       call.type === "Outgoing" ? <PhoneOutgoing className="w-4 h-4 text-blue-500" /> :
                       <PhoneMissed className="w-4 h-4 text-red-500" />}
                      {call.type}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-semibold text-gray-900 dark:text-white">{call.phoneNumber}</td>
                  <td className="px-6 py-4">{call.agentName}</td>
                  <td className="px-6 py-4 flex items-center gap-1"><Clock className="w-3.5 h-3.5 text-gray-400" /> {call.duration}</td>
                  <td className="px-6 py-4 text-gray-400 text-xs">{call.timestamp}</td>
                  <td className="px-6 py-4 text-right">
                    {call.duration !== "00:00" ? (
                      <button className="p-2 text-brand-600 dark:text-brand-400 bg-brand-50 dark:bg-brand-950/50 rounded-full hover:bg-brand-100 transition">
                        <Play className="w-3.5 h-3.5 fill-current" />
                      </button>
                    ) : (
                      <span className="text-xs text-gray-400">N/A</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
