"use client";
import React, { useState, useEffect, useCallback } from "react";
import ComponentCard from "@/components/common/ComponentCard";
import PageBreadcrumb from "@/components/common/PageBreadCrumb";
import Button from "@/components/ui/button/Button";
import Input from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Select from "@/components/form/Select";
import MultiSelect from "@/components/form/MultiSelect";
import { employeeService, companyService, apiClient, departmentService, roleService, designationService } from "@/lib/services";
import Loader from "@/components/ui/loader/Loader";
import { getCompanyIdFromToken } from "@/lib/auth";
import { useAlert } from "@/context/AlertContext";

interface Employee {
  id: number;
  companyId: number;
  code: string;
  firstName: string;
  middleName: string;
  lastName: string;
  name: string;
  email: string;
  phone?: string;
  companyName?: string;
  roleId?: number | null;
  roleName?: string;
  departmentId?: number | null;
  departmentName?: string;
  designationId?: number | null;
  designationName?: string;
  branches?: string[];
  status?: string;
}

interface Company {
  companyId: number;
  companyName: string;
  companyCode?: string;
}

export default function EmployeesPage() {
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const { showAlert } = useAlert();

  const [showModal, setShowModal] = useState(false);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [firstName, setFirstName] = useState("");
  const [middleName, setMiddleName] = useState("");
  const [lastName, setLastName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [password, setPassword] = useState("");
  const [selectedCompanyId, setSelectedCompanyId] = useState<number | null>(null);
  const [selectedRoleId, setSelectedRoleId] = useState<number | null>(null);
  const [selectedDepartmentId, setSelectedDepartmentId] = useState<number | null>(null);
  const [selectedDesignationId, setSelectedDesignationId] = useState<number | null>(null);
  const [selectedBranches, setSelectedBranches] = useState<string[]>([]);
  
  const [branchOptions, setBranchOptions] = useState<{ value: string, text: string, selected: boolean }[]>([]);
  const [departmentOptions, setDepartmentOptions] = useState<{ value: string, label: string }[]>([]);
  const [designationOptions, setDesignationOptions] = useState<{ value: string, label: string }[]>([]);
  const [roleOptions, setRoleOptions] = useState<{ value: string, label: string }[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [tokenCompanyId, setTokenCompanyId] = useState<number | null>(null);

  const fetchData = useCallback(async () => {
    setLoading(true);
    const cid = getCompanyIdFromToken();
    setTokenCompanyId(cid);

    try {
      let companyList: Company[] = [];
      try {
        const compRes = await companyService.getCompanies();
        if (compRes?.success && Array.isArray(compRes.data)) {
          companyList = compRes.data;
          setCompanies(companyList);
        }
      } catch (err) {
        console.warn("Failed to load companies", err);
      }

      try {
        const brRes = await apiClient.get(cid ? `/branches?companyId=${cid}` : `/branches`);
        let bList: any[] = [];
        if (brRes.data?.success && Array.isArray(brRes.data.data)) {
          bList = brRes.data.data;
        } else if (Array.isArray(brRes.data)) {
          bList = brRes.data;
        }
        setBranchOptions(bList.map(b => {
          const name = b.branchName || b.name || `Branch #${b.branchId || b.id}`;
          return { value: String(b.branchId || b.id), text: name, selected: false };
        }));
      } catch (err) {
        console.warn("Failed to load branches", err);
      }

      try {
        const depRes = await departmentService.getDepartments(1, 100, '', cid || undefined);
        let dList: any[] = [];
        if (depRes?.success && Array.isArray(depRes.data)) dList = depRes.data;
        else if (Array.isArray(depRes)) dList = depRes;

        setDepartmentOptions(dList.map(d => {
          const name = d.departmentName || d.name || `Dept #${d.departmentId || d.id}`;
          return { value: String(d.departmentId || d.id), label: name };
        }));
      } catch (err) {
        console.warn("Failed to load departments", err);
      }

      try {
        const desRes = await designationService.getDesignations(1, 100, '', cid || undefined);
        let desList: any[] = [];
        if (desRes?.success && Array.isArray(desRes.data)) desList = desRes.data;
        else if (Array.isArray(desRes)) desList = desRes;

        setDesignationOptions(desList.map(des => {
          const name = des.designationName || des.name || `Designation #${des.designationId || des.id}`;
          return { value: String(des.designationId || des.id), label: name };
        }));
      } catch (err) {
        console.warn("Failed to load designations", err);
      }

      try {
        const rolRes = await roleService.getRoles();
        let rList: any[] = [];
        if (rolRes?.success && Array.isArray(rolRes.data)) rList = rolRes.data;
        else if (Array.isArray(rolRes)) rList = rolRes;

        setRoleOptions(rList.map(r => {
          const name = r.roleName || r.name || `Role #${r.roleId || r.id}`;
          return { value: String(r.roleId || r.id), label: name };
        }));
      } catch (err) {
        console.warn("Failed to load roles", err);
      }

      // Fetch employees for the token's companyId
      const empRes = await employeeService.getEmployees(1, 100, searchTerm, cid || undefined);
      
      let empList: any[] = [];
      if (empRes?.success) {
        if (empRes.data && Array.isArray(empRes.data.items)) {
          empList = empRes.data.items;
        } else if (Array.isArray(empRes.data)) {
          empList = empRes.data;
        }
      } else if (Array.isArray(empRes)) {
        empList = empRes;
      }

      // Filter out Tenant owners (where Tenant is 1 or true) to display only Tenant = 0
      const subEmployees = empList.filter((item: any) => {
        const isTenantOwner = item.Tenant === 1 || item.Tenant === true || item.tenant === 1 || item.tenant === true;
        return !isTenantOwner;
      });

      if (subEmployees.length > 0) {
        const mappedEmps: Employee[] = subEmployees.map((item: any) => ({
          id: item.employeeId || item.id,
          companyId: item.companyId || cid || 1,
          code: item.employeeCode || item.code || `EMP-${item.employeeId || item.id}`,
          firstName: item.firstName || item.FirstName || "",
          middleName: item.middleName || item.MiddleName || "",
          lastName: item.lastName || item.LastName || "",
          name: item.employeeName || item.EmployeeName || `${item.firstName || ''} ${item.lastName || ''}`.trim(),
          email: item.email,
          phone: item.phone || item.mobileNo || item.Phone || '',
          companyName: item.companyName || companyList.find(c => c.companyId === item.companyId)?.companyName || `Company #${item.companyId || cid || 1}`,
          roleId: item.roleId || item.RoleId || null,
          roleName: item.roleName || item.role || 'Employee',
          departmentId: item.departmentId || item.DepartmentId || null,
          departmentName: item.departmentName || item.department || 'General',
          designationId: item.designationId || item.DesignationId || null,
          designationName: item.designationName || item.designation || 'None',
          branches: Array.isArray(item.assignedBranchIds) ? item.assignedBranchIds.map(String) : (item.branches || []),
          status: item.isActive !== false ? 'Active' : 'Inactive',
        }));
        setEmployees(mappedEmps);
      } else {
        setEmployees([]);
      }
    } catch (error) {
      console.error("Failed to fetch employees from API", error);
      setEmployees([]);
    } finally {
      setLoading(false);
    }
  }, [searchTerm]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleOpenAdd = () => {
    setEditingId(null);
    setFirstName("");
    setMiddleName("");
    setLastName("");
    setEmail("");
    setPhone("");
    setCode(`EMP-${Math.floor(1000 + Math.random() * 9000)}`);
    setPassword("");
    setSelectedCompanyId(tokenCompanyId || companies[0]?.companyId || null);
    setSelectedRoleId(roleOptions[0] ? Number(roleOptions[0].value) : null);
    setSelectedDepartmentId(departmentOptions[0] ? Number(departmentOptions[0].value) : null);
    setSelectedDesignationId(designationOptions[0] ? Number(designationOptions[0].value) : null);
    setSelectedBranches([]);
    setShowModal(true);
  };

  const handleOpenEdit = (emp: Employee) => {
    setEditingId(emp.id);
    setFirstName(emp.firstName);
    setMiddleName(emp.middleName);
    setLastName(emp.lastName);
    setEmail(emp.email);
    setPhone(emp.phone || "");
    setCode(emp.code);
    setPassword("");
    setSelectedCompanyId(emp.companyId);
    setSelectedRoleId(emp.roleId || null);
    setSelectedDepartmentId(emp.departmentId || null);
    setSelectedDesignationId(emp.designationId || null);
    setSelectedBranches(emp.branches || []);
    setShowModal(true);
  };

  const handleDelete = async (id: number) => {
    if (confirm("Are you sure you want to delete this employee?")) {
      try {
        await employeeService.deleteEmployee(id);
      } catch (err) {
        console.warn("Delete employee API fallback", err);
      }
      setEmployees((prev) => prev.filter((emp) => emp.id !== id));
    }
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!firstName || !email) {
      showAlert("warning", "Warning", "First Name and Email are required.");
      return;
    }

    const cid = selectedCompanyId || tokenCompanyId || companies[0]?.companyId;
    if (!cid) {
      showAlert("warning", "Warning", "Please select a company.");
      return;
    }

    const payload = {
      employeeId: editingId || 0,
      companyId: cid,
      employeeCode: code,
      firstName,
      middleName,
      lastName,
      email,
      password: password || "123456",
      mobileNo: phone,
      roleId: selectedRoleId || 0,
      departmentId: selectedDepartmentId || null,
      designationId: selectedDesignationId || null,
      branchIds: selectedBranches.map(Number),
    };

    if (editingId) {
      try {
        const res = await employeeService.updateEmployee(editingId, payload);
        if (res && res.success === false) {
          showAlert("error", "Error", res.message || "Failed to update employee.");
          return;
        }
        await fetchData();
        showAlert("success", "Success", "Employee updated successfully!");
      } catch (err) {
        console.warn("Update employee call fallback", err);
        showAlert("error", "Error", "Failed to update employee.");
        return;
      }
    } else {
      try {
        const res = await employeeService.createEmployee(payload);
        if (res && res.success === false) {
          showAlert("error", "Error", res.message || "Failed to create employee.");
          return;
        }
        await fetchData();
        showAlert("success", "Success", "Employee created successfully!");
      } catch (err) {
        console.warn("Create employee call fallback", err);
        showAlert("error", "Error", "Failed to create employee.");
        return;
      }
    }

    setShowModal(false);
  };

  const filteredEmployees = employees.filter((emp) => {
    return (
      emp.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      emp.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      emp.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (emp.departmentName && emp.departmentName.toLowerCase().includes(searchTerm.toLowerCase())) ||
      (emp.designationName && emp.designationName.toLowerCase().includes(searchTerm.toLowerCase()))
    );
  });

  return (
    <div>
      <PageBreadcrumb pageTitle="Employee Management" />
      <div className="space-y-6">
        <ComponentCard title="Company Wise Employee Directory">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between mb-6">
            <div className="w-full sm:w-72">
              <Input
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                placeholder="Search employees..."
              />
            </div>

            <Button
              onClick={handleOpenAdd}
              className="bg-brand-500 hover:bg-brand-600 text-white"
            >
              + Add Employee
            </Button>
          </div>

          <div className="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800">
            <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
              <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-700 dark:text-gray-200 font-semibold uppercase text-xs">
                <tr>
                  <th className="p-4">Code</th>
                  <th className="p-4">Employee Name</th>
                  <th className="p-4">Email / Phone</th>
                  <th className="p-4">Department</th>
                  <th className="p-4">Designation</th>
                  <th className="p-4">Role</th>
                  <th className="p-4">Status</th>
                  <th className="p-4">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-800">
                {loading ? (
                  <tr>
                    <td colSpan={8} className="p-8">
                      <Loader size="md" text="Loading employee directory..." />
                    </td>
                  </tr>
                ) : filteredEmployees.length > 0 ? (
                  filteredEmployees.map((emp) => (
                    <tr
                      key={emp.id}
                      className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30"
                    >
                      <td className="p-4 font-mono font-semibold text-brand-600 dark:text-brand-400">
                        {emp.code}
                      </td>
                      <td className="p-4 font-medium text-gray-900 dark:text-white">
                        {emp.name}
                      </td>
                      <td className="p-4">
                        <div>{emp.email}</div>
                        {emp.phone && <div className="text-xs text-gray-400">{emp.phone}</div>}
                      </td>
                      <td className="p-4">{emp.departmentName || "General"}</td>
                      <td className="p-4">{emp.designationName || "None"}</td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-blue-50 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400">
                          {emp.roleName}
                        </span>
                      </td>
                      <td className="p-4">
                        <span className="px-2.5 py-1 text-xs font-semibold rounded-full bg-emerald-50 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400">
                          {emp.status}
                        </span>
                      </td>
                      <td className="p-4">
                        <div className="flex items-center gap-3">
                          <button
                            onClick={() => handleOpenEdit(emp)}
                            className="text-sm font-medium text-brand-600 hover:text-brand-700 dark:text-brand-400"
                          >
                            Edit
                          </button>
                          <button
                            onClick={() => handleDelete(emp.id)}
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
                    <td
                      colSpan={8}
                      className="p-6 text-center text-gray-500 dark:text-gray-400"
                    >
                      No employees found for the current company token context.
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
              {editingId ? "Edit Employee" : "Add New Employee"}
            </h3>
            <form onSubmit={handleSave} className="space-y-4">
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <Label>First Name</Label>
                  <Input
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="e.g. Kavan"
                  />
                </div>
                <div>
                  <Label>Middle Name</Label>
                  <Input
                    value={middleName}
                    onChange={(e) => setMiddleName(e.target.value)}
                    placeholder="Optional"
                  />
                </div>
                <div>
                  <Label>Last Name</Label>
                  <Input
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="e.g. Solanki"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Email Address</Label>
                  <Input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="Enter email address"
                  />
                </div>
                <div>
                  <Label>{editingId ? "Password (Leave blank to keep)" : "Password"}</Label>
                  <Input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder={editingId ? "••••••••" : "Enter password"}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Employee Code</Label>
                  <Input
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    placeholder="e.g. EMP-OWNER"
                  />
                </div>
                <div>
                  <Label>Phone Number</Label>
                  <Input
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="Enter phone number"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Department</Label>
                  <Select
                    options={departmentOptions}
                    defaultValue={String(selectedDepartmentId || "")}
                    onChange={(val) => setSelectedDepartmentId(val ? Number(val) : null)}
                  />
                </div>
                <div>
                  <Label>Designation</Label>
                  <Select
                    options={designationOptions}
                    defaultValue={String(selectedDesignationId || "")}
                    onChange={(val) => setSelectedDesignationId(val ? Number(val) : null)}
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label>Role</Label>
                  <Select
                    options={roleOptions}
                    defaultValue={String(selectedRoleId || "")}
                    onChange={(val) => setSelectedRoleId(val ? Number(val) : null)}
                  />
                </div>
                <div className="z-20">
                  <MultiSelect
                    label="Branch"
                    options={branchOptions}
                    defaultSelected={selectedBranches}
                    onChange={(selected) => setSelectedBranches(selected)}
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-3">
                <Button
                  type="button"
                  onClick={() => setShowModal(false)}
                  variant="outline"
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  className="bg-brand-500 hover:bg-brand-600 text-white"
                >
                  {editingId ? "Update Employee" : "Save Employee"}
                </Button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
