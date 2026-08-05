"use client";
import React, { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import { callService, employeeService } from "@/lib/services";
import { getCompanyIdFromToken } from "@/lib/auth";
import { Phone, PhoneCall, ShieldAlert, Clock, ArrowUpRight, BarChart3, TrendingUp, Calendar } from "lucide-react";
import { ApexOptions } from "apexcharts";

// Dynamically import ApexCharts for Next.js SSR compatibility
const ReactApexChart = dynamic(() => import("react-apexcharts"), { ssr: false });

export default function AnalyticsPage() {
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
        console.error("Failed to load analytics metrics", err);
        setDashboardData(null);
      } finally {
        setLoading(false);
      }
    };

    loadDashboardData();
  }, [selectedDate, selectedEmployee]);

  const totalCalls = dashboardData?.totalCalls ?? 0;
  const answered = dashboardData?.answeredCalls ?? 0;
  const missed = dashboardData?.missedCalls ?? 0;
  const rejected = dashboardData?.rejectedCalls ?? 0;
  const busy = dashboardData?.busyCalls ?? 0;

  const averageDuration = dashboardData?.averageDurationSeconds ?? 0;
  const totalDurationSeconds = totalCalls * averageDuration;

  const formatTotalTime = (seconds: number) => {
    if (seconds <= 0) return "0h 0m";
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return `${hrs}h ${mins}m`;
  };

  // 1. Line/Area Chart Options - Call Trends
  const areaChartOptions: ApexOptions = {
    chart: {
      type: "area",
      toolbar: { show: false },
      fontFamily: "Inter, sans-serif",
    },
    colors: ["#6366F1"],
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
  };

  const areaChartSeries = [
    { 
      name: "Daily Calls Logged", 
      data: dashboardData?.weeklyCallVolume && dashboardData.weeklyCallVolume.length > 0 
        ? dashboardData.weeklyCallVolume 
        : [0, 0, 0, 0, 0, 0, 0] 
    }
  ];

  // 2. Bar Chart Options - Outcome distribution
  const barChartOptions: ApexOptions = {
    chart: {
      type: "bar",
      toolbar: { show: false },
      fontFamily: "Inter, sans-serif",
    },
    colors: ["#10B981", "#EF4444", "#F59E0B", "#6B7280"],
    plotOptions: {
      bar: {
        borderRadius: 6,
        columnWidth: "45%",
        distributed: true,
      }
    },
    dataLabels: { enabled: false },
    legend: { show: false },
    xaxis: {
      categories: ["Answered", "Missed", "Rejected", "Busy"],
      labels: { style: { colors: "#9CA3AF" } },
    },
    yaxis: {
      labels: { style: { colors: "#9CA3AF" } },
    },
    grid: { borderColor: "#37415115" },
  };

  const barChartSeries = [
    {
      name: "Calls Count",
      data: [answered, missed, rejected, busy]
    }
  ];

  // 3. Donut Chart Options - Call Ratio
  const donutChartOptions: ApexOptions = {
    chart: { type: "donut" },
    labels: ["Answered", "Unanswered"],
    colors: ["#4F46E5", "#F3F4F6"],
    legend: { show: false },
    dataLabels: { enabled: false },
    plotOptions: {
      pie: {
        donut: {
          size: "75%",
          labels: {
            show: true,
            total: {
              show: true,
              label: "Answered",
              formatter: () => `${totalCalls > 0 ? Math.round((answered / totalCalls) * 100) : 0}%`,
              fontSize: "18px",
              fontWeight: 600,
              color: "#111827",
            }
          }
        }
      }
    }
  };

  const donutChartSeries = [answered, totalCalls - answered];

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <TrendingUp className="w-7 h-7 text-indigo-500" />
            Call Telemetry Analytics
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Advanced diagnostic tools for monitoring call log distribution and metrics</p>
        </div>

        <div className="flex flex-wrap items-center gap-3 bg-white dark:bg-gray-900 px-4 py-2 border border-gray-100 dark:border-gray-800 rounded-xl shadow-sm self-start sm:self-auto">
          {/* Employee Wise Filter (Admins Only) */}
          {isAdmin && (
            <div className="flex items-center gap-2 border-r border-gray-100 dark:border-gray-800 pr-3 mr-1">
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

          <label className="flex items-center gap-2 cursor-pointer select-none">
            <span className="text-xs text-gray-500 dark:text-gray-400 font-semibold uppercase tracking-wider flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-brand-500" /> Date:
            </span>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => {
                setSelectedDate(e.target.value);
              }}
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
              onClick={() => {
                setSelectedDate("");
              }}
              className="px-2.5 py-1.5 text-xs font-semibold text-red-500 hover:text-red-700 dark:text-red-400 bg-red-50 dark:bg-red-950/20 rounded-lg transition"
            >
              Clear
            </button>
          )}
        </div>
      </div>

      {/* Analytics KPI Dashboard Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm">
          <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Total Call Volume</span>
          <div className="flex items-baseline gap-2 mt-2">
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{loading ? "..." : totalCalls}</h3>
            <span className="text-xs text-emerald-500 font-semibold flex items-center">
              <ArrowUpRight className="w-3 h-3 mr-0.5" /> +100%
            </span>
          </div>
          <p className="text-xs text-gray-400 mt-1.5 font-medium">Logged calls across workspace</p>
        </div>

        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm">
          <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Total Talk Time</span>
          <div className="flex items-baseline gap-2 mt-2">
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{loading ? "..." : formatTotalTime(totalDurationSeconds)}</h3>
            <span className="text-xs text-indigo-500 font-semibold flex items-center">
              <Clock className="w-3 h-3 mr-0.5" /> Cumulative
            </span>
          </div>
          <p className="text-xs text-gray-400 mt-1.5 font-medium">Total logged agent connection time</p>
        </div>

        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm">
          <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Answer Rate (%)</span>
          <div className="flex items-baseline gap-2 mt-2">
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white">
              {loading ? "..." : `${totalCalls > 0 ? Math.round((answered / totalCalls) * 100) : 0}%`}
            </h3>
            <span className="text-xs text-emerald-500 font-semibold flex items-center">
              <PhoneCall className="w-3 h-3 mr-0.5" /> High Quality
            </span>
          </div>
          <p className="text-xs text-gray-400 mt-1.5 font-medium">Percentage of successfully connected calls</p>
        </div>

        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm">
          <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Average Duration</span>
          <div className="flex items-baseline gap-2 mt-2">
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white">{loading ? "..." : `${averageDuration}s`}</h3>
            <span className="text-xs text-purple-500 font-semibold flex items-center">
              <BarChart3 className="w-3 h-3 mr-0.5" /> Regular
            </span>
          </div>
          <p className="text-xs text-gray-400 mt-1.5 font-medium">Average seconds per call log</p>
        </div>
      </div>

      {/* Main Analytics Graphs */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 p-6 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm space-y-4">
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Daily Telemetry Load</h3>
            <p className="text-xs text-gray-400">Visualizing aggregate daily call telemetry flow</p>
          </div>
          <div className="h-72">
            <ReactApexChart options={areaChartOptions} series={areaChartSeries} type="area" height="100%" />
          </div>
        </div>

        <div className="p-6 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex flex-col justify-between">
          <div>
            <h3 className="text-lg font-bold text-gray-900 dark:text-white">Connection Efficiency Ratio</h3>
            <p className="text-xs text-gray-400 mb-4">Proportion of answered to unanswered calls</p>
          </div>
          <div className="h-48 flex items-center justify-center relative">
            {totalCalls > 0 ? (
              <ReactApexChart options={donutChartOptions} series={donutChartSeries} type="donut" height="100%" />
            ) : (
              <span className="text-xs text-gray-400 font-semibold">No active call records</span>
            )}
          </div>
          <div className="flex justify-around border-t border-gray-50 dark:border-gray-800/80 pt-4 text-xs font-semibold">
            <div className="flex items-center gap-1.5 text-indigo-500">
              <span className="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> Answered ({answered})
            </div>
            <div className="flex items-center gap-1.5 text-gray-400">
              <span className="w-2.5 h-2.5 rounded-full bg-gray-200 dark:bg-gray-700"></span> Unanswered ({totalCalls - answered})
            </div>
          </div>
        </div>
      </div>

      {/* Outcome distribution Bar Chart */}
      <div className="p-6 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm space-y-4">
        <div>
          <h3 className="text-lg font-bold text-gray-900 dark:text-white">Detailed Disposition Breakdown</h3>
          <p className="text-xs text-gray-400">Summary count categorized by connection result status</p>
        </div>
        <div className="h-72">
          {totalCalls > 0 ? (
            <ReactApexChart options={barChartOptions} series={barChartSeries} type="bar" height="100%" />
          ) : (
            <div className="h-full flex flex-col items-center justify-center text-gray-400">
              <ShieldAlert className="w-10 h-10 mb-2 text-gray-300 dark:text-gray-700" />
              <span className="text-sm font-semibold">No disposition logs available</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
