"use client";
import React, { useEffect, useState } from "react";
import { menuService } from "@/lib/services";
import { Plus, Edit2, Trash2, ListTree, FolderTree } from "lucide-react";
import InputField from "@/components/form/input/InputField";
import Label from "@/components/form/Label";
import Button from "@/components/ui/button/Button";
import { Modal } from "@/components/ui/modal";

interface Menu {
  menuId: number;
  menuName: string;
  icon?: string;
  url?: string;
  parentId?: number;
  parentName?: string;
  sortOrder: number;
  isActive: boolean;
}

export default function MenusPage() {
  const [menus, setMenus] = useState<Menu[]>([]);
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingMenu, setEditingMenu] = useState<Menu | null>(null);

  const [formData, setFormData] = useState({
    menuName: "",
    icon: "",
    url: "",
    parentId: "",
    sortOrder: 0,
    isActive: true,
  });

  const fetchMenus = async () => {
    setLoading(true);
    try {
      const res = await menuService.getAllMenus();
      if (res?.success) {
        setMenus(res.data);
      } else if (Array.isArray(res)) {
        setMenus(res);
      }
    } catch (err) {
      console.error("Failed to load menus", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMenus();
  }, []);

  const handleOpenModal = (menu?: Menu) => {
    if (menu) {
      setEditingMenu(menu);
      setFormData({
        menuName: menu.menuName,
        icon: menu.icon || "",
        url: menu.url || "",
        parentId: menu.parentId ? menu.parentId.toString() : "",
        sortOrder: menu.sortOrder,
        isActive: menu.isActive,
      });
    } else {
      setEditingMenu(null);
      setFormData({
        menuName: "",
        icon: "",
        url: "",
        parentId: "",
        sortOrder: menus.length + 1,
        isActive: true,
      });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setEditingMenu(null);
  };

  const handleSave = async () => {
    try {
      const payload = {
        ...formData,
        parentId: formData.parentId ? parseInt(formData.parentId) : null,
        sortOrder: parseInt(formData.sortOrder.toString()),
      };

      if (editingMenu) {
        await menuService.updateMenu({ ...payload, menuId: editingMenu.menuId });
      } else {
        await menuService.createMenu(payload);
      }
      handleCloseModal();
      fetchMenus();
    } catch (err) {
      console.error("Failed to save menu", err);
      alert("Error saving menu");
    }
  };

  const handleDelete = async (id: number) => {
    if (confirm("Are you sure you want to delete this menu?")) {
      try {
        await menuService.deleteMenu(id);
        fetchMenus();
      } catch (err) {
        console.error("Failed to delete menu", err);
        alert("Error deleting menu");
      }
    }
  };

  const parentOptions = menus.filter((m) => m.parentId == null || m.parentId === undefined).map(m => ({
    label: m.menuName,
    value: m.menuId.toString()
  }));

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <ListTree className="w-6 h-6 text-brand-500" />
            Menu Master
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400">Manage application menus and hierarchy</p>
        </div>
        <Button onClick={() => handleOpenModal()} className="flex items-center gap-2">
          <Plus className="w-4 h-4" /> Add Menu
        </Button>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-100 dark:border-gray-800 overflow-hidden shadow-sm">
        <table className="w-full text-left text-sm text-gray-600 dark:text-gray-300">
          <thead className="bg-gray-50 dark:bg-gray-800/50 text-gray-400 font-semibold uppercase text-xs">
            <tr>
              <th className="px-6 py-4">Menu Name</th>
              <th className="px-6 py-4">Icon</th>
              <th className="px-6 py-4">URL / Route</th>
              <th className="px-6 py-4">Parent</th>
              <th className="px-6 py-4">Sort Order</th>
              <th className="px-6 py-4 text-center">Status</th>
              <th className="px-6 py-4 text-center">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
            {loading ? (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center text-gray-400">Loading menus...</td>
              </tr>
            ) : menus.length > 0 ? (
              menus.map((menu) => (
                <tr key={menu.menuId} className="hover:bg-gray-50/50 dark:hover:bg-gray-800/30 transition">
                  <td className="px-6 py-4 font-semibold text-gray-900 dark:text-white flex items-center gap-2">
                    {menu.parentId ? <FolderTree className="w-4 h-4 text-gray-400 ml-4" /> : null}
                    {menu.menuName}
                  </td>
                  <td className="px-6 py-4">{menu.icon || "-"}</td>
                  <td className="px-6 py-4 font-mono text-xs text-brand-500">{menu.url || "-"}</td>
                  <td className="px-6 py-4">
                    {menu.parentName ? (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-300">
                        {menu.parentName}
                      </span>
                    ) : (
                      "-"
                    )}
                  </td>
                  <td className="px-6 py-4">{menu.sortOrder}</td>
                  <td className="px-6 py-4 text-center">
                    <span
                      className={`inline-flex px-2 py-1 rounded-full text-xs font-medium ${menu.isActive
                        ? "bg-success-50 text-success-700 dark:bg-success-900/20 dark:text-success-400"
                        : "bg-error-50 text-error-700 dark:bg-error-900/20 dark:text-error-400"
                        }`}
                    >
                      {menu.isActive ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-center space-x-3">
                    <button onClick={() => handleOpenModal(menu)} className="text-gray-400 hover:text-brand-500 transition">
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button onClick={() => handleDelete(menu.menuId)} className="text-gray-400 hover:text-error-500 transition">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={7} className="px-6 py-8 text-center text-gray-400">No menus found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      <Modal isOpen={isModalOpen} onClose={handleCloseModal} className="max-w-lg p-6">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6">
          {editingMenu ? "Edit Menu" : "Add Menu"}
        </h2>
        <div className="space-y-4">
          <div>
            <Label>Menu Name</Label>
            <InputField
              type="text"
              placeholder="e.g., Dashboard"
              value={formData.menuName}
              onChange={(e) => setFormData({ ...formData, menuName: e.target.value })}
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Label>Icon (Lucide React)</Label>
              <InputField
                type="text"
                placeholder="e.g., LayoutDashboard"
                value={formData.icon}
                onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
              />
            </div>
            <div>
              <Label>Sort Order</Label>
              <InputField
                type="number"
                value={formData.sortOrder}
                onChange={(e) => setFormData({ ...formData, sortOrder: parseInt(e.target.value) || 0 })}
              />
            </div>
          </div>
          <div>
            <Label>Route URL</Label>
            <InputField
              type="text"
              placeholder="e.g., /dashboard"
              value={formData.url}
              onChange={(e) => setFormData({ ...formData, url: e.target.value })}
            />
          </div>
          <div>
            <Label>Parent Menu (Optional)</Label>
            <select
              className="w-full px-4 py-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-xl focus:ring-2 focus:ring-brand-500 focus:outline-none transition-colors text-sm dark:text-white"
              value={formData.parentId}
              onChange={(e) => setFormData({ ...formData, parentId: e.target.value })}
            >
              <option value="">None (Top Level)</option>
              {parentOptions.map((opt) => (
                <option key={opt.value} value={opt.value}>
                  {opt.label}
                </option>
              ))}
            </select>
          </div>

          {editingMenu && (
            <div className="flex items-center gap-2 mt-2">
              <input
                type="checkbox"
                id="isActive"
                checked={formData.isActive}
                onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                className="w-4 h-4 rounded text-brand-500 bg-gray-100 border-gray-300 dark:bg-gray-800 dark:border-gray-700 focus:ring-brand-500 focus:ring-2"
              />
              <Label>Active Status</Label>
            </div>
          )}

          <div className="flex justify-end gap-3 mt-8">
            <Button variant="outline" onClick={handleCloseModal}>
              Cancel
            </Button>
            <Button onClick={handleSave}>Save Menu</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
