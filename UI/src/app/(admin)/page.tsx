"use client";
import React, { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import { callService, employeeService } from "@/lib/services";
import { getCompanyIdFromToken } from "@/lib/auth";
import { Phone, Users, ShieldAlert, ArrowUpRight, Clock, Activity, Calendar } from "lucide-react";
import { ApexOptions } from "apexcharts";

// Dynamically import ApexCharts for Next.js SSR compatibility
const ReactApexChart = dynamic(() => import("react-apexcharts"), { ssr: false });

export default function DashboardPage() {
  const [dashboardData, setDashboardData] = useState<any>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [selectedDate, setSelectedDate] = useState<string>(() => {
    const today = new Date();
    const y = today.getFullYear();
    const m = (today.getMonth() + 1).toString().padStart(2, "0");
    const d = today.getDate().toString().padStart(2, "0");
    return `${y}-${m}-${d}`;
  });
  const [selectedEmployee, setSelectedEmployee] = useState<string>("All");
  const [isAdmin, setIsAdmin] = useState(false);
  const [employees, setEmployees] = useState<any[]>([]);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const userStr = localStorage.getItem("user");
      if (userStr) {
        try {
          const userObj = JSON.parse(userStr);
          const role = userObj.roleName || "";
          setIsAdmin(role === "Company Admin" || role === "Super Admin" || userObj.tenant);
        } catch (e) {}
      }
    }
  }, []);

  useEffect(() => {
    const fetchEmployees = async () => {
      try {
        const cid = getCompanyIdFromToken();
        const res = await employeeService.getEmployees(1, 100, "", cid || undefined);
        let list: any[] = [];
        if (res?.success) {
          if (res.data && Array.isArray(res.data.items)) {
            list = res.data.items;
          } else if (Array.isArray(res.data)) {
            list = res.data;
          }
        } else if (Array.isArray(res)) {
          list = res;
        }
        setEmployees(list.filter(e => !e.tenant));
      } catch (e) {
        console.error(e);
      }
    };
    if (isAdmin) {
      fetchEmployees();
    }
  }, [isAdmin]);

  useEffect(() => {
    const loadDashboardData = async () => {
      setLoading(true);
      try {
        const res = await callService.getDashboardSummary(
          selectedDate || undefined, 
          selectedEmployee !== "All" ? selectedEmployee : undefined
        ).catch(() => null);
        if (res?.success) {
          setDashboardData(res.data);
        } else {
          setDashboardData(null);
        }
      } catch (err) {
        console.error("Failed to load dashboard metrics", err);
        setDashboardData(null);
      } finally {
        setLoading(false);
      }
    };

    loadDashboardData();
  }, [selectedDate, selectedEmployee]);

  // ApexCharts Configuration
  const lineChartOptions: ApexOptions = {
    chart: {
      type: "area",
      toolbar: { show: false },
      fontFamily: "Inter, sans-serif",
    },
    colors: ["#4F46E5", "#10B981"],
    stroke: { curve: "smooth", width: 3 },
    fill: {
      type: "gradient",
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.45,
        opacityTo: 0.05,
      },
    },
    xaxis: {
      categories: dashboardData?.weeklyLabels && dashboardData.weeklyLabels.length > 0 
        ? dashboardData.weeklyLabels 
        : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      labels: { style: { colors: "#9CA3AF" } },
    },
    yaxis: {
      labels: { style: { colors: "#9CA3AF" } },
    },
    grid: { borderColor: "#37415120" },
    legend: { labels: { colors: "#9CA3AF" } },
  };

  const lineChartSeries = [
    { 
      name: "Total Calls", 
      data: dashboardData?.weeklyCallVolume && dashboardData.weeklyCallVolume.length > 0 
        ? dashboardData.weeklyCallVolume 
        : [0, 0, 0, 0, 0, 0, 0] 
    },
    { 
      name: "Leads Converted", 
      data: dashboardData?.weeklyLeadConversions && dashboardData.weeklyLeadConversions.length > 0 
        ? dashboardData.weeklyLeadConversions 
        : [0, 0, 0, 0, 0, 0, 0] 
    },
  ];

  const donutChartOptions: ApexOptions = {
    chart: { type: "donut" },
    labels: ["Answered", "Missed", "Rejected", "Busy"],
    colors: ["#10B981", "#EF4444", "#F59E0B", "#6B7280"],
    legend: { position: "bottom", labels: { colors: "#9CA3AF" } },
    dataLabels: { enabled: false },
  };

  const answered = dashboardData?.answeredCalls ?? 0;
  const missed = dashboardData?.missedCalls ?? 0;
  const rejected = dashboardData?.rejectedCalls ?? 0;
  const busy = dashboardData?.busyCalls ?? 0;

  const donutChartSeries = [answered, missed, rejected, busy];

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-brand-600 via-indigo-600 to-purple-600 text-white shadow-xl shadow-brand-500/20 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold mb-2">Callalyze Executive Overview</h1>
          <p className="text-brand-100 text-sm max-w-xl">
            Real-time enterprise intelligence monitoring call volume, active mobile telemetry, and CRM sales pipelines.
          </p>
        </div>
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-md rounded-xl text-xs font-semibold border border-white/20">
          <span>Live Telemetry Running</span>
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
        </div>
      </div>

      {/* Filters Control Panel */}
      <div className="p-4 bg-white dark:bg-gray-900 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col sm:flex-row items-stretch sm:items-center justify-end gap-4">
        <div className="flex flex-wrap items-center gap-3">
          {/* Employee Wise Filter (Admins Only) */}
          {isAdmin && (
            <div className="flex items-center gap-2">
              <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider">
                Agent:
              </span>
              <select
                value={selectedEmployee}
                onChange={(e) => setSelectedEmployee(e.target.value)}
                className="px-3 py-1.5 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500 cursor-pointer"
              >
                <option value="All">All Agents</option>
                {employees.map((emp) => (
                  <option key={emp.employeeId} value={emp.employeeId}>
                    {emp.employeeName || `${emp.firstName} ${emp.lastName}`}
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Date Picker */}
          <label className="flex items-center gap-2 cursor-pointer select-none">
            <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-brand-500" /> Date:
            </span>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              onClick={(e) => {
                try {
                  e.currentTarget.showPicker();
                } catch (err) {}
              }}
              className="px-3 py-1.5 text-sm bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-brand-500 cursor-pointer"
            />
          </label>
          {selectedDate && (
            <button
              onClick={() => setSelectedDate("")}
              className="px-2.5 py-1.5 text-xs font-semibold text-red-500 hover:text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-950/20 rounded-lg transition"
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Total Calls</span>
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {loading ? "..." : (dashboardData?.totalCalls ?? 0)}
            </h3>
            <span className="text-xs font-medium text-emerald-500 flex items-center mt-1">
              <ArrowUpRight className="w-3.5 h-3.5 mr-0.5" /> Dynamic Tracking
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-brand-50 dark:bg-brand-950/50 flex items-center justify-center text-brand-600 dark:text-brand-400">
            <Phone className="w-6 h-6" />
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">CRM Leads</span>
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {loading ? "..." : (dashboardData?.totalLeads ?? 0)}
            </h3>
            <span className="text-xs font-medium text-emerald-500 flex items-center mt-1">
              <ArrowUpRight className="w-3.5 h-3.5 mr-0.5" /> Active Pipeline
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-indigo-50 dark:bg-indigo-950/50 flex items-center justify-center text-indigo-600 dark:text-indigo-400">
            <Users className="w-6 h-6" />
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Active Devices</span>
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {loading ? "..." : (dashboardData?.totalDevices ?? 0)}
            </h3>
            <span className="text-xs font-medium text-blue-500 flex items-center mt-1">
              <Activity className="w-3.5 h-3.5 mr-0.5" /> Registered Mobile Units
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-blue-50 dark:bg-blue-950/50 flex items-center justify-center text-blue-600 dark:text-blue-400">
            <ShieldAlert className="w-6 h-6" />
          </div>
        </div>

        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Avg Call Duration</span>
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {loading ? "..." : `${dashboardData?.averageDurationSeconds ?? 0}s`}
            </h3>
            <span className="text-xs font-medium text-purple-500 flex items-center mt-1">
              <Clock className="w-3.5 h-3.5 mr-0.5" /> Call Engagement
            </span>
          </div>
          <div className="w-12 h-12 rounded-xl bg-purple-50 dark:bg-purple-950/50 flex items-center justify-center text-purple-600 dark:text-purple-400">
            <Clock className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Apex Analytics Graphs */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 p-6 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg font-bold text-gray-900 dark:text-white">Call Volume vs Lead Conversions</h3>
              <p className="text-xs text-gray-400">Weekly call activity telemetry trend</p>
            </div>
          </div>
          <div className="h-72">
            <ReactApexChart options={lineChartOptions} series={lineChartSeries} type="area" height="100%" />
          </div>
        </div>

        <div className="p-6 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-1">Call Disposition</h3>
            <p className="text-xs text-gray-400 mb-4">Distribution of agent call outcomes</p>
          </div>
          <div className="h-64 flex items-center justify-center">
            {answered + missed + rejected + busy > 0 ? (
              <ReactApexChart options={donutChartOptions} series={donutChartSeries} type="donut" height="100%" />
            ) : (
              <div className="text-center text-gray-400 dark:text-gray-500 text-sm flex flex-col items-center justify-center">
                <Activity className="w-12 h-12 mb-2 text-gray-300 dark:text-gray-700 animate-pulse" />
                No call telemetry logged
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
