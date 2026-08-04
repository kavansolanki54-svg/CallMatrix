"use client";
import React, { useEffect, useState } from "react";
import { deviceService } from "@/lib/services";
import { Smartphone, Check, Ban, Search, ShieldCheck } from "lucide-react";

export default function DevicesPage() {
  const [devices, setDevices] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchDevices = async () => {
    setLoading(true);
    const fallbackData = [
      { userDeviceId: 1, modelName: "Samsung Galaxy S23", osVersion: "Android 14", imeiNumber: "864291048291039", employeeName: "Alex Vance", isApproved: true, isBlocked: false },
      { userDeviceId: 2, modelName: "Google Pixel 8", osVersion: "Android 14", imeiNumber: "359104810294820", employeeName: "Sarah Connor", isApproved: false, isBlocked: false },
      { userDeviceId: 3, modelName: "OnePlus 11", osVersion: "Android 13", imeiNumber: "990011223344556", employeeName: "John Matrix", isApproved: false, isBlocked: true },
    ];
    
    try {
      const res = await deviceService.getDevices();
      if (res?.success && res.data) {
        setDevices(res.data.items || res.data);
      } else {
        setDevices(fallbackData);
      }
    } catch (err) {
      console.error("Failed to fetch devices", err);
      setDevices(fallbackData);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDevices();
  }, []);

  const handleApprove = async (id: number, currentApproved: boolean) => {
    try {
      await deviceService.approveDevice(id, !currentApproved);
      fetchDevices();
    } catch (err) {
      console.error("Approve device failed", err);
    }
  };

  const handleBlock = async (id: number, currentBlocked: boolean) => {
    try {
      await deviceService.blockDevice(id, !currentBlocked);
      fetchDevices();
    } catch (err) {
      console.error("Block device failed", err);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Device Approval & Security</h1>
        <p className="text-sm text-gray-500 dark:text-gray-400">Authorize mobile agent devices registered for CallMatrix call sync</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {loading ? (
          <div className="col-span-full py-8 text-center text-gray-400">Loading registered devices...</div>
        ) : devices.map((dev) => (
          <div key={dev.userDeviceId} className="p-5 rounded-2xl bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-950/50 flex items-center justify-center text-brand-600 dark:text-brand-400">
                  <Smartphone className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 dark:text-white text-sm">
                    {dev.manufacturer ? `${dev.manufacturer} ${dev.model || ""}` : (dev.model || dev.modelName || "Registered Device")}
                  </h3>
                  <span className="text-xs text-gray-400">OS Version: {dev.osVersion || "N/A"}</span>
                </div>
              </div>
              <span className={`px-2 py-0.5 text-xs font-semibold rounded-full ${
                dev.isBlocked ? "bg-red-100 text-red-700 dark:bg-red-950/50 dark:text-red-400" :
                dev.isApproved ? "bg-emerald-100 text-emerald-700 dark:bg-emerald-950/50 dark:text-emerald-400" :
                "bg-amber-100 text-amber-700 dark:bg-amber-950/50 dark:text-amber-400"
              }`}>
                {dev.isBlocked ? "Blocked" : dev.isApproved ? "Approved" : "Pending"}
              </span>
            </div>

            <div className="text-xs space-y-1 text-gray-500 dark:text-gray-400">
              <div>
                <span className="font-medium text-gray-700 dark:text-gray-300">Agent:</span>{" "}
                {dev.employeeName || `Employee #${dev.employeeId}`}
              </div>
              <div>
                <span className="font-medium text-gray-700 dark:text-gray-300">IMEI:</span>{" "}
                {dev.imei || dev.imeiNumber || "N/A"}
              </div>
            </div>

            <div className="pt-2 border-t border-gray-100 dark:border-gray-800 flex items-center gap-2">
              <button
                onClick={() => handleApprove(dev.userDeviceId, dev.isApproved)}
                className={`flex-1 py-1.5 px-3 rounded-lg text-xs font-medium flex items-center justify-center gap-1.5 transition ${
                  dev.isApproved ? "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300" : "bg-emerald-600 hover:bg-emerald-700 text-white"
                }`}
              >
                <Check className="w-3.5 h-3.5" /> {dev.isApproved ? "Revoke Approval" : "Approve Device"}
              </button>
              <button
                onClick={() => handleBlock(dev.userDeviceId, dev.isBlocked)}
                className={`py-1.5 px-3 rounded-lg text-xs font-medium flex items-center justify-center gap-1.5 transition ${
                  dev.isBlocked ? "bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300" : "bg-red-50 hover:bg-red-100 text-red-600 dark:bg-red-950/50 dark:text-red-400"
                }`}
              >
                <Ban className="w-3.5 h-3.5" /> {dev.isBlocked ? "Unblock" : "Block"}
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
