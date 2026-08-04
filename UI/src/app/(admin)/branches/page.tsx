"use client";
import React, { useState, useEffect, useCallback } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import Button from "@/components/ui/button/Button";
import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Select from "@/components/form/Select";
import TextArea from "@/components/form/input/TextArea";
import { companyService, apiClient } from "@/lib/services";
import { getCompanyIdFromToken } from "@/lib/auth";
import Loader from "@/components/ui/loader/Loader";
import { useAlert } from "@/context/AlertContext";

interface Branch {
  id: number;
  companyId: number;
  companyName?: string;
  name: string;
  code: string;
  address: string;
  country: string;
  state: string;
  city: string;
  pincode: string;
  phone: string;
  email: string;
  status: string;
}

interface Company {
  companyId: number;
  companyName: string;
}

export default function BranchesPage() {
  const [branches, setBranches] = useState<Branch[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const { showAlert } = useAlert();

  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [name, setName] = useState("");
  const [code, setCode] = useState("");
  const [address, setAddress] = useState("");
  const [country, setCountry] = useState("");
  const [branchState, setBranchState] = useState("");
  const [city, setCity] = useState("");
  const [pincode, setPincode] = useState("");
  const [phone, setPhone] = useState("");
  const [email, setEmail] = useState("");
  const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [tokenCompanyId, setTokenCompanyId] = useState<number | null>(null);

  const fetchBranches = useCallback(async () => {
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
        console.warn("Failed to fetch companies", err);
      }

      let url = `/branches?search=${encodeURIComponent(searchTerm)}`;
      if (cid) url += `&companyId=${cid}`;

      let resData: any[] = [];
      try {
        const res = await apiClient.get(url);
        if (res.data?.success && Array.isArray(res.data.data)) {
          resData = res.data.data;
        } else if (Array.isArray(res.data)) {
          resData = res.data;
        }
      } catch (e) {
        console.warn("Branches endpoint 404/error fallback", e);
      }

      const mapped: Branch[] = resData.map((item: any) => ({
        id: item.BranchId || item.branchId || item.id,
        companyId: item.CompanyId || item.companyId || cid || (companies[0]?.companyId ?? null),
        companyName: item.CompanyName || item.companyName || (companies.find(c => c.companyId === (item.CompanyId || item.companyId || cid))?.companyName) || `Company #${item.CompanyId || item.companyId || cid}`,
        name: item.BranchName || item.branchName || item.name || "",
        code: item.BranchCode || item.branchCode || item.code || `BR-${item.BranchId || item.branchId || item.id}`,
        address: item.Address || item.address || "",
        country: item.Country || item.country || "",
        state: item.State || item.state || "",
        city: item.City || item.city || "",
        pincode: item.Pincode || item.pincode || "",
        phone: item.Phone || item.phone || "",
        email: item.Email || item.email || "",
        status: (item.IsActive ?? item.isActive) !== false ? "Active" : "Inactive",
      }));

      setBranches(mapped);
    } catch (err) {
      console.error("Failed to load branches", err);
      setBranches([]);
    } finally {
      setLoading(false);
    }
  }, [searchTerm]);

  useEffect(() => {
    fetchBranches();
  }, [fetchBranches]);

  const handleOpenAdd = () => {
    setEditingId(null);
    setName("");
    setCode("");
    setAddress("");
    setCountry("");
    setBranchState("");
    setCity("");
    setPincode("");
    setPhone("");
    setEmail("");
    setSelectedCompanyId(tokenCompanyId || companies[0]?.companyId || null);
    setShowModal(true);
  };

  const handleOpenEdit = (b: Branch) => {
    setEditingId(b.id);
    setName(b.name);
    setCode(b.code);
    setAddress(b.address);
    setCountry(b.country);
    setBranchState(b.state);
    setCity(b.city);
    setPincode(b.pincode);
    setPhone(b.phone);
    setEmail(b.email);
    setSelectedCompanyId(b.companyId);
    setShowModal(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("Are you sure you want to delete this branch?")) {
      try {
        await apiClient.delete(`/branches/${id}`);
      } catch (e) {
        console.warn("Delete branch API fallback", e);
      }
      setBranches((prev) => prev.filter((b) => b.id !== id));
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
      branchName: name,
      branchCode: code,
      address,
      country,
      state: branchState,
      city,
      pincode,
      phone,
      email,
      companyId: cid,
    };

    if (editingId) {
      try {
        await apiClient.put(`/branches/${editingId}`, payload);
        await fetchBranches();
        showAlert("success", "Success", "Branch updated successfully!");
      } catch (err: any) {
        console.warn("Update branch call error", err);
        showAlert("error", "Error", "Failed to update branch.");
      }
    } else {
      try {
        await apiClient.post("/branches", payload);
        await fetchBranches();
        showAlert("success", "Success", "Branch created successfully!");
      } catch (err: any) {
        console.warn("Create branch call error", err);
        showAlert("error", "Error", "Failed to create branch.");
      }
    }
    setShowModal(false);
  };

  const filteredBranches = branches.filter((b) => {
    return (
      b.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      b.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      b.city.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (b.companyName && b.companyName.toLowerCase().includes(searchTerm.toLowerCase()))
    );
  });

  return (
    <div>
      <PageBreadcrumb pageTitle="Branch Management" />
      <div className="space-y-6">
        <ComponentCard title="Branch Office Directory" desc="Manage corporate locations and regional branches">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
            <div className="w-full sm:w-72">
              <Input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search branches..."
              />
            </div>
            <Button onClick={handleOpenAdd} className="bg-brand-500 hover:bg-brand-600 text-white">
              + Add Branch
            </Button>
          </div>

          <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-200 font-semibold uppercase text-xs">
                <tr>
                  <th className="p-4">Code</th>
                  <th className="p-4">Branch Name</th>
                  <th className="p-4">Address / Location</th>
                  <th className="p-4">Contact Info</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="p-8">
                      <Loader size="md" text="Loading branches..." />
                    </td>
                  </tr>
                ) : filteredBranches.length > 0 ? (
                  filteredBranches.map((b) => (
                    <tr key={b.id} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30">
                      <td className="p-4 font-mono font-semibold text-brand-600 dark:text-brand-400">{b.code}</td>
                      <td className="p-4 font-medium text-gray-900 dark:text-white">{b.name}</td>
                      <td className="p-4">
                        <div className="font-medium text-gray-900 dark:text-white">{b.address || "N/A"}</div>
                        {b.city || b.state || b.pincode || b.country ? (
                          <div className="text-xs text-gray-500">
                            {[b.city, b.state, b.pincode, b.country].filter(Boolean).join(", ")}
                          </div>
                        ) : null}
                      </td>
                      <td className="p-4">
                        <div className="font-medium text-gray-900 dark:text-white">{b.phone || "N/A"}</div>
                        <div className="text-xs text-gray-500">{b.email || "N/A"}</div>
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                          {b.status}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <button
                            onClick={() => handleOpenEdit(b)}
                            className="text-sm font-medium text-brand-600 hover:text-brand-700 dark:text-brand-400"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(b.id)}
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
                    <td colSpan={6} className="p-6 text-center text-gray-500 dark:text-gray-400">
                      No branches found for the current company token context.
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
          <div className="bg-white dark:bg-gray-900 rounded-2xl p-6 w-full max-w-2xl border border-gray-200 dark:border-gray-800 shadow-xl">
            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
              {editingId ? "Edit Branch" : "Add New Branch"}
            </h3>
            <form onSubmit={handleSave} className="space-y-4 max-h-[80vh] overflow-y-auto pr-2">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Branch Name</Label>
                  <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Metro Tech Hub" />
                </div>
                <div>
                  <Label>Branch Code</Label>
                  <Input value={code} onChange={(e) => setCode(e.target.value)} placeholder="e.g. BR-001" />
                </div>
              </div>

              <div>
                <Label>Address</Label>
                <TextArea value={address} onChange={(val) => setAddress(val)} placeholder="e.g. 123 Business Rd" />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Country</Label>
                  <Input value={country} onChange={(e) => setCountry(e.target.value)} placeholder="e.g. USA" />
                </div>
                <div>
                  <Label>State</Label>
                  <Input value={branchState} onChange={(e) => setBranchState(e.target.value)} placeholder="e.g. NY" />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>City</Label>
                  <Input value={city} onChange={(e) => setCity(e.target.value)} placeholder="e.g. New York" />
                </div>
                <div>
                  <Label>Pincode</Label>
                  <Input value={pincode} onChange={(e) => setPincode(e.target.value)} placeholder="e.g. 10001" />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Contact Phone</Label>
                  <Input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="e.g. +1-555-0100" />
                </div>
                <div>
                  <Label>Email</Label>
                  <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="e.g. branch@corp.com" />
                </div>
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
                  {editingId ? "Update Branch" : "Save Branch"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
