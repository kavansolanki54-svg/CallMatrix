"use client";
import React, { useEffect, useState } from "react";
import { roleService } from "@/lib/services";
import { Shield, Save, CheckSquare, Square, ChevronRight, ChevronDown } from "lucide-react";
import Select from "@/components/form/Select";

export default function PermissionsPage() {
  const [roles, setRoles] = useState<any[]>([]);
  const [selectedRole, setSelectedRole] = useState<number>(0);
  const [permissions, setPermissions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [collapsedMenus, setCollapsedMenus] = useState<Record<number, boolean>>({});

  useEffect(() => {
    const fetchRoles = async () => {
      try {
        const res = await roleService.getRoles();
        if (res?.success && Array.isArray(res.data)) {
          setRoles(res.data);
        } else if (Array.isArray(res)) {
          setRoles(res);
        } else {
          setRoles([]);
        }
      } catch (err) {
        console.error("Failed to load roles", err);
        setRoles([]);
      }
    };

    fetchRoles();
  }, []);

  useEffect(() => {
    const fetchPermissions = async () => {
      if (!selectedRole) {
        setLoading(false);
        setPermissions([]);
        return;
      }
      
      setLoading(true);
      try {
        const res = await roleService.getPermissions(selectedRole);
        if (res?.success) {
          if (Array.isArray(res.data)) {
            setPermissions(res.data);
          } else if (res.data?.permissions && Array.isArray(res.data.permissions)) {
            setPermissions(res.data.permissions);
          } else {
            setPermissions([]);
          }
        } else {
          setPermissions([]);
        }
      } catch (err) {
        console.error("Failed to load permissions", err);
        setPermissions([]);
      } finally {
        setLoading(false);
      }
    };

    fetchPermissions();
  }, [selectedRole]);

  const toggleCollapse = (menuId: number) => {
    setCollapsedMenus(prev => ({ ...prev, [menuId]: !prev[menuId] }));
  };

  const togglePermission = (index: number, key: string) => {
    const updated = [...permissions];
    updated[index][key] = !updated[index][key];
    setPermissions(updated);
  };

  const toggleColumnPermission = (key: string) => {
    if (permissions.length === 0) return;
    const allSelected = permissions.every(p => p[key]);
    const updated = permissions.map(p => ({ ...p, [key]: !allSelected }));
    setPermissions(updated);
  };

  const handleSave = async () => {
    try {
      await roleService.updatePermissions({ roleId: selectedRole, permissions });
      alert("Role permissions saved successfully!");
    } catch (err) {
      console.error("Failed to save permissions", err);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Role & Menu Permissions</h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Configure access rights per system role</p>
        </div>
        <button
          onClick={handleSave}
          disabled={!selectedRole}
          className={`inline-flex items-center gap-2 px-4 py-2 text-white rounded-lg font-medium text-sm transition shadow-sm ${
            !selectedRole ? "bg-gray-400 cursor-not-allowed opacity-70" : "bg-brand-500 hover:bg-brand-600"
          }`}
        >
          <Save className="w-4 h-4" /> Save Permissions
        </button>
      </div>

      {/* Role Selection Dropdown */}
      <div className="bg-white dark:bg-gray-900 p-4 rounded-xl border border-gray-100 dark:border-gray-800 shadow-sm flex items-center gap-4">
        <label className="text-sm font-semibold text-gray-700 dark:text-gray-300 min-w-max">
          Select Role:
        </label>
        <div className="w-full md:w-80">
          <Select
            options={roles.map(r => ({ value: String(r.roleId), label: r.roleName }))}
            defaultValue={selectedRole ? String(selectedRole) : ""}
            onChange={(val) => setSelectedRole(Number(val))}
          />
        </div>
      </div>

      {/* Permission Matrix */}
      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden shadow-sm">
        <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
          <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-400 font-semibold uppercase text-xs">
            <tr>
              <th className="px-6 py-4">Menu / Feature</th>
              {[
                { key: "canView", label: "View" },
                { key: "canAdd", label: "Create" },
                { key: "canEdit", label: "Edit" },
                { key: "canDelete", label: "Delete" },
                { key: "canPrint", label: "Print" },
                { key: "canApprove", label: "Approve" }
              ].map(({ key, label }) => {
                const allSelected = permissions.length > 0 && permissions.every(p => p[key]);
                return (
                  <th key={key} className="px-6 py-4 text-center">
                    <div className="flex items-center justify-center gap-2">
                      <span>{label}</span>
                      <button
                        onClick={() => toggleColumnPermission(key)}
                        className="text-brand-600 dark:text-brand-400 hover:scale-110 transition"
                        title={`Select all ${label}`}
                      >
                        {allSelected ? <CheckSquare className="w-4 h-4" /> : <Square className="w-4 h-4 text-gray-300 dark:text-gray-700" />}
                      </button>
                    </div>
                  </th>
                );
              })}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {!selectedRole ? (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center text-gray-500 dark:text-gray-400 bg-gray-50/50 dark:bg-gray-800/30">
                  Please select a role to view or edit permissions.
                </td>
              </tr>
            ) : loading ? (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center text-gray-400">Loading matrix...</td>
              </tr>
            ) : Array.isArray(permissions) && permissions.length > 0 ? (
              (function renderTree(parentId: any = null, level = 0): React.ReactNode {
                const children = permissions.filter((p) => (p.parentId || null) === parentId);
                if (children.length === 0) return null;

                return children.map((perm) => {
                  const originalIndex = permissions.findIndex(p => p.menuId === perm.menuId);
                  const hasChildren = permissions.some(p => p.parentId === perm.menuId);
                  const isCollapsed = collapsedMenus[perm.menuId];
                  
                  return (
                    <React.Fragment key={perm.menuId}>
                      <tr className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition border-t border-gray-50 dark:border-gray-800/50">
                        <td className="px-6 py-4 font-semibold text-gray-900 dark:text-white flex items-center gap-2" style={{ paddingLeft: `${(level * 1.5) + 1.5}rem` }}>
                          {hasChildren ? (
                            <button 
                              onClick={() => toggleCollapse(perm.menuId)}
                              className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition"
                            >
                              {isCollapsed ? <ChevronRight className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                            </button>
                          ) : (
                            <span className="w-4 h-4 inline-block" />
                          )}
                          {perm.menuName}
                        </td>
                        {["canView", "canAdd", "canEdit", "canDelete", "canPrint", "canApprove"].map((key) => (
                          <td key={key} className="px-6 py-4 text-center">
                            <button
                              onClick={() => togglePermission(originalIndex, key)}
                              className="text-brand-600 dark:text-brand-400 hover:scale-110 transition"
                            >
                              {permissions[originalIndex][key] ? <CheckSquare className="w-5 h-5" /> : <Square className="w-5 h-5 text-gray-300 dark:text-gray-700" />}
                            </button>
                          </td>
                        ))}
                      </tr>
                      {!isCollapsed && renderTree(perm.menuId, level + 1)}
                    </React.Fragment>
                  );
                });
              })()
            ) : (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center text-gray-400">No permissions found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
