"use client";
import React, { useState, useEffect } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import Button from "@/components/ui/button/Button";
import Input from "@/components/form/input/InputField";
import { apiClient } from "@/lib/services";
import { getCompanyIdFromToken } from "@/lib/auth";

export default function ReportsPage() {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    const fetchReports = async () => {
      setLoading(true);
      const cid = getCompanyIdFromToken();
      try {
        let url = `/reports?search=${encodeURIComponent(search)}`;
        if (cid) url += `&companyId=${cid}`;
        const res = await apiClient.get(url);
        if (res.data?.success && Array.isArray(res.data.data)) {
          setReports(res.data.data);
        } else if (Array.isArray(res.data)) {
          setReports(res.data);
        } else {
          setReports([]);
        }
      } catch (err) {
        console.warn("Reports API error fallback", err);
        setReports([]);
      } finally {
        setLoading(false);
      }
    };
    fetchReports();
  }, [search]);

  return (
    <div>
      <PageBreadcrumb pageTitle="Reports & Analytics" />
      <div className="space-y-6">
        <ComponentCard title="Company Performance Reports" desc="Export operational telemetry and CRM activity logs">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
            <div className="w-full sm:w-72">
              <Input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search reports..."
              />
            </div>
            <Button className="bg-brand-500 hover:bg-brand-600 text-white">
              Generate New Report
            </Button>
          </div>

          <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-200 font-semibold uppercase text-xs">
                <tr>
                  <th className="p-4">Report Title</th>
                  <th className="p-4">Module</th>
                  <th className="p-4">Generated Date</th>
                  <th className="p-4">Format</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="p-6 text-center text-gray-500 dark:text-gray-400">
                      Loading reports data...
                    </td>
                  </tr>
                ) : reports.length > 0 ? (
                  reports.map((r, index) => (
                    <tr key={index} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30">
                      <td className="p-4 font-medium text-gray-900 dark:text-white">{r.title || r.reportName}</td>
                      <td className="p-4">{r.module || "General"}</td>
                      <td className="p-4">{r.generatedAt || new Date().toLocaleDateString()}</td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
                          {r.format || "PDF"}
                        </span>
                      </td>
                      <td className="p-4">
                        <button className="text-sm font-medium text-brand-600 hover:text-brand-700 dark:text-brand-400">
                          Download
                        </button>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={5} className="p-6 text-center text-gray-500 dark:text-gray-400">
                      No reports generated for current company token context.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </ComponentCard>
      </div>
    </div>
  );
}
