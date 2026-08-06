"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Play, Pause, Clock, Calendar, ShieldAlert, ArrowDownToLine, PhoneCall, Disc, PhoneIncoming, PhoneOutgoing, PhoneMissed } from "lucide-react";

export default function RecordingsPage() {
  const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5164/api";
  const baseUrl = apiBase.replace(/\/api\/?$/, "");

  const [calls, setCalls] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [activeRecordingUrl, setActiveRecordingUrl] = useState<string | null>(null);
  const [activeRecordingId, setActiveRecordingId] = useState<number | null>(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const audioRef = React.useRef<HTMLAudioElement>(null);
  const [selectedDate, setSelectedDate] = useState<string>(() => {
    const today = new Date();
    const y = today.getFullYear();
    const m = (today.getMonth() + 1).toString().padStart(2, "0");
    const d = today.getDate().toString().padStart(2, "0");
    return `${y}-${m}-${d}`;
  });

  const formatDuration = (secs: number) => {
    if (!secs) return "00:00";
    const m = Math.floor(secs / 60).toString().padStart(2, "0");
    const s = (secs % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  };

  const formatDate = (dateStr: string) => {
    if (!dateStr) return "";
    const d = new Date(dateStr.endsWith("Z") ? dateStr : dateStr + "Z");
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
      const res = await callService.getRecordings(page, 100, search, selectedDate);
      if (res?.success && res.data) {
        const items = res.data.items || res.data;
        setCalls(items);
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
  }, [page, search, selectedDate]);

  const handlePlayToggle = (url: string, recordingId: number) => {
    const fullUrl = url.startsWith("http") ? url : `${baseUrl}${url}`;
    
    if (activeRecordingId === recordingId) {
      if (isPlaying) {
        audioRef.current?.pause();
      } else {
        audioRef.current?.play();
      }
      setIsPlaying(!isPlaying);
    } else {
      setActiveRecordingUrl(fullUrl);
      setActiveRecordingId(recordingId);
      setIsPlaying(true);
    }
  };

  const groupRecordingsByPhone = (callList: any[]) => {
    const groups: Record<string, {
      phoneNumber: string;
      contactName?: string;
      employeeName?: string;
      employeeId: number;
      recordings: any[];
    }> = {};

    callList.forEach((call) => {
      const key = call.phoneNumber || "Unknown";
      if (!groups[key]) {
        groups[key] = {
          phoneNumber: key,
          contactName: call.contactName,
          employeeName: call.employeeName,
          employeeId: call.employeeId,
          recordings: [],
        };
      }
      groups[key].recordings.push(call);
    });

    return Object.values(groups);
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
          <p className="text-gray-400 dark:text-gray-500 text-sm font-medium">No recorded conversations found for this day</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {groupRecordingsByPhone(calls).map((group) => {
            return (
              <div 
                key={group.phoneNumber}
                className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col justify-between hover:border-brand-300 dark:hover:border-brand-800 hover:shadow-md transition-all duration-300"
              >
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-2">
                      <div className="w-10 h-10 rounded-full bg-brand-50 dark:bg-brand-950/40 text-brand-600 dark:text-brand-400 flex items-center justify-center font-bold text-sm">
                        {group.contactName ? group.contactName.charAt(0).toUpperCase() : "#"}
                      </div>
                      <div>
                        <h3 className="font-bold text-gray-900 dark:text-white text-base tracking-tight truncate max-w-[130px]">
                          {group.phoneNumber}
                        </h3>
                        {group.contactName && (
                          <p className="text-[10px] text-gray-400 dark:text-gray-500 font-medium truncate max-w-[130px]">{group.contactName}</p>
                        )}
                      </div>
                    </div>
                    <span className="inline-flex items-center px-2 py-0.5 bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 rounded-full text-[10px] font-bold">
                      {group.recordings.length} {group.recordings.length === 1 ? "call" : "calls"}
                    </span>
                  </div>
                  <p className="text-xs text-gray-400 font-medium mt-3">
                    Agent: <span className="text-gray-700 dark:text-gray-300 font-semibold">{group.employeeName || `Employee #${group.employeeId}`}</span>
                  </p>
                </div>

                <div className="border-t border-gray-50 dark:border-gray-800/80 pt-3 mt-4 space-y-2">
                  {group.recordings.map((rec) => {
                    const isCurrent = activeRecordingId === rec.callRecordingId;
                    const isThisPlaying = isCurrent && isPlaying;
                    const cType = rec.callType || "Incoming";
                    const recUrl = rec.fileUrl || rec.recordingUrl || "";
                    
                    const formatCallTime = (dateStr: string) => {
                      if (!dateStr) return "";
                      const d = new Date(dateStr.endsWith("Z") ? dateStr : dateStr + "Z");
                      if (isNaN(d.getTime())) return dateStr;
                      return d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit" });
                    };

                    return (
                      <div 
                        key={rec.callRecordingId}
                        className={`p-2 rounded-xl border flex items-center justify-between gap-3 transition ${
                          isCurrent 
                            ? "bg-brand-50/30 dark:bg-brand-950/10 border-brand-500/30" 
                            : "bg-gray-50/50 dark:bg-gray-800/30 border-transparent hover:border-gray-200 dark:hover:border-gray-700"
                        }`}
                      >
                        <div className="flex items-center gap-1.5">
                          <span className="p-1 rounded-lg">
                            {cType === "Incoming" ? <PhoneIncoming className="w-3.5 h-3.5 text-emerald-500" /> :
                             cType === "Outgoing" ? <PhoneOutgoing className="w-3.5 h-3.5 text-blue-500" /> :
                             <PhoneMissed className="w-3.5 h-3.5 text-red-500" />}
                          </span>
                          <div className="text-[11px]">
                            <div className="font-semibold text-gray-700 dark:text-gray-300">{formatCallTime(rec.callDateTime)}</div>
                            <div className="text-[9px] text-gray-400 flex items-center gap-1 mt-0.5">
                              <Clock className="w-2.5 h-2.5" />
                              {formatDuration(rec.duration)}
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-1.5">
                          <a
                            href={recUrl.startsWith("http") ? recUrl : `${baseUrl}${recUrl}`}
                            download
                            target="_blank"
                            rel="noopener noreferrer"
                            className="p-1 bg-white dark:bg-gray-800 text-gray-400 hover:text-gray-700 dark:hover:text-white rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 transition"
                            title="Download Recording"
                          >
                            <ArrowDownToLine className="w-3.5 h-3.5" />
                          </a>
                          <button
                            onClick={() => handlePlayToggle(recUrl, rec.callRecordingId)}
                            className={`p-1 rounded-lg transition shadow-sm border ${
                              isThisPlaying
                                ? "bg-indigo-600 border-indigo-600 text-white shadow-indigo-600/20"
                                : "bg-brand-500 border-brand-500 hover:bg-brand-600 text-white shadow-brand-500/20"
                            }`}
                          >
                            {isThisPlaying ? <Pause className="w-3 h-3 fill-current" /> : <Play className="w-3 h-3 fill-current" />}
                          </button>
                        </div>
                      </div>
                    );
                  })}
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
              disabled={calls.length < 100}
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
                setActiveRecordingId(null);
                setIsPlaying(false);
              }}
              className="p-1 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition"
            >
              <span className="text-sm font-bold">✕</span>
            </button>
          </div>
          <audio 
            ref={audioRef}
            key={activeRecordingUrl}
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
