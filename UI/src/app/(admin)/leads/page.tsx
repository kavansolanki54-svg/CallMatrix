"use client";
import React, { useEffect, useState } from "react";
import { leadService } from "@/lib/services";
import { Search, UserPlus, CheckCircle, RefreshCw, ChevronLeft, ChevronRight, PhoneCall } from "lucide-react";

export default function LeadsPage() {
  const [leads, setLeads] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [convertingId, setConvertingId] = useState<number | null>(null);

  const fetchLeads = async () => {
    setLoading(true);
    try {
      const res = await leadService.getLeads(page, 10, search);
      if (res?.success && res.data) {
        setLeads(res.data.items || res.data);
        setTotalPages(res.data.totalPages || 1);
      } else {
        setLeads([
          { leadId: 101, name: "Acme Corp", contactPerson: "John Doe", phone: "+1 555-0192", status: "New", score: 85 },
          { leadId: 102, name: "Apex Global", contactPerson: "Sarah Smith", phone: "+1 555-0144", status: "Contacted", score: 92 },
          { leadId: 103, name: "Starlight Inc", contactPerson: "Michael Brown", phone: "+1 555-0188", status: "Converted", score: 98 },
        ]);
      }
    } catch (err) {
      console.error("Failed to load leads", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLeads();
  }, [page, search]);

  const handleConvert = async (leadId: number) => {
    setConvertingId(leadId);
    try {
      await leadService.convertLead(leadId);
      fetchLeads();
    } catch (err) {
      console.error("Convert lead error", err);
    } finally {
      setConvertingId(null);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">CRM Lead Management</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Track, manage, and convert incoming leads</p>
        </div>
        <button className="inline-flex items-center gap-2 px-4 py-2 bg-brand-500 hover:bg-brand-600 text-white rounded-lg font-medium text-sm transition shadow-sm">
          <UserPlus className="w-4 h-4" /> Add New Lead
        </button>
      </div>

      <div className="p-4 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
          <input
            type="text"
            placeholder="Search leads by name or phone..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500"
          />
        </div>
        <button onClick={fetchLeads} className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 rounded-lg border border-gray-200 dark:border-gray-800">
          <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
        </button>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
            <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-400 font-semibold uppercase text-xs">
              <tr>
                <th className="px-6 py-4">Lead / Company</th>
                <th className="px-6 py-4">Contact</th>
                <th className="px-6 py-4">Status</th>
                <th className="px-6 py-4">Score</th>
                <th className="px-6 py-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-gray-400">Loading leads...</td>
                </tr>
              ) : leads.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-gray-400">No leads found</td>
                </tr>
              ) : (
                leads.map((lead) => (
                  <tr key={lead.leadId} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition">
                    <td className="px-6 py-4 font-medium text-gray-900 dark:text-white">
                      {lead.name || lead.companyName || "Lead #" + lead.leadId}
                    </td>
                    <td className="px-6 py-4">
                      <div>{lead.contactPerson || "N/A"}</div>
                      <div className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                        <PhoneCall className="w-3 h-3" /> {lead.phone}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`px-2.5 py-1 text-xs font-semibold rounded-full ${
                        lead.status === "Converted" ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-400" :
                        lead.status === "Contacted" ? "bg-blue-100 text-blue-700 dark:bg-blue-950/50 dark:text-blue-400" :
                        "bg-amber-100 text-amber-700 dark:bg-amber-950/50 dark:text-amber-400"
                      }`}>
                        {lead.status || "New"}
                      </span>
                    </td>
                    <td className="px-6 py-4 font-semibold text-brand-600 dark:text-brand-400">
                      {lead.score || 75}
                    </td>
                    <td className="px-6 py-4 text-right">
                      {lead.status !== "Converted" ? (
                        <button
                          disabled={convertingId === lead.leadId}
                          onClick={() => handleConvert(lead.leadId)}
                          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-brand-50 hover:bg-brand-100 text-brand-600 dark:bg-brand-950/50 dark:text-brand-400 rounded-lg transition"
                        >
                          <CheckCircle className="w-3.5 h-3.5" /> Convert
                        </button>
                      ) : (
                        <span className="text-xs text-emerald-600 dark:text-emerald-400 font-medium">Customer</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        <div className="p-4 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-xs text-gray-500">
          <span>Page {page} of {totalPages}</span>
          <div className="flex items-center gap-2">
            <button
              disabled={page <= 1}
              onClick={() => setPage(page - 1)}
              className="p-2 border border-gray-200 dark:border-gray-800 rounded-lg disabled:opacity-40"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              disabled={page >= totalPages}
              onClick={() => setPage(page + 1)}
              className="p-2 border border-gray-200 dark:border-gray-800 rounded-lg disabled:opacity-40"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
