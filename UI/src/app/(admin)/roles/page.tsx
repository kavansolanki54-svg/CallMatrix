"use client";
import React, { useEffect, useState } from "react";
import { roleService, enumService } from "@/lib/services";
import { Plus, Edit2, Trash2, Shield, Search } from "lucide-react";
import InputField from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Button from "@/components/ui/button/Button";
import { Modal } from "@/components/ui/modal";
import Select from "@/components/form/Select";
import { useAlert } from "@/context/AlertContext";

interface Role {
  roleId: number;
  companyId: number;
  roleName: string;
  roleTypeId: number;
  description?: string;
  isActive: boolean;
  createdAt: string;
}

export default function RolesPage() {
  const [roles, setRoles] = useState<Role[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingRole, setEditingRole] = useState<Role | null>(null);
  const [roleTypes, setRoleTypes] = useState<{value: string, label: string}[]>([]);
  const { showAlert } = useAlert();

  const [formData, setFormData] = useState({
    roleName: "",
    roleTypeId: 8,
    description: "",
  });

  const fetchRoles = async () => {
    setLoading(true);
    try {
      const res = await roleService.getRoles();
      if (res?.success) {
        setRoles(res.data);
      } else if (Array.isArray(res)) {
        setRoles(res);
      }
    } catch (err) {
      console.error("Failed to load roles", err);
    } finally {
      setLoading(false);
    }
  };

  const fetchRoleTypes = async () => {
    const res = await enumService.getEnums(2);
    if (res?.success) {
      setRoleTypes(res.data);
    }
  };

  useEffect(() => {
    fetchRoles();
    fetchRoleTypes();
  }, []);

  const handleOpenModal = (role?: Role) => {
    if (role) {
      setEditingRole(role);
      setFormData({
        roleName: role.roleName,
        roleTypeId: role.roleTypeId || 8,
        description: role.description || "",
      });
    } else {
      setEditingRole(null);
      setFormData({
        roleName: "",
        roleTypeId: 8,
        description: "",
      });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingRole(null);
  };

  const handleSave = async () => {
    try {
      if (editingRole) {
        await roleService.updateRole({ ...formData, roleId: editingRole.roleId });
      } else {
        await roleService.createRole(formData);
      }
      handleCloseModal();
      fetchRoles();
      showAlert("success", "Success", "Role saved successfully!");
    } catch (err) {
      console.error("Failed to save role", err);
      showAlert("error", "Error", "Error saving role");
    }
  };

  const handleDelete = async (id: number) => {
    if (confirm("Are you sure you want to delete this role?")) {
      try {
        await roleService.deleteRole(id);
        fetchRoles();
        showAlert("success", "Success", "Role deleted successfully!");
      } catch (err) {
        console.error("Failed to delete role", err);
        showAlert("error", "Error", "Error deleting role");
      }
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <Shield className="w-6 h-6 text-brand-500" />
            Role Master
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Manage user roles and profiles</p>
        </div>
        <Button onClick={() => handleOpenModal()} className="flex items-center gap-2">
          <Plus className="w-4 h-4" /> Add Role
        </Button>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden shadow-sm">
        <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
          <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-400 font-semibold uppercase text-xs">
            <tr>
              <th className="px-6 py-4">Role Name</th>
              <th className="px-6 py-4">Role Type</th>
              <th className="px-6 py-4">Description</th>
              <th className="px-6 py-4 text-center">Status</th>
              <th className="px-6 py-4 text-center">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {loading ? (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center text-gray-400">Loading roles...</td>
              </tr>
            ) : roles.length > 0 ? (
              roles.map((role) => (
                <tr key={role.roleId} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition">
                  <td className="px-6 py-4 font-semibold text-gray-900 dark:text-white">
                    {role.roleName}
                  </td>
                  <td className="px-6 py-4 text-brand-600 dark:text-brand-400 font-medium">
                    {roleTypes.find(t => Number(t.value) === role.roleTypeId)?.label || `Type ${role.roleTypeId}`}
                  </td>
                  <td className="px-6 py-4">{role.description || "-"}</td>
                  <td className="px-6 py-4 text-center">
                    <span
                      className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${
                        role.isActive
                          ? "bg-success-50 text-success-700 dark:bg-success-900/20 dark:text-success-400"
                          : "bg-error-50 text-error-700 dark:bg-error-900/20 dark:text-error-400"
                      }`}
                    >
                      {role.isActive ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-center space-x-3">
                    <button onClick={() => handleOpenModal(role)} className="text-gray-400 hover:text-brand-500 transition">
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button onClick={() => handleDelete(role.roleId)} className="text-gray-400 hover:text-error-500 transition">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={5} className="px-6 py-8 text-center text-gray-400">No roles found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <Modal isOpen={isModalOpen} onClose={handleCloseModal} className="max-w-lg p-6">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6">
          {editingRole ? "Edit Role" : "Add Role"}
        </h2>
        <div className="space-y-4">
          <div>
            <Label>Role Name</Label>
            <InputField
              type="text"
              placeholder="e.g., HR Manager"
              value={formData.roleName}
              onChange={(e) => setFormData({ ...formData, roleName: e.target.value })}
            />
          </div>
          <div>
            <Label>Role Type</Label>
            <Select
              options={roleTypes}
              defaultValue={String(formData.roleTypeId)}
              onChange={(val) => setFormData({ ...formData, roleTypeId: parseInt(val) })}
            />
          </div>
          <div>
            <Label>Description</Label>
            <textarea
              className="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:ring-2 focus:ring-brand-500 focus:outline-none transition-colors text-sm dark:text-white resize-none"
              rows={3}
              placeholder="e.g., Has full access to HR modules."
              value={formData.description}
              onChange={(e) => setFormData({ ...formData, description: e.target.value })}
            />
          </div>

          <div className="flex justify-end gap-3 mt-8">
            <Button variant="outline" onClick={handleCloseModal}>
              Cancel
            </Button>
            <Button onClick={handleSave}>Save Role</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
