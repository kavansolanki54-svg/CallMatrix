"use client";
import React, { useState, useEffect } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import Button from "@/components/ui/button/Button";
import Input from "@/components/form/input/InputField";
import { apiClient } from "@/lib/services";
import { getCompanyIdFromToken } from "@/lib/auth";

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");

  useEffect(() => {
    const fetchNotifications = async () => {
      setLoading(true);
      const cid = getCompanyIdFromToken();
      try {
        let url = `/notifications?search=${encodeURIComponent(search)}`;
        if (cid) url += `&companyId=${cid}`;
        const res = await apiClient.get(url);
        if (res.data?.success && Array.isArray(res.data.data)) {
          setNotifications(res.data.data);
        } else if (Array.isArray(res.data)) {
          setNotifications(res.data);
        } else {
          setNotifications([]);
        }
      } catch (err) {
        console.warn("Notifications API error fallback", err);
        setNotifications([]);
      } finally {
        setLoading(false);
      }
    };
    fetchNotifications();
  }, [search]);

  return (
    <div>
      <PageBreadcrumb pageTitle="Notifications" />
      <div className="space-y-6">
        <ComponentCard title="System & Company Alerts" desc="View real-time call telemetry and system activity alerts">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
            <div className="w-full sm:w-72">
              <Input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search notifications..."
              />
            </div>
            <Button className="bg-brand-500 hover:bg-brand-600 text-white">
              Mark All as Read
            </Button>
          </div>

          <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-200 font-semibold uppercase text-xs">
                <tr>
                  <th className="p-4">Timestamp</th>
                  <th className="p-4">Category</th>
                  <th className="p-4">Notification Message</th>
                  <th className="p-4">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={4} className="p-6 text-center text-gray-500 dark:text-gray-400">
                      Loading notifications...
                    </td>
                  </tr>
                ) : notifications.length > 0 ? (
                  notifications.map((n, index) => (
                    <tr key={index} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30">
                      <td className="p-4 text-xs font-mono text-gray-400">{n.createdAt || new Date().toLocaleString()}</td>
                      <td className="p-4 font-semibold text-gray-900 dark:text-white">{n.category || "System"}</td>
                      <td className="p-4">{n.message || n.text}</td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                          {n.isRead ? "Read" : "Unread"}
                        </span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="p-6 text-center text-gray-500 dark:text-gray-400">
                      No notifications for current company token context.
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
