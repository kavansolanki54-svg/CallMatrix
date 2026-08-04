"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Phone, PhoneIncoming, PhoneOutgoing, PhoneMissed, Play, Clock, Calendar } from "lucide-react";

export default function CallsPage() {
  const [calls, setCalls] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [activeRecordingUrl, setActiveRecordingUrl] = useState<string | null>(null);

  const formatDuration = (secs: number) => {
    if (!secs) return "00:00";
    const m = Math.floor(secs / 60).toString().padStart(2, "0");
    const s = (secs % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return "";
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const y = d.getFullYear();
    const m = (d.getMonth() + 1).toString().padStart(2, "0");
    const day = d.getDate().toString().padStart(2, "0");
    const hr = d.getHours().toString().padStart(2, "0");
    const min = d.getMinutes().toString().padStart(2, "0");
    return `${y}-${m}-${day} ${hr}:${min}`;
  };

  const fetchCalls = async () => {
    setLoading(true);
    try {
      const res = await callService.getCalls(page, 5, search);
      if (res?.success && res.data) {
        setCalls(res.data.items || res.data);
      } else {
        setCalls([]);
      }
    } catch (err) {
      console.error("Failed to fetch call telemetry", err);
      setCalls([]);
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
              ) : calls.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-8 text-center text-gray-400">No call logs found</td>
                </tr>
              ) : calls.map((call) => {
                const cType = call.callType || "Incoming";
                return (
                  <tr key={call.callId} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition">
                    <td className="px-6 py-4">
                      <span className="flex items-center gap-1.5 font-medium text-xs">
                        {cType === "Incoming" ? <PhoneIncoming className="w-4 h-4 text-emerald-500" /> :
                         cType === "Outgoing" ? <PhoneOutgoing className="w-4 h-4 text-blue-500" /> :
                         <PhoneMissed className="w-4 h-4 text-red-500" />}
                        {cType}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-semibold text-gray-900 dark:text-white">{call.phoneNumber}</div>
                      {call.contactName && (
                        <div className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{call.contactName}</div>
                      )}
                    </td>
                    <td className="px-6 py-4">{call.employeeName || `Employee #${call.employeeId}`}</td>
                    <td className="px-6 py-4 flex items-center gap-1">
                      <Clock className="w-3.5 h-3.5 text-gray-400" /> {formatDuration(call.duration)}
                    </td>
                    <td className="px-6 py-4 text-gray-400 text-xs">{formatDate(call.callDateTime)}</td>
                    <td className="px-6 py-4 text-right">
                      {call.hasRecording && call.recordingUrl ? (
                        <button
                            const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5164/api";
                            const baseUrl = apiBase.replace(/\/api\/?$/, "");
                            const fullUrl = call.recordingUrl.startsWith("http") 
                              ? call.recordingUrl 
                              : `${baseUrl}${call.recordingUrl}`;
                            setActiveRecordingUrl(fullUrl);
                          }}
                          className="inline-block p-2 text-brand-600 dark:text-brand-400 bg-brand-50 dark:bg-brand-950/50 rounded-full hover:bg-brand-100 transition"
                        >
                          <Play className="w-3.5 h-3.5 fill-current" />
                        </button>
                      ) : (
                        <span className="text-xs text-gray-400">N/A</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Pagination UI */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray-100 dark:border-gray-800">
          <div className="text-xs text-gray-500">
            Showing Page <span className="font-semibold text-gray-700 dark:text-gray-300">{page}</span>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage((p) => Math.max(p - 1, 1))}
              disabled={page === 1}
              className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-semibold text-gray-600 dark:text-gray-400 disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
            >
              Previous
            </button>
            <button
              onClick={() => setPage((p) => p + 1)}
              disabled={calls.length < 5}
              className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-semibold text-gray-600 dark:text-gray-400 disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Floating Recording Player */}
      {activeRecordingUrl && (
        <div className="fixed bottom-6 right-6 left-6 md:left-auto md:w-96 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl shadow-2xl p-4 flex flex-col gap-3 z-50 animate-in fade-in slide-in-from-bottom-4 duration-300">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-indigo-500"></span>
              </span>
              <span className="text-xs font-semibold text-gray-900 dark:text-white">Playing Call Recording</span>
            </div>
            <button 
              onClick={() => setActiveRecordingUrl(null)}
              className="p-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition"
            >
              <span className="text-sm font-bold">✕</span>
            </button>
          </div>
          <audio 
            src={activeRecordingUrl} 
            controls 
            autoPlay 
            className="w-full focus:outline-none"
          />
        </div>
      )}
    </div>
  );
}
