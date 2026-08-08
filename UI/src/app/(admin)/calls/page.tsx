"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Phone, PhoneIncoming, PhoneOutgoing, PhoneMissed, Play, Clock, Calendar, Sparkles } from "lucide-react";
import { Modal } from "@/components/ui/modal";

export default function CallsPage() {
  const [calls, setCalls] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [activeRecordingUrl, setActiveRecordingUrl] = useState<string | null>(null);

  const [summaryOpen, setSummaryOpen] = useState(false);
  const [summaryLoading, setSummaryLoading] = useState(false);
  const [summaryError, setSummaryError] = useState<string | null>(null);
  const [summaryText, setSummaryText] = useState<string | null>(null);

  const handleShowSummary = async (callId: number) => {
    setSummaryOpen(true);
    setSummaryLoading(true);
    setSummaryError(null);
    setSummaryText(null);
    try {
      const res = await callService.getCallSummary(callId);
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

      if (l.toLowerCase().includes("sentiment:")) {
        if (l.toLowerCase().includes("positive")) sentiment = "Positive";
        else if (l.toLowerCase().includes("negative")) sentiment = "Negative";
        else sentiment = "Neutral";
        continue;
      }

      if (l.toLowerCase().includes("key discussion") || l.toLowerCase().includes("discussion points")) {
        currentSection = "points";
        continue;
      } else if (l.toLowerCase().includes("action items") || l.toLowerCase().includes("to-do")) {
        currentSection = "actions";
        continue;
      } else if (l.toLowerCase().includes("keywords")) {
        currentSection = "keywords";
        continue;
      } else if (l.toLowerCase().includes("follow-up") || l.toLowerCase().includes("suggestions")) {
        currentSection = "followups";
        continue;
      } else if (l.match(/^\d\.\s/)) {
        continue;
      }

      if (l.startsWith("-") || l.startsWith("*")) {
        const content = l.replace(/^[-*\s]+/, "");
        if (currentSection === "points") points.push(content);
        else if (currentSection === "actions") actions.push(content);
        else if (currentSection === "keywords") keywords.push(content);
        else if (currentSection === "followups") followUps.push(content);
      } else {
        if (currentSection === "summary") {
          summary += (summary ? " " : "") + l;
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
    const d = new Date(dateStr.endsWith("Z") ? dateStr : dateStr + "Z");
    if (isNaN(d.getTime())) return dateStr;
    const hr = d.getHours().toString().padStart(2, "0");
    const min = d.getMinutes().toString().padStart(2, "0");
    return `${hr}:${min}`;
  };

  const groupCallsByDate = (callList: any[]) => {
    const groups: Record<string, any[]> = {};
    callList.forEach((call) => {
      if (!call.callDateTime) return;
      const d = new Date(call.callDateTime.endsWith("Z") ? call.callDateTime : call.callDateTime + "Z");
      const y = d.getFullYear();
      const m = (d.getMonth() + 1).toString().padStart(2, "0");
      const day = d.getDate().toString().padStart(2, "0");
      const dateKey = `${y}-${m}-${day}`;
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
                                <div className="flex items-center justify-end gap-2">
                                  <button
                                    onClick={() => handleShowSummary(call.callId)}
                                    className="p-2 text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-950/50 rounded-full hover:bg-indigo-100 transition"
                                    title="AI Summary"
                                  >
                                    <Sparkles className="w-3.5 h-3.5" />
                                  </button>
                                  <button
                                    onClick={() => {
                                      const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5164/api";
                                      const baseUrl = apiBase.replace(/\/api\/?$/, "");
                                      const fullUrl = call.recordingUrl.startsWith("http") 
                                        ? call.recordingUrl 
                                        : `${baseUrl}${call.recordingUrl}`;
                                      setActiveRecordingUrl(fullUrl);
                                    }}
                                    className="p-2 text-brand-600 dark:text-brand-400 bg-brand-50 dark:bg-brand-950/50 rounded-full hover:bg-brand-100 transition"
                                    title="Play Audio"
                                  >
                                    <Play className="w-3.5 h-3.5 fill-current" />
                                  </button>
                                </div>
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
            key={activeRecordingUrl}
            src={activeRecordingUrl} 
            controls 
            autoPlay 
            className="w-full focus:outline-none"
          />
        </div>
      )}
      {/* AI Summary Modal */}
      <Modal isOpen={summaryOpen} onClose={() => setSummaryOpen(false)} className="max-w-[650px] p-6 m-4 overflow-y-auto max-h-[85vh]">
        <div className="flex items-center gap-3 border-b border-gray-100 dark:border-gray-800 pb-4 mb-4">
          <div className="p-2 rounded-xl bg-indigo-50 dark:bg-indigo-950/30 text-indigo-600 dark:text-indigo-400">
            <Sparkles className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">AI Call Analysis</h3>
            <p className="text-xs text-gray-400">Powered by Gemini 1.5 Flash</p>
          </div>
        </div>

        {summaryLoading && (
          <div className="py-12 flex flex-col items-center justify-center gap-3">
            <div className="relative w-10 h-10 border-4 border-indigo-200 border-t-indigo-600 rounded-full animate-spin"></div>
            <p className="text-sm text-gray-500 animate-pulse">Gemini is transcribing & analyzing recording...</p>
          </div>
        )}

        {summaryError && (
          <div className="p-4 rounded-2xl bg-red-50 dark:bg-red-950/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 text-sm font-medium">
            <h4 className="font-bold mb-1">Analysis Failed</h4>
            <p className="text-xs opacity-90">{summaryError}</p>
          </div>
        )}

        {!summaryLoading && !summaryError && parsedSummary && (
          <div className="space-y-5 text-sm">
            {/* Sentiment & Overview */}
            <div className="flex items-center justify-between gap-3 bg-gray-50/50 dark:bg-gray-800/30 border border-gray-100 dark:border-gray-800 p-3 rounded-2xl">
              <span className="text-xs text-gray-500 font-medium">Overall Call Sentiment</span>
              <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                parsedSummary.sentiment === "Positive" ? "bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-800" :
                parsedSummary.sentiment === "Negative" ? "bg-red-50 dark:bg-red-950/50 text-red-600 dark:text-red-400 border border-red-200 dark:border-red-800" :
                "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400 border border-gray-200 dark:border-gray-700"
              }`}>
                {parsedSummary.sentiment}
              </span>
            </div>

            {/* Short Summary */}
            {parsedSummary.summary && (
              <div className="space-y-1.5">
                <h4 className="font-bold text-gray-800 dark:text-gray-200">Call Summary</h4>
                <div className="p-4 rounded-2xl bg-indigo-50/20 dark:bg-indigo-950/10 border border-indigo-100/50 dark:border-indigo-950/30 text-gray-600 dark:text-gray-300 leading-relaxed">
                  {parsedSummary.summary}
                </div>
              </div>
            )}

            {/* Key Discussion Points */}
            {parsedSummary.points.length > 0 && (
              <div className="space-y-1.5">
                <h4 className="font-bold text-gray-800 dark:text-gray-200">Key Discussion Points</h4>
                <ul className="space-y-2">
                  {parsedSummary.points.map((pt, i) => (
                    <li key={i} className="flex gap-2.5 text-gray-600 dark:text-gray-300">
                      <span className="w-1.5 h-1.5 rounded-full bg-indigo-500 mt-2 shrink-0" />
                      <span>{pt}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Action Items */}
            {parsedSummary.actions.length > 0 && (
              <div className="space-y-1.5">
                <h4 className="font-bold text-gray-800 dark:text-gray-200">Action Items</h4>
                <ul className="space-y-2">
                  {parsedSummary.actions.map((item, i) => (
                    <li key={i} className="flex gap-2.5 text-gray-600 dark:text-gray-300">
                      <span className="w-1.5 h-1.5 rounded-full bg-brand-500 mt-2 shrink-0" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Follow-ups */}
            {parsedSummary.followUps.length > 0 && (
              <div className="space-y-1.5">
                <h4 className="font-bold text-gray-800 dark:text-gray-200">Follow-up Suggestions</h4>
                <ul className="space-y-2">
                  {parsedSummary.followUps.map((item, i) => (
                    <li key={i} className="flex gap-2.5 text-gray-600 dark:text-gray-300">
                      <span className="w-1.5 h-1.5 rounded-full bg-amber-500 mt-2 shrink-0" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            {/* Keywords */}
            {parsedSummary.keywords.length > 0 && (
              <div className="space-y-1.5 border-t border-gray-100 dark:border-gray-800 pt-4 mt-4">
                <h4 className="font-bold text-gray-800 dark:text-gray-200">Tags & Keywords</h4>
                <div className="flex flex-wrap gap-1.5">
                  {parsedSummary.keywords.map((word, i) => (
                    <span key={i} className="px-2 py-0.5 rounded-lg bg-gray-100 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 dark:text-gray-400">
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
