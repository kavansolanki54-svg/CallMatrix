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

  const formatTime = (dateStr: string) => {
    if (!dateStr) return "";
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return dateStr;
    const hr = d.getHours().toString().padStart(2, "0");
    const min = d.getMinutes().toString().padStart(2, "0");
    return `${hr}:${min}`;
  };

  const groupCallsByDate = (callList: any[]) => {
    const groups: Record<string, any[]> = {};
    callList.forEach((call) => {
      if (!call.callDateTime) return;
      const dateKey = call.callDateTime.split("T")[0];
      if (!groups[dateKey]) {
        groups[dateKey] = [];
      }
      groups[dateKey].push(call);
    });
    return groups;
  };

  const formatGroupHeaderDate = (dateStr: string) => {
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) return dateStr;
    
    const today = new Date();
    const isToday = date.getDate() === today.getDate() &&
                    date.getMonth() === today.getMonth() &&
                    date.getFullYear() === today.getFullYear();
                    
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const isYesterday = date.getDate() === yesterday.getDate() &&
                        date.getMonth() === yesterday.getMonth() &&
                        date.getFullYear() === yesterday.getFullYear();

    const options: Intl.DateTimeFormatOptions = { weekday: "long", year: "numeric", month: "long", day: "numeric" };
    const formatted = date.toLocaleDateString("en-US", options);

    if (isToday) return `Today - ${formatted}`;
    if (isYesterday) return `Yesterday - ${formatted}`;
    return formatted;
  };

  const [selectedDate, setSelectedDate] = useState<string>(() => {
    const today = new Date();
    const y = today.getFullYear();
    const m = (today.getMonth() + 1).toString().padStart(2, "0");
    const d = today.getDate().toString().padStart(2, "0");
    return `${y}-${m}-${d}`;
  });
  const [callType, setCallType] = useState<string>("All");

  const fetchCalls = async () => {
    setLoading(true);
    try {
      const res = await callService.getCalls(page, 5, search, selectedDate || undefined, callType);
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
  }, [page, search, selectedDate, callType]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Call Telemetry & Analytics</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">Monitor mobile agent calls, recordings, and call dispositions</p>
      </div>

      <div className="p-4 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
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

        <div className="flex flex-wrap items-center gap-3">
          {/* Call Type Filter */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider">
              Type:
            </span>
            <select
              value={callType}
              onChange={(e) => {
                setCallType(e.target.value);
                setPage(1);
              }}
              className="px-3 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500 cursor-pointer"
            >
              <option value="All">All Types</option>
              <option value="Incoming">Incoming</option>
              <option value="Outgoing">Outgoing</option>
              <option value="Missed">Missed</option>
              <option value="Rejected">Rejected</option>
            </select>
          </div>

          <label className="flex items-center gap-2 cursor-pointer select-none">
            <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-brand-500" /> Date:
            </span>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => {
                setSelectedDate(e.target.value);
                setPage(1);
              }}
              onClick={(e) => {
                try {
                  e.currentTarget.showPicker();
                } catch (err) {}
              }}
              className="px-3 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500 cursor-pointer"
            />
          </label>
          {selectedDate && (
            <button
              onClick={() => {
                setSelectedDate("");
                setPage(1);
              }}
              className="px-2.5 py-2 text-xs font-semibold text-red-500 hover:text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-950/20 rounded-lg transition"
            >
              Clear
            </button>
          )}
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
                <th className="px-6 py-4">Time</th>
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
              ) : (
                Object.entries(groupCallsByDate(calls))
                  .sort(([a], [b]) => b.localeCompare(a))
                  .map(([dateKey, dateCalls]) => (
                    <React.Fragment key={dateKey}>
                      {/* Day Group Sub-Header */}
                      <tr className="bg-gray-50/50 dark:bg-gray-800/10 border-y border-gray-100 dark:border-gray-800/60">
                        <td colSpan={6} className="px-6 py-3 font-semibold text-xs text-brand-600 dark:text-brand-400 tracking-wider">
                          <div className="flex items-center gap-2">
                            <Calendar className="w-4 h-4 text-brand-500" />
                            {formatGroupHeaderDate(dateKey)}
                          </div>
                        </td>
                      </tr>
                      {/* Call Rows for this day */}
                      {dateCalls.map((call) => {
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
                            <td className="px-6 py-4 text-gray-400 text-xs font-mono">{formatTime(call.callDateTime)}</td>
                            <td className="px-6 py-4 text-right">
                              {call.hasRecording && call.recordingUrl ? (
                                <button
                                  onClick={() => {
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
                    </React.Fragment>
                  ))
              )}
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
