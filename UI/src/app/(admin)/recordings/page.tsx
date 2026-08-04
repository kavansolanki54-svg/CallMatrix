"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Play, Pause, Clock, Calendar, ShieldAlert, ArrowDownToLine, PhoneCall, Disc } from "lucide-react";

export default function RecordingsPage() {
  const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5164/api";
  const baseUrl = apiBase.replace(/\/api\/?$/, "");

  const [calls, setCalls] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [activeRecordingUrl, setActiveRecordingUrl] = useState<string | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);

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

  const fetchRecordings = async () => {
    setLoading(true);
    try {
      // Fetch larger page size to ensure we get plenty of recording items
      const res = await callService.getCalls(page, 10, search);
      if (res?.success && res.data) {
        const items = res.data.items || res.data;
        // Filter for items containing call recordings
        const withRecordings = items.filter((c: any) => c.hasRecording && c.recordingUrl);
        setCalls(withRecordings);
      } else {
        setCalls([]);
      }
    } catch (err) {
      console.error("Failed to fetch recording logs", err);
      setCalls([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRecordings();
  }, [page, search]);

  const handlePlayToggle = (url: string) => {
    const fullUrl = url.startsWith("http") ? url : `${baseUrl}${url}`;
    
    if (activeRecordingUrl === fullUrl) {
      setIsPlaying(!isPlaying);
    } else {
      setActiveRecordingUrl(fullUrl);
      setIsPlaying(true);
    }
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <Disc className="w-7 h-7 text-brand-600 animate-spin-slow" />
            Agent Call Recordings
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Stream, listen and download recorded agent conversations</p>
        </div>
      </div>

      {/* Filter and search */}
      <div className="p-4 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex items-center gap-4">
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

      {/* Grid List */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {[1, 2, 3].map((n) => (
            <div key={n} className="h-44 bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl animate-pulse p-5"></div>
          ))}
        </div>
      ) : calls.length === 0 ? (
        <div className="p-12 text-center bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col items-center justify-center">
          <Disc className="w-12 h-12 text-gray-300 dark:text-gray-700 mb-2" />
          <p className="text-gray-400 dark:text-gray-500 text-sm font-medium">No recorded conversations found</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {calls.map((call) => {
            const isCurrent = activeRecordingUrl?.includes(call.recordingUrl);
            const isThisPlaying = isCurrent && isPlaying;
            return (
              <div 
                key={call.callId} 
                className={`p-5 rounded-2xl bg-white dark:bg-gray-900 border transition-all duration-300 shadow-sm flex flex-col justify-between h-48 group ${
                  isCurrent 
                    ? "border-brand-500 ring-2 ring-brand-500/10" 
                    : "border-gray-100 dark:border-gray-800 hover:border-brand-300 dark:hover:border-brand-800 hover:shadow-md"
                }`}
              >
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-brand-50 dark:bg-brand-950/40 text-brand-600 dark:text-brand-400 rounded-lg text-xs font-semibold">
                      <PhoneCall className="w-3 h-3" />
                      {call.callType || "Call"}
                    </span>
                    <span className="text-xs text-gray-400 dark:text-gray-500 flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      {formatDuration(call.duration)}
                    </span>
                  </div>

                  <h3 className="font-bold text-gray-900 dark:text-white text-base tracking-tight truncate">
                    {call.phoneNumber}
                  </h3>
                  <p className="text-xs text-gray-400 mt-1 font-medium">
                    Agent: <span className="text-gray-700 dark:text-gray-300 font-semibold">{call.employeeName || `Employee #${call.employeeId}`}</span>
                  </p>
                </div>

                <div className="flex items-center justify-between border-t border-gray-50 dark:border-gray-800/80 pt-4 mt-2">
                  <div className="flex items-center gap-1 text-gray-400 text-[11px] font-medium">
                    <Calendar className="w-3 h-3" />
                    {formatDate(call.callDateTime)}
                  </div>
                  <div className="flex items-center gap-2">
                    <a
                      href={call.recordingUrl.startsWith("http") ? call.recordingUrl : `${baseUrl}${call.recordingUrl}`}
                      download
                      target="_blank"
                      rel="noopener noreferrer"
                      className="p-2 bg-gray-50 hover:bg-gray-100 dark:bg-gray-800 dark:hover:bg-gray-700/80 text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-white rounded-xl transition"
                      title="Download MP3"
                    >
                      <ArrowDownToLine className="w-4 h-4" />
                    </a>
                    <button
                      onClick={() => handlePlayToggle(call.recordingUrl)}
                      className={`p-3 rounded-xl transition shadow-lg ${
                        isThisPlaying
                          ? "bg-indigo-600 text-white shadow-indigo-600/20"
                          : "bg-brand-500 hover:bg-brand-600 text-white shadow-brand-500/20"
                      }`}
                    >
                      {isThisPlaying ? <Pause className="w-4 h-4 fill-current" /> : <Play className="w-4 h-4 fill-current" />}
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Pagination UI */}
      {!loading && calls.length > 0 && (
        <div className="flex items-center justify-between px-6 py-4 bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl shadow-sm">
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
              disabled={calls.length < 10}
              className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-semibold text-gray-600 dark:text-gray-400 disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
            >
              Next
            </button>
          </div>
        </div>
      )}

      {/* Floating Audio Player */}
      {activeRecordingUrl && (
        <div className="fixed bottom-6 right-6 left-6 md:left-auto md:w-96 bg-white dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-2xl shadow-2xl p-4 flex flex-col gap-3 z-50 animate-in fade-in slide-in-from-bottom-4 duration-300">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-indigo-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-indigo-500"></span>
              </span>
              <span className="text-xs font-semibold text-gray-900 dark:text-white">Streaming Audio Telemetry</span>
            </div>
            <button 
              onClick={() => {
                setActiveRecordingUrl(null);
                setIsPlaying(false);
              }}
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
            onPlay={() => setIsPlaying(true)}
            onPause={() => setIsPlaying(false)}
          />
        </div>
      )}
    </div>
  );
}
