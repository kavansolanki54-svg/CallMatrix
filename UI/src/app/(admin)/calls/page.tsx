"use client";
import React, { useEffect, useState } from "react";
import { callService } from "@/lib/services";
import { Search, Phone, PhoneIncoming, PhoneOutgoing, PhoneMissed, Play, Clock, Calendar, Sparkles, CheckSquare, MessageSquare, Lightbulb, Tag, ShieldAlert } from "lucide-react";
import { Modal } from "@/components/ui/modal";

export default function CallsPage() {
  const [calls, setCalls] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [clientPage, setClientPage] = useState(1);
  const [pageSize, setPageSize] = useState(5);
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
      const res = await callService.getCalls(1, 1000, search, selectedDate || undefined, callType);
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
  }, [search, selectedDate, callType]);

  const filteredCalls = calls.filter((c) => {
    if (callType && callType !== "All") {
      return c.callType === callType;
    }
    return true;
  });

  const grandTotalCalls = filteredCalls.length;
  const grandTotalDuration = filteredCalls.reduce((sum, call) => sum + (call.duration || 0), 0);
  const startIndex = (clientPage - 1) * pageSize;
  const paginatedCalls = filteredCalls.slice(startIndex, startIndex + pageSize);

  return (
    <div className="space-y-6">
      <div className="p-3 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search by Employee or phone..."
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setClientPage(1);
            }}
            className="w-full pl-9 pr-4 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Call Type Filter */}
          <div className="flex items-center gap-2">
            <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider">
              TYPE:
            </span>
            <select
              value={callType}
              onChange={(e) => {
                setCallType(e.target.value);
                setClientPage(1);
              }}
              className="px-3 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500 cursor-pointer font-semibold"
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
              <Calendar className="w-3.5 h-3.5 text-brand-500" /> DATE:
            </span>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => {
                setSelectedDate(e.target.value);
                setClientPage(1);
              }}
              onClick={(e) => {
                try {
                  e.currentTarget.showPicker();
                } catch (err) { }
              }}
              className="px-3 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500 cursor-pointer font-semibold"
            />
          </label>
          {selectedDate && (
            <button
              onClick={() => {
                setSelectedDate("");
                setClientPage(1);
              }}
              className="px-3 py-2 text-xs font-semibold text-red-500 hover:text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-950/20 rounded-lg transition"
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
                <th className="px-6 py-4 text-xs font-semibold">
                  Type <span className="text-brand-600 dark:text-brand-400 font-extrabold text-[12.5px] ml-0.5">({grandTotalCalls} Calls)</span>
                </th>
                <th className="px-6 py-4">Phone Number</th>
                <th className="px-6 py-4">Employee</th>
                <th className="px-6 py-4 text-xs font-semibold">
                  Duration <span className="text-indigo-600 dark:text-indigo-400 font-extrabold text-[12.5px] ml-0.5">({(grandTotalDuration / 3600).toFixed(1)} Hours)</span>
                </th>
                <th className="px-6 py-4 text-right">Recording</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-gray-400">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <div className="w-6 h-6 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
                      <span className="text-xs">Loading call logs...</span>
                    </div>
                  </td>
                </tr>
              ) : calls.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center">
                    <div className="flex flex-col items-center justify-center text-gray-400 dark:text-gray-500">
                      <Phone className="w-12 h-12 text-gray-300 dark:text-gray-700 mb-2" />
                      <p className="font-semibold text-sm">No call logs found</p>
                      <p className="text-xs opacity-80 mt-0.5">Try changing your search or date filter.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                Object.entries(groupCallsByDate(paginatedCalls))
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
                            {/* Type badge */}
                            <td className="px-6 py-4">
                              <span className="flex items-center gap-1.5 font-bold text-xs">
                                {cType === "Incoming" ? <PhoneIncoming className="w-4 h-4 text-emerald-500" /> :
                                  cType === "Outgoing" ? <PhoneOutgoing className="w-4 h-4 text-blue-500" /> :
                                    <PhoneMissed className="w-4 h-4 text-red-500" />}
                                {cType}
                              </span>
                            </td>

                            {/* Phone Number & Name */}
                            <td className="px-6 py-4">
                              <div className="flex items-center gap-3">
                                <div className="w-10 h-10 rounded-full bg-brand-50 dark:bg-brand-950/40 text-brand-600 dark:text-brand-400 flex items-center justify-center font-bold text-sm shadow-sm border border-brand-100/50 dark:border-brand-950/20">
                                  {call.contactName ? call.contactName.charAt(0).toUpperCase() : "#"}
                                </div>
                                <div>
                                  <div className="font-bold text-gray-900 dark:text-white text-[14.5px] leading-tight">
                                    {call.phoneNumber}
                                  </div>
                                  {call.contactName && (
                                    <div className="text-xs text-gray-400 dark:text-gray-500 font-semibold mt-0.5">
                                      {call.contactName}
                                    </div>
                                  )}
                                </div>
                              </div>
                            </td>

                            {/* Employee */}
                            <td className="px-6 py-4">
                              <div className="flex items-center gap-2">
                                <div className="w-6 h-6 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-650 dark:text-gray-450 flex items-center justify-center font-bold text-[10px] uppercase shadow-sm border border-gray-250/50 dark:border-gray-700/50">
                                  {call.employeeName ? call.employeeName.charAt(0).toUpperCase() : "E"}
                                </div>
                                <span className="font-semibold text-gray-750 dark:text-gray-300 text-xs">
                                  {call.employeeName || `Employee #${call.employeeId}`}
                                </span>
                              </div>
                            </td>

                            {/* Duration */}
                            <td className="px-6 py-4 font-semibold text-gray-800 dark:text-gray-200 text-xs font-mono">
                              <div className="flex items-center gap-1.5">
                                <Clock className="w-3.5 h-3.5 text-gray-450 shrink-0" />
                                {formatDuration(call.duration)}
                              </div>
                            </td>

                            {/* Action / Recording */}
                            <td className="px-6 py-4 text-right">
                              {call.hasRecording && call.recordingUrl ? (
                                <div className="flex items-center justify-end gap-2">
                                  {/* AI Summary Button */}
                                  <button
                                    onClick={() => handleShowSummary(call.callId)}
                                    className="p-2 bg-indigo-50 hover:bg-indigo-100 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 rounded-lg shadow-sm border border-indigo-100/50 dark:border-indigo-950/30 transition flex items-center justify-center"
                                    title="View AI Analysis"
                                  >
                                    <Sparkles className="w-4 h-4" />
                                  </button>

                                  {/* Play Button */}
                                  <button
                                    onClick={() => {
                                      const apiBase = process.env.NEXT_PUBLIC_API_URL || "http://localhost:5164/api";
                                      const baseUrl = apiBase.replace(/\/api\/?$/, "");
                                      const fullUrl = call.recordingUrl.startsWith("http")
                                        ? call.recordingUrl
                                        : `${baseUrl}${call.recordingUrl}`;
                                      setActiveRecordingUrl(fullUrl);
                                    }}
                                    className="p-2 bg-brand-500 hover:bg-brand-600 text-white rounded-lg shadow-sm border border-brand-500 hover:border-brand-600 transition flex items-center justify-center"
                                    title="Play Recording"
                                  >
                                    <Play className="w-4 h-4 fill-current" />
                                  </button>
                                </div>
                              ) : (
                                <span className="text-xs text-gray-450 font-semibold italic">N/A</span>
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
        {!loading && (() => {
          const totalCalls = filteredCalls.length;
          const totalPages = Math.ceil(totalCalls / pageSize);
          const startIndex = (clientPage - 1) * pageSize;
          if (totalCalls === 0) return null;

          return (
            <div className="flex flex-col sm:flex-row items-center justify-between gap-4 px-6 py-4 bg-white dark:bg-gray-900 border-t border-gray-100 dark:border-gray-800/80">
              <div className="text-xs text-gray-500">
                Showing <span className="font-semibold text-gray-700 dark:text-gray-300">{startIndex + 1}</span>–<span className="font-semibold text-gray-700 dark:text-gray-300">{Math.min(startIndex + pageSize, totalCalls)}</span> of <span className="font-semibold text-gray-700 dark:text-gray-300">{totalCalls}</span> calls
              </div>
              
              <div className="flex flex-wrap items-center gap-4">
                {/* Page Size Selector */}
                <div className="flex items-center gap-2 text-xs text-gray-500">
                  <span>Show:</span>
                  <select
                    value={pageSize}
                    onChange={(e) => {
                      setPageSize(Number(e.target.value));
                      setClientPage(1);
                    }}
                    className="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg px-2 py-1 focus:outline-none focus:ring-1 focus:ring-brand-500 font-semibold cursor-pointer text-gray-750 dark:text-gray-350"
                  >
                    <option value={5}>5</option>
                    <option value={10}>10</option>
                    <option value={20}>20</option>
                    <option value={50}>50</option>
                  </select>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    onClick={() => setClientPage((p) => Math.max(p - 1, 1))}
                    disabled={clientPage === 1}
                    className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-semibold text-gray-600 dark:text-gray-400 disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
                  >
                    Previous
                  </button>
                  <div className="hidden sm:flex items-center gap-1.5">
                    {Array.from({ length: totalPages }, (_, i) => i + 1).map((pNum) => (
                      <button
                        key={pNum}
                        onClick={() => setClientPage(pNum)}
                        className={`w-7 h-7 rounded-lg text-xs font-semibold transition ${clientPage === pNum
                          ? "bg-brand-500 text-white shadow-md shadow-brand-500/10"
                          : "text-gray-600 dark:text-gray-400 hover:bg-gray-50 dark:hover:bg-gray-800"
                          }`}
                      >
                        {pNum}
                      </button>
                    ))}
                  </div>
                  <button
                    onClick={() => setClientPage((p) => Math.min(p + 1, totalPages))}
                    disabled={clientPage === totalPages}
                    className="px-3 py-1.5 rounded-lg border border-gray-200 dark:border-gray-700 text-xs font-semibold text-gray-600 dark:text-gray-400 disabled:opacity-50 hover:bg-gray-50 dark:hover:bg-gray-800 transition"
                  >
                    Next
                  </button>
                </div>
              </div>
            </div>
          );
        })()}
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
      <Modal isOpen={summaryOpen} onClose={() => setSummaryOpen(false)} className="max-w-[650px] p-6 m-4 overflow-y-auto max-h-[85vh] rounded-2xl border border-gray-100 dark:border-gray-800 shadow-2xl bg-white dark:bg-gray-900">
        <div className="flex items-center gap-3 border-b border-gray-100 dark:border-gray-800 pb-4 mb-5">
          <div className="p-2.5 rounded-xl bg-indigo-50 dark:bg-indigo-950/30 text-indigo-600 dark:text-indigo-400 shadow-sm">
            <Sparkles className="w-5 h-5 animate-pulse" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white tracking-tight">AI Call Analysis</h3>
            <p className="text-xs text-gray-500 dark:text-gray-400">Powered by Callalyze AI</p>
          </div>
        </div>

        {summaryLoading && (
          <div className="py-16 flex flex-col items-center justify-center gap-4">
            <div className="relative w-12 h-12 flex items-center justify-center">
              <div className="absolute w-12 h-12 border-4 border-indigo-100 dark:border-indigo-950/50 rounded-full"></div>
              <div className="absolute w-12 h-12 border-4 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
            </div>
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400 animate-pulse">AI is transcribing & analyzing recording...</p>
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
              <span className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold shadow-sm border ${parsedSummary.sentiment === "Positive" ? "bg-emerald-500/10 border-emerald-500/20 text-emerald-600 dark:text-emerald-400" :
                parsedSummary.sentiment === "Negative" ? "bg-rose-500/10 border-rose-500/20 text-rose-600 dark:text-rose-400" :
                  "bg-gray-500/10 border-gray-500/20 text-gray-600 dark:text-gray-400"
                }`}>
                <span className={`w-1.5 h-1.5 rounded-full ${parsedSummary.sentiment === "Positive" ? "bg-emerald-500 animate-pulse" :
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
