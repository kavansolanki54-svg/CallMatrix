"use client";
import React, { useState, useEffect, useCallback } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import Button from "@/components/ui/button/Button";
import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Select from "@/components/form/Select";
import { designationService, companyService } from "@/lib/services";
import { getCompanyIdFromToken, getUserIdFromToken } from "@/lib/auth";
import { apiClient } from "@/lib/apiClient";
import TextArea from "@/components/form/input/TextArea";
import Loader from "@/components/ui/loader/Loader";

interface Designation {
  id: number;
  companyId: number;
  companyName?: string;
  departmentId: number;
  name: string;
  description: string;
  count: number;
}

interface Company {
  companyId: number;
  companyName: string;
}

interface Department {
  id: number;
  name: string;
}

export default function DesignationsPage() {
  const [designations, setDesignations] = useState<Designation[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [name, setName] = useState("");
  const [description, setDescription] = useState("");
  const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null);
  const [selectedDepartmentId, setSelectedDepartmentId] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [tokenCompanyId, setTokenCompanyId] = useState<number | null>(null);

  const fetchDesignations = useCallback(async () => {
    setLoading(true);
    const cid = getCompanyIdFromToken();
    setTokenCompanyId(cid);

    try {
      try {
        const compRes = await companyService.getCompanies();
        if (compRes?.success && Array.isArray(compRes.data)) {
          setCompanies(compRes.data);
        }
      } catch (err) {
        console.warn("Failed to fetch companies list", err);
      }

      try {
        let url = `/departments?search=`;
        if (cid) url += `&companyId=${cid}`;
        const res = await apiClient.get(url);
        if (res.data?.success && Array.isArray(res.data.data)) {
          setDepartments(res.data.data.map((d: any) => ({ 
            id: d.DepartmentId || d.departmentId, 
            name: d.DepartmentName || d.departmentName 
          })));
        }
      } catch (err) {
        console.warn("Failed to fetch departments", err);
      }

      const res = await designationService.getDesignations(1, 100, searchTerm, cid || undefined);
      const resData = (res?.success && Array.isArray(res.data)) ? res.data : (Array.isArray(res) ? res : []);
      const mapped: Designation[] = resData.map((item: any) => ({
        id: item.DesignationId || item.designationId || item.id,
        companyId: item.CompanyId || item.companyId || cid || 1,
        companyName: item.CompanyName || item.companyName || `Company #${item.CompanyId || item.companyId || cid || 1}`,
        departmentId: item.DepartmentId || item.departmentId || 0,
        name: item.DesignationName || item.designationName || item.name || "",
        description: item.Description || item.description || "",
        count: item.EmployeeCount || item.employeeCount || item.count || 0,
      }));
      setDesignations(mapped);
    } catch (err) {
      console.error("Failed to load designations", err);
      setDesignations([]);
    } finally {
      setLoading(false);
    }
  }, [searchTerm]);

  useEffect(() => {
    fetchDesignations();
  }, [fetchDesignations]);

  const handleOpenAdd = () => {
    setEditingId(null);
    setName("");
    setDescription("");
    setSelectedCompanyId(tokenCompanyId || companies[0]?.companyId || null);
    setSelectedDepartmentId(departments[0]?.id || null);
    setShowModal(true);
  };

  const handleOpenEdit = (des: Designation) => {
    setEditingId(des.id);
    setName(des.name);
    setDescription(des.description);
    setSelectedCompanyId(des.companyId);
    setSelectedDepartmentId(des.departmentId);
    setShowModal(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("Are you sure you want to delete this designation?")) {
      try {
        await designationService.deleteDesignation(id);
      } catch (err) {
        console.warn("Delete designation API fallback", err);
      }
      setDesignations((prev) => prev.filter((des) => des.id !== id));
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name) return;

    const cid = selectedCompanyId || tokenCompanyId || companies[0]?.companyId;
    const did = selectedDepartmentId || departments[0]?.id;

    if (!cid) {
      alert("Please select a company.");
      return;
    }
    if (!did) {
      alert("Please select a department.");
      return;
    }

    const payload = {
      designationName: name,
      description: description,
      departmentId: did,
      companyId: cid,
      CreatedBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
      UpdatedBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
      createdBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
      updatedBy: getUserIdFromToken() !== null ? getUserIdFromToken() : 0,
    };

    if (editingId) {
      try {
        await designationService.updateDesignation(editingId, payload);
        await fetchDesignations();
      } catch (err: any) {
        console.warn("Update designation call error fallback", err);
        alert("Failed to update designation.");
      }
    } else {
      try {
        await designationService.createDesignation(payload);
        await fetchDesignations();
      } catch (err: any) {
        console.warn("Create designation call error fallback", err);
        alert("Failed to create designation.");
      }
    }
    setShowModal(false);
  };

  const filteredDesignations = designations.filter((des) => {
    return (
      (des.name || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (des.description || "").toLowerCase().includes(searchTerm.toLowerCase()) ||
      (des.companyName && des.companyName.toLowerCase().includes(searchTerm.toLowerCase()))
    );
  });

  return (
    <div>
      <PageBreadcrumb pageTitle="Designations" />
      <div className="space-y-6">
        <ComponentCard title="Employee Designations" desc="Define title hierarchies and organizational tiers">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
            <div className="w-full sm:w-72">
              <Input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search designations..."
              />
            </div>
            <Button onClick={handleOpenAdd} className="bg-brand-500 hover:bg-brand-600 text-white">
              + Add Designation
            </Button>
          </div>

          <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-200 font-semibold uppercase text-xs">
                <tr>
                  <th className="p-4">Designation Title</th>
                  <th className="p-4">Description</th>
                  <th className="p-4">Department</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={4} className="p-8">
                      <Loader size="md" text="Loading designations..." />
                    </td>
                  </tr>
                ) : filteredDesignations.length > 0 ? (
                  filteredDesignations.map((des) => (
                    <tr key={des.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30">
                      <td className="p-4 font-medium text-gray-900 dark:text-white">{des.name}</td>
                      <td className="p-4 text-gray-500 text-sm truncate max-w-xs" title={des.description}>
                        {des.description || "No description"}
                      </td>
                      <td className="p-4 font-semibold">{departments.find(d => d.id === des.departmentId)?.name || `Dept #${des.departmentId}`}</td>
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <button
                            onClick={() => handleOpenEdit(des)}
                            className="text-sm font-medium text-brand-600 hover:text-brand-700 dark:text-brand-400"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(des.id)}
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
                      No designations found for the current company token context.
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
              {editingId ? "Edit Designation" : "Add Designation"}
            </h3>
            <form onSubmit={handleSave} className="space-y-4">
              <div>
                <Label>Department</Label>
                <Select
                  options={departments.map(dep => ({ value: String(dep.id), label: dep.name }))}
                  defaultValue={String(selectedDepartmentId || (departments.length > 0 ? departments[0]?.id : ""))}
                  onChange={(val) => setSelectedDepartmentId(Number(val))}
                  placeholder={departments.length > 0 ? "Select department" : "No departments available"}
                />
              </div>
              <div>
                <Label>Designation Title</Label>
                <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Regional Account Executive" />
              </div>
              <div>
                <Label>Description</Label>
                <TextArea value={description} onChange={(val) => setDescription(val)} placeholder="e.g. Handles regional accounts" />
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
                  {editingId ? "Update Designation" : "Save Designation"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
