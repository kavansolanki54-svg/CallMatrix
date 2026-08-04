"use client";
import React, { useState, useEffect, useCallback } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import Button from "@/components/ui/button/Button";
import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Select from "@/components/form/Select";
import { departmentService, companyService } from "@/lib/services";
import Loader from "@/components/ui/loader/Loader";
import { getCompanyIdFromToken, getUserIdFromToken } from "@/lib/auth";
import { useAlert } from "@/context/AlertContext";

interface Department {
  id: number;
  companyId: number;
  companyName?: string;
  name: string;
  code: string;
  head: string;
  count: number;
  status: string;
}

interface Company {
  companyId: number;
  companyName: string;
}

export default function DepartmentsPage() {
  const [departments, setDepartments] = useState<Department[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const { showAlert } = useAlert();

  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [tokenCompanyId, setTokenCompanyId] = useState<number | null>(null);

  const fetchDepartments = useCallback(async () => {
    setLoading(true);
    const cid = getCompanyIdFromToken();
    setTokenCompanyId(cid);

    try {
      // Fetch companies
      try {
        const compRes = await companyService.getCompanies();
        if (compRes?.success && Array.isArray(compRes.data)) {
          setCompanies(compRes.data);
        }
      } catch (err) {
        console.warn("Failed to fetch companies list", err);
      }

      // Fetch departments for companyId extracted from token
      const res = await departmentService.getDepartments(1, 100, searchTerm, cid || undefined);
      const resData = (res?.success && Array.isArray(res.data)) ? res.data : (Array.isArray(res) ? res : []);
      const mapped: Department[] = resData.map((item: any) => ({
        id: item.DepartmentId || item.departmentId || item.id,
        companyId: item.CompanyId || item.companyId || cid || (companies[0]?.companyId ?? null),
        companyName: item.CompanyName || item.companyName || (companies.find(c => c.companyId === (item.CompanyId || item.companyId || cid))?.companyName) || `Company #${item.CompanyId || item.companyId || cid}`,
        name: item.DepartmentName || item.departmentName || item.name || "",
        code: item.DepartmentCode || item.departmentCode || item.code || `DEP-${item.DepartmentId || item.departmentId || item.id}`,
        head: item.Head || item.head || item.managerName || "Unassigned",
        count: item.EmployeeCount || item.employeeCount || item.count || 0,
        status: (item.IsActive ?? item.isActive) !== false ? "Active" : "Inactive",
      }));
      setDepartments(mapped);
    } catch (err) {
      console.error("Failed to load departments", err);
      setDepartments([]);
    } finally {
      setLoading(false);
    }
  }, [searchTerm]);

  useEffect(() => {
    fetchDepartments();
  }, [fetchDepartments]);

  const handleOpenAdd = () => {
    setEditingId(null);
    setName("");
    setCode("");
    setSelectedCompanyId(tokenCompanyId || companies[0]?.companyId || null);
    setShowModal(true);
  };

  const handleOpenEdit = (dep: Department) => {
    setEditingId(dep.id);
    setName(dep.name);
    setCode(dep.code);
    setSelectedCompanyId(dep.companyId);
    setShowModal(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("Are you sure you want to delete this department?")) {
      try {
        await departmentService.deleteDepartment(id);
      } catch (err) {
        console.warn("Delete department API fallback", err);
      }
      setDepartments((prev) => prev.filter((dep) => dep.id !== id));
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;

    const cid = selectedCompanyId || tokenCompanyId || companies[0]?.companyId;
    if (!cid) {
      showAlert("warning", "Warning", "Please select a company.");
      return;
    }

    const payload = {
      departmentName: name,
      departmentCode: code,
      companyId: cid,
      CreatedBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
      UpdatedBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
      createdBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
      updatedBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
    };

    if (editingId) {
      try {
        await departmentService.updateDepartment(editingId, payload);
        await fetchDepartments();
        showAlert("success", "Success", "Department updated successfully!");
      } catch (err: any) {
        console.warn("Update department call error fallback", err);
        showAlert("error", "Error", "Failed to update department.");
      }
    } else {
      try {
        await departmentService.createDepartment(payload);
        await fetchDepartments();
        showAlert("success", "Success", "Department created successfully!");
      } catch (err: any) {
        console.warn("Create department call error fallback", err);
        showAlert("error", "Error", "Failed to create department.");
      }
    }
    setShowModal(false);
  };

  const filteredDepartments = departments.filter((dep) => {
    return (
      (dep.name || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (dep.code || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (dep.companyName && dep.companyName.toLowerCase().includes(searchTerm.toLowerCase()))
    );
  });

  return (
    <div>
      <PageBreadcrumb pageTitle="Departments" />
      <div className="space-y-6">
        <ComponentCard title="Company Departments" desc="Configure business units and organizational structures">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
            <div className="w-full sm:w-72">
              <Input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search departments..."
              />
            </div>
            <Button onClick={handleOpenAdd} className="bg-brand-500 hover:bg-brand-600 text-white">
              + Add Department
            </Button>
          </div>

          <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-200 font-semibold uppercase text-xs">
                <tr>
                  <th className="p-4">Code</th>
                  <th className="p-4">Department Name</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={4} className="p-8">
                      <Loader size="md" text="Loading departments..." />
                    </td>
                  </tr>
                ) : filteredDepartments.length > 0 ? (
                  filteredDepartments.map((dep) => (
                    <tr key={dep.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30">
                      <td className="p-4 font-mono font-semibold text-brand-600 dark:text-brand-400">{dep.code}</td>
                      <td className="p-4 font-medium text-gray-900 dark:text-white">{dep.name}</td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                          {dep.status}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <button
                            onClick={() => handleOpenEdit(dep)}
                            className="text-sm font-medium text-brand-600 hover:text-brand-700 dark:text-brand-400"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(dep.id)}
                            className="text-sm font-medium text-red-600 hover:text-red-700 dark:text-red-400"
                          >
                            Delete
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan={4} className="p-6 text-center text-gray-500 dark:text-gray-400">
                      No departments found for the current company token context.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </ComponentCard>
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 w-full max-w-md border border-gray-200 dark:border-gray-800 shadow-xl">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              {editingId ? "Edit Department" : "Add Department"}
            </h3>
            <form onSubmit={handleSave} className="space-y-4">
              <div>
                <Label>Department Name</Label>
                <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Quality Assurance" />
              </div>
              <div>
                <Label>Department Code</Label>
                <Input value={code} onChange={(e) => setCode(e.target.value)} placeholder="e.g. DEP-QA" />
              </div>
              {companies.length > 0 && (
                <div>
                  <Label>Company</Label>
                  <Select
                    options={companies.map(comp => ({ value: String(comp.companyId), label: comp.companyName }))}
                    defaultValue={String(selectedCompanyId || tokenCompanyId || companies[0]?.companyId || "")}
                    onChange={(val) => setSelectedCompanyId(Number(val))}
                  />
                </div>
              )}
              <div className="flex justify-end gap-3 pt-3">
                <Button type="button" onClick={() => setShowModal(false)} variant="outline">
                  Cancel
                </Button>
                <Button type="submit" className="bg-brand-500 hover:bg-brand-600 text-white">
                  {editingId ? "Update Department" : "Save Department"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
