"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Play, Pause, Clock, Calendar, ShieldAlert, ArrowDownToLine, PhoneCall, Disc, PhoneIncoming, PhoneOutgoing, PhoneMissed, Sparkles, CheckSquare, MessageSquare, Lightbulb, Tag } from "lucide-react";
import { Modal } from "@/components/ui/modal";

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

  const [summaryOpen, setSummaryOpen] = useState(false);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryError, setSummaryError] = useState<string | null>(null);
  const [summaryText, setSummaryText] = useState<string | null>(null);

  const handleShowSummary = async (recordingId: number) => {
    setSummaryOpen(true);
    setSummaryLoading(true);
    setSummaryError(null);
    setSummaryText(null);
    try {
      const res = await callService.getRecordingSummary(recordingId);
      if (res && (res.success || res.isSuccess)) {
        setSummaryText(res.data);
      } else {
        setSummaryError(res.message || "Failed to generate AI summary.");
      }
    } catch (err: any) {
      const errMsg = err.response?.data?.message || err.message || "An error occurred.";
      setSummaryError(errMsg);
    } finally {
      setSummaryLoading(false);
    }
  };

  const parsedSummary = summaryText ? (() => {
    let summary = "";
    let points: string[] = [];
    let actions: string[] = [];
    let sentiment = "Neutral";
    let keywords: string[] = [];
    let followUps: string[] = [];

    const lines = summaryText.split("\n");
    let currentSection: "summary" | "points" | "actions" | "keywords" | "followups" | null = "summary";

    for (let line of lines) {
      const l = line.trim();
      if (!l) continue;

      // Extract sentiment from anywhere
      if (l.toLowerCase().includes("sentiment:")) {
        if (l.toLowerCase().includes("positive")) sentiment = "Positive";
        else if (l.toLowerCase().includes("negative")) sentiment = "Negative";
        else sentiment = "Neutral";
        continue;
      }

      // Check section transitions
      if (l.toLowerCase().includes("key discussion") || l.toLowerCase().includes("discussion points") || l.toLowerCase().includes("key points")) {
        currentSection = "points";
        continue;
      } else if (l.toLowerCase().includes("action items") || l.toLowerCase().includes("to-do") || l.toLowerCase().includes("actionable")) {
        currentSection = "actions";
        continue;
      } else if (l.toLowerCase().includes("keywords") || l.toLowerCase().includes("tags")) {
        currentSection = "keywords";
        continue;
      } else if (l.toLowerCase().includes("follow-up") || l.toLowerCase().includes("suggestions")) {
        currentSection = "followups";
        continue;
      } else if (l.toLowerCase().includes("short summary") || l.toLowerCase().includes("call summary") || l.toLowerCase().includes("summary:")) {
        currentSection = "summary";
        continue;
      }

      // Skip lines that are purely markdown headers or numbers indicating sections
      if (l.startsWith("#") || l.match(/^\d+\.\s+\*\*.*?\*\*/i) || l.match(/^\d+\.\s+Summary/i)) {
        continue;
      }

      // Skip intro lines in summary section
      if (currentSection === "summary" && (
        l.toLowerCase().startsWith("here is") || 
        l.toLowerCase().startsWith("based on") || 
        l.toLowerCase().startsWith("this is a")
      )) {
        continue;
      }

      // Process list items or paragraphs
      if (l.startsWith("-") || l.startsWith("*") || l.startsWith("•")) {
        const content = l.replace(/^[-*•\s]+/, "").trim();
        if (content.length > 0) {
          if (currentSection === "points") points.push(content);
          else if (currentSection === "actions") actions.push(content);
          else if (currentSection === "keywords") keywords.push(content);
          else if (currentSection === "followups") followUps.push(content);
        }
      } else {
        if (currentSection === "summary") {
          // Filter out markdown bold markers from the summary block
          const cleanText = l.replace(/\*\*/g, "").trim();
          if (cleanText.length > 0) {
            summary += (summary ? " " : "") + cleanText;
          }
        } else {
          // If it doesn't start with a bullet point but we are in a bullet section, treat it as a bullet point anyway if it has content
          const content = l.trim();
          if (content.length > 0) {
            if (currentSection === "points") points.push(content);
            else if (currentSection === "actions") actions.push(content);
            else if (currentSection === "keywords") keywords.push(content);
            else if (currentSection === "followups") followUps.push(content);
          }
        }
      }
    }

    return { summary, points, actions, sentiment, keywords, followUps };
  })() : null;

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
                          <button
                            onClick={() => handleShowSummary(rec.callRecordingId)}
                            className="p-1 bg-white dark:bg-gray-800 text-indigo-500 hover:text-indigo-700 dark:hover:text-indigo-400 rounded-lg shadow-sm border border-gray-100 dark:border-gray-700 transition"
                            title="AI Call Summary"
                          >
                            <Sparkles className="w-3.5 h-3.5" />
                          </button>
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
      {/* AI Summary Modal */}
      <Modal isOpen={summaryOpen} onClose={() => setSummaryOpen(false)} className="max-w-[650px] p-6 m-4 overflow-y-auto max-h-[85vh] rounded-2xl border border-gray-100 dark:border-gray-800 shadow-2xl bg-white dark:bg-gray-900">
        <div className="flex items-center gap-3 border-b border-gray-100 dark:border-gray-800 pb-4 mb-5">
          <div className="p-2.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/30 text-indigo-600 dark:text-indigo-400 shadow-sm">
            <Sparkles className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">AI Call Analysis</h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">Powered by Gemini Developer Suite</p>
          </div>
        </div>

        {summaryLoading && (
          <div className="py-16 flex flex-col items-center justify-center gap-4">
            <div className="relative w-12 h-12 flex items-center justify-center">
              <div className="absolute w-12 h-12 border-4 border-indigo-100 dark:border-indigo-950/50 rounded-full"></div>
              <div className="absolute w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
            </div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400 animate-pulse">Gemini is transcribing & analyzing recording...</p>
          </div>
        )}

        {summaryError && (
          <div className="p-4 rounded-2xl bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800/60 text-red-650 dark:text-red-400 text-sm font-medium flex gap-3 items-start">
            <ShieldAlert className="w-5 h-5 shrink-0 mt-0.5 text-red-550" />
            <div>
              <h4 className="font-bold mb-0.5">Analysis Failed</h4>
              <p className="text-xs opacity-90 leading-relaxed">{summaryError}</p>
            </div>
          </div>
        )}

        {!summaryLoading && !summaryError && parsedSummary && (
          <div className="space-y-6 text-sm">
            {/* Sentiment & Overview */}
            <div className="flex items-center justify-between gap-3 bg-gray-50/50 dark:bg-gray-800/20 border border-gray-150 dark:border-gray-800/80 p-4 rounded-2xl shadow-sm">
              <span className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">Overall Call Sentiment</span>
              <span className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold shadow-sm border ${
                parsedSummary.sentiment === "Positive" ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-600 dark:text-emerald-400" :
                parsedSummary.sentiment === "Negative" ? "bg-rose-500/10 border-rose-500/20 text-rose-600 dark:text-rose-400" :
                "bg-gray-500/10 border-gray-500/20 text-gray-600 dark:text-gray-400"
              }`}>
                <span className={`w-1.5 h-1.5 rounded-full ${
                  parsedSummary.sentiment === "Positive" ? "bg-emerald-500 animate-pulse" :
                  parsedSummary.sentiment === "Negative" ? "bg-rose-500 animate-pulse" :
                  "bg-gray-400"
                }`} />
                {parsedSummary.sentiment}
              </span>
            </div>

            {/* Short Summary */}
            {parsedSummary.summary && (
              <div className="space-y-2">
                <h4 className="font-bold text-gray-900 dark:text-gray-100 flex items-center gap-1.5 text-xs uppercase tracking-wider text-gray-500">
                  Call Summary
                </h4>
                <div className="p-4 rounded-2xl bg-indigo-50/20 dark:bg-indigo-950/10 border border-indigo-100/50 dark:border-indigo-950/20 text-gray-700 dark:text-gray-300 leading-relaxed text-[13.5px]">
                  {parsedSummary.summary}
                </div>
              </div>
            )}

            {/* Key Discussion Points */}
            {parsedSummary.points.length > 0 && (
              <div className="space-y-2">
                <h4 className="font-bold text-gray-900 dark:text-gray-100 flex items-center gap-1.5 text-xs uppercase tracking-wider text-gray-500">
                  Key Discussion Points
                </h4>
                <div className="p-4 rounded-2xl bg-gray-50/30 dark:bg-gray-800/10 border-l-4 border-indigo-500 border border-gray-100 dark:border-gray-800/50">
                  <ul className="space-y-3">
                    {parsedSummary.points.map((pt, i) => (
                      <li key={i} className="flex gap-3 text-gray-700 dark:text-gray-300 text-[13.5px] leading-relaxed">
                        <MessageSquare className="w-4 h-4 text-indigo-500 dark:text-indigo-400 shrink-0 mt-0.5" />
                        <span>{pt}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}

            {/* Action Items */}
            {parsedSummary.actions.length > 0 && (
              <div className="space-y-2">
                <h4 className="font-bold text-gray-900 dark:text-gray-100 flex items-center gap-1.5 text-xs uppercase tracking-wider text-gray-500">
                  Action Items
                </h4>
                <div className="p-4 rounded-2xl bg-gray-50/30 dark:bg-gray-800/10 border-l-4 border-emerald-500 border border-gray-100 dark:border-gray-800/50">
                  <ul className="space-y-3">
                    {parsedSummary.actions.map((item, i) => (
                      <li key={i} className="flex gap-3 text-gray-700 dark:text-gray-300 text-[13.5px] leading-relaxed">
                        <CheckSquare className="w-4 h-4 text-emerald-500 dark:text-emerald-400 shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}

            {/* Follow-ups */}
            {parsedSummary.followUps.length > 0 && (
              <div className="space-y-2">
                <h4 className="font-bold text-gray-900 dark:text-gray-100 flex items-center gap-1.5 text-xs uppercase tracking-wider text-gray-500">
                  Follow-up Suggestions
                </h4>
                <div className="p-4 rounded-2xl bg-gray-50/30 dark:bg-gray-800/10 border-l-4 border-amber-500 border border-gray-100 dark:border-gray-800/50">
                  <ul className="space-y-3">
                    {parsedSummary.followUps.map((item, i) => (
                      <li key={i} className="flex gap-3 text-gray-700 dark:text-gray-300 text-[13.5px] leading-relaxed">
                        <Lightbulb className="w-4 h-4 text-amber-500 dark:text-amber-400 shrink-0 mt-0.5" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}

            {/* Keywords */}
            {parsedSummary.keywords.length > 0 && (
              <div className="space-y-2.5 border-t border-gray-100 dark:border-gray-800/80 pt-4 mt-5">
                <h4 className="font-bold text-gray-900 dark:text-gray-100 flex items-center gap-1.5 text-xs uppercase tracking-wider text-gray-500">
                  Tags & Keywords
                </h4>
                <div className="flex flex-wrap gap-2">
                  {parsedSummary.keywords.map((word, i) => (
                    <span key={i} className="flex items-center gap-1 px-3 py-1 rounded-full bg-gray-50 dark:bg-gray-800/60 border border-gray-200/80 dark:border-gray-700/60 text-xs font-semibold text-gray-600 dark:text-gray-400">
                      <Tag className="w-3.5 h-3.5 text-gray-400 shrink-0" />
                      {word}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </Modal>
    </div>
  );
}
