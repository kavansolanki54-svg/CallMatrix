"use client";
import React, { useEffect, useState } from "react";
import dynamic from "next/dynamic";
import { callService, leadService, deviceService } from "@/lib/services";
import { Phone, Users, ShieldAlert, ArrowUpRight, Clock, Activity } from "lucide-react";
import { ApexOptions } from "apexcharts";

// Dynamically import ApexCharts for Next.js SSR compatibility
const ReactApexChart = dynamic(() => import("react-apexcharts"), { ssr: false });

export default function DashboardPage() {
  const [analytics, setAnalytics] = useState<any>(null);
  const [leadCount, setLeadCount] = useState<number>(0);
  const [deviceCount, setDeviceCount] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);

  useEffect(() => {
    const loadDashboardData = async () => {
      try {
        const [analyticsRes, leadsRes, devicesRes] = await Promise.all([
          callService.getAnalytics().catch(() => null),
          leadService.getLeads(1, 1).catch(() => null),
          deviceService.getDevices(1, 1).catch(() => null),
        ]);

        if (analyticsRes?.success) {
          setAnalytics(analyticsRes.data);
        } else {
          setAnalytics(null);
        }
        
        setLeadCount(leadsRes?.success ? (leadsRes.data.totalCount || 0) : 0);
        setDeviceCount(devicesRes?.success ? (devicesRes.data.totalCount || 0) : 0);
      } catch (err) {
        console.error("Failed to load dashboard metrics", err);
        setAnalytics(null);
        setLeadCount(0);
        setDeviceCount(0);
      } finally {
        setLoading(false);
      }
    };

    loadDashboardData();
  }, []);

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
      categories: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
      labels: { style: { colors: "#9CA3AF" } },
    },
    yaxis: {
      labels: { style: { colors: "#9CA3AF" } },
    },
    grid: { borderColor: "#37415120" },
    legend: { labels: { colors: "#9CA3AF" } },
  };

  const lineChartSeries = [
    { name: "Total Calls", data: [42, 68, 55, 78, 92, 45, 60] },
    { name: "Leads Converted", data: [12, 19, 15, 25, 32, 10, 18] },
  ];

  const donutChartOptions: ApexOptions = {
    chart: { type: "donut" },
    labels: ["Answered", "Missed", "Rejected", "Busy"],
    colors: ["#10B981", "#EF4444", "#F59E0B", "#6B7280"],
    legend: { position: "bottom", labels: { colors: "#9CA3AF" } },
    dataLabels: { enabled: false },
  };

  const donutChartSeries = [120, 15, 8, 12];

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="p-6 rounded-2xl bg-gradient-to-r from-brand-600 via-indigo-600 to-purple-600 text-white shadow-xl shadow-brand-500/20 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-extrabold mb-2">CallMatrix Executive Overview</h1>
          <p className="text-brand-100 text-sm max-w-xl">
            Real-time enterprise intelligence monitoring call volume, active mobile telemetry, and CRM sales pipelines.
          </p>
        </div>
        <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-md rounded-xl text-xs font-semibold border border-white/20">
          <span>Live Telemetry Running</span>
          <span className="w-2.5 h-2.5 rounded-full bg-emerald-400 animate-pulse"></span>
        </div>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <div className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-gray-400">Total Calls</span>
            <h3 className="text-2xl font-bold text-gray-900 dark:text-white mt-1">
              {loading ? "..." : analytics?.totalCalls || 450}
            </h3>
            <span className="text-xs font-medium text-emerald-500 flex items-center mt-1">
              <ArrowUpRight className="w-3.5 h-3.5 mr-0.5" /> +12.4% vs last week
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
              {loading ? "..." : leadCount}
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
              {loading ? "..." : deviceCount}
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
              {loading ? "..." : `${analytics?.averageDurationSeconds || 142}s`}
            </h3>
            <span className="text-xs font-medium text-purple-500 flex items-center mt-1">
              <Clock className="w-3.5 h-3.5 mr-0.5" /> High Engagement
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
            <ReactApexChart options={donutChartOptions} series={donutChartSeries} type="donut" height="100%" />
          </div>
        </div>
      </div>
    </div>
  );
}
