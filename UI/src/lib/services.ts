import { apiClient } from './apiClient';
export { apiClient };

export interface LoginRequest {
  email: string;
  passwordHash: string;
}

export interface UserInfo {
  employeeId: number;
  companyId: number;
  roleId: number;
  roleName: string;
  employeeCode: string;
  employeeName: string;
  email: string;
  tenant: number;
  profileImageUrl?: string;
}

export interface LoginResponse {
  token: string;
  refreshToken: string;
  expiresAt: string;
  user: UserInfo;
}

export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
  errors?: string[];
  statusCode: number;
}

export interface MenuItem {
  menuId: number;
  companyId?: number;
  menuName: string;
  icon?: string;
  url?: string;
  parentId?: number;
  sortOrder: number;
  permissions: {
    canView: boolean;
    canAdd: boolean;
    canEdit: boolean;
    canDelete: boolean;
    canExport: boolean;
    canImport: boolean;
    canPrint: boolean;
    canUpload: boolean;
    canDownload: boolean;
    canApprove: boolean;
    canAssign: boolean;
  };
  children: MenuItem[];
}

export interface SignUpRequest {
  fullName: string;
  companyName: string;
  email: string;
  password: string;
}

export const authService = {
  login: async (credentials: LoginRequest): Promise<ApiResponse<LoginResponse>> => {
    try {
      const response = await apiClient.post<ApiResponse<LoginResponse>>('/auth/login', {
        email: credentials.email,
        password: credentials.passwordHash,
      });
      return response.data;
    } catch (error: any) {
      if (error.response?.data) {
        return error.response.data;
      }
      return {
        success: false,
        message: error.response?.data?.message || 'Invalid email or password',
        data: null as any,
        statusCode: error.response?.status || 401,
      };
    }
  },

  signUp: async (request: SignUpRequest): Promise<ApiResponse<boolean>> => {
    try {
      const payload = {
        ...request,
        roleId: null
      };
      const response = await apiClient.post<ApiResponse<boolean>>('/auth/signup', payload);
      return response.data;
    } catch (error: any) {
      if (error.response?.data) {
        return error.response.data;
      }
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to complete registration',
        data: false,
        statusCode: error.response?.status || 400,
      };
    }
  },

  logout: async (employeeId: number): Promise<ApiResponse<boolean>> => {
    try {
      const res = await apiClient.post<ApiResponse<boolean>>(`/auth/logout?employeeId=${employeeId}`);
      return res.data;
    } catch (error: any) {
      if (error.response?.data) {
        return error.response.data;
      }
      return {
        success: false,
        message: error.response?.data?.message || 'Failed to logout',
        data: false,
        statusCode: error.response?.status || 400,
      };
    }
  },
};

export const menuService = {
  getMenuTree: async (roleId: number | null, companyId: number): Promise<ApiResponse<MenuItem[]>> => {
    const url = roleId 
      ? `/menus/tree?roleId=${roleId}&companyId=${companyId}`
      : `/menus/tree?companyId=${companyId}`;
    const res = await apiClient.get<ApiResponse<MenuItem[]>>(url);
    return res.data;
  },
  getAllMenus: async () => {
    const res = await apiClient.get(`/menus`);
    return res.data;
  },
  createMenu: async (data: any) => {
    const res = await apiClient.post(`/menus`, data);
    return res.data;
  },
  updateMenu: async (data: any) => {
    const res = await apiClient.put(`/menus`, data);
    return res.data;
  },
  deleteMenu: async (id: number) => {
    const res = await apiClient.delete(`/menus/${id}`);
    return res.data;
  }
};

export const leadService = {
  getLeads: async (page = 1, pageSize = 10, search = '') => {
    const res = await apiClient.get(`/leads?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`);
    return res.data;
  },
  createLead: async (data: any) => {
    const res = await apiClient.post('/leads', data);
    return res.data;
  },
  convertLead: async (leadId: number) => {
    const res = await apiClient.post(`/leads/${leadId}/convert`);
    return res.data;
  },
  getTimeline: async (leadId: number) => {
    const res = await apiClient.get(`/leads/${leadId}/timeline`);
    return res.data;
  },
};

export const callService = {
  getCalls: async (page = 1, pageSize = 10, search = "", date?: string, callType?: string) => {
    let url = `/calls?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`;
    if (date) {
      url += `&date=${encodeURIComponent(date)}`;
    }
    if (callType && callType !== "All") {
      url += `&Filters[CallType]=${encodeURIComponent(callType)}`;
    }
    const res = await apiClient.get(url);
    return res.data;
  },
  getAnalytics: async (startDate?: string, endDate?: string) => {
    let url = '/calls/analytics';
    if (startDate && endDate) {
      url += `?startDate=${startDate}&endDate=${endDate}`;
    }
    const res = await apiClient.get(url);
    return res.data;
  },
  getDashboardSummary: async (date?: string, employeeId?: string | number) => {
    let url = "/calls/dashboard";
    const params = [];
    if (date) {
      params.push(`date=${encodeURIComponent(date)}`);
    }
    if (employeeId && employeeId !== "All") {
      params.push(`employeeId=${encodeURIComponent(employeeId.toString())}`);
    }
    if (params.length > 0) {
      url += `?${params.join("&")}`;
    }
    const res = await apiClient.get(url);
    return res.data;
  },
  getRecordings: async (page = 1, pageSize = 10, search = '', date = '') => {
    let url = `/calls/recordings?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`;
    if (date) {
      url += `&date=${encodeURIComponent(date)}`;
    }
    const res = await apiClient.get(url);
    return res.data;
  },
};

export const deviceService = {
  getDevices: async (page = 1, pageSize = 10, search = '') => {
    const res = await apiClient.get(`/devices?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`);
    return res.data;
  },
  approveDevice: async (userDeviceId: number, isApproved: boolean) => {
    const res = await apiClient.put('/devices/approve', { userDeviceId, isApproved });
    return res.data;
  },
  blockDevice: async (userDeviceId: number, isBlocked: boolean) => {
    const res = await apiClient.put('/devices/block', { userDeviceId, isBlocked });
    return res.data;
  },
};

export const employeeService = {
  getEmployees: async (page = 1, pageSize = 10, search = '', companyId?: number) => {
    try {
      let url = `/employees?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`;
      if (companyId) {
        url += `&companyId=${companyId}`;
      }
      const res = await apiClient.get(url);
      return res.data;
    } catch (error: any) {
      console.warn("getEmployees endpoint error:", error?.message);
      return { success: false, message: error?.message, data: [] };
    }
  },
  createEmployee: async (data: any) => {
    try {
      const res = await apiClient.post('/employees', data);
      return res.data;
    } catch (error: any) {
      console.warn("createEmployee endpoint error:", error?.message);
      const msg = error.response?.data?.message || error.response?.data?.Message || error.message;
      return { success: false, message: msg, data: null };
    }
  },
  updateEmployee: async (id: number, data: any) => {
    try {
      const res = await apiClient.put(`/employees/${id}`, data);
      return res.data;
    } catch (error: any) {
      console.warn("updateEmployee endpoint error:", error?.message);
      const msg = error.response?.data?.message || error.response?.data?.Message || error.message;
      return { success: false, message: msg, data: null };
    }
  },
  deleteEmployee: async (id: number) => {
    try {
      const res = await apiClient.delete(`/employees/${id}`);
      return res.data;
    } catch (error: any) {
      console.warn("deleteEmployee endpoint error:", error?.message);
      return { success: false, message: error?.message, data: false };
    }
  },
};

export const companyService = {
  getCompanies: async () => {
    try {
      if (typeof window !== 'undefined') {
        const userJson = localStorage.getItem('user');
        if (userJson) {
          const user = JSON.parse(userJson);
          return {
            success: true,
            data: [{
              companyId: Number(user.companyId || user.CompanyId || 3),
              companyName: user.companyName || user.CompanyName || "Kavan Solanki Enterprise"
            }]
          };
        }
      }
      return { success: true, data: [{ companyId: 3, companyName: "Kavan Solanki Enterprise" }] };
    } catch (error: any) {
      return { success: false, message: error?.message, data: [] };
    }
  },
};

export const departmentService = {
  getDepartments: async (page = 1, pageSize = 10, search = '', companyId?: number) => {
    try {
      let url = `/departments?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`;
      if (companyId) {
        url += `&companyId=${companyId}`;
      }
      const res = await apiClient.get(url);
      return res.data;
    } catch (error: any) {
      console.warn("getDepartments endpoint error:", error?.message);
      return { success: false, message: error?.message, data: [] };
    }
  },
  createDepartment: async (data: any) => {
    try {
      const res = await apiClient.post('/departments', data);
      return res.data;
    } catch (error: any) {
      console.warn("createDepartment endpoint error:", error?.message);
      return { success: false, message: error?.message, data: null };
    }
  },
  updateDepartment: async (id: number, data: any) => {
    try {
      const res = await apiClient.put(`/departments/${id}`, data);
      return res.data;
    } catch (error: any) {
      console.warn("updateDepartment endpoint error:", error?.message);
      return { success: false, message: error?.message, data: null };
    }
  },
  deleteDepartment: async (id: number) => {
    try {
      const res = await apiClient.delete(`/departments/${id}`);
      return res.data;
    } catch (error: any) {
      console.warn("deleteDepartment endpoint error:", error?.message);
      return { success: false, message: error?.message, data: false };
    }
  },
};

export const designationService = {
  getDesignations: async (page = 1, pageSize = 10, search = '', companyId?: number) => {
    try {
      let url = `/designations?page=${page}&pageSize=${pageSize}&search=${encodeURIComponent(search)}`;
      if (companyId) {
        url += `&companyId=${companyId}`;
      }
      const res = await apiClient.get(url);
      return res.data;
    } catch (error: any) {
      console.warn("getDesignations endpoint error:", error?.message);
      return { success: false, message: error?.message, data: [] };
    }
  },
  createDesignation: async (data: any) => {
    try {
      const res = await apiClient.post('/designations', data);
      return res.data;
    } catch (error: any) {
      console.warn("createDesignation endpoint error:", error?.message);
      return { success: false, message: error?.message, data: null };
    }
  },
  updateDesignation: async (id: number, data: any) => {
    try {
      const res = await apiClient.put(`/designations/${id}`, data);
      return res.data;
    } catch (error: any) {
      console.warn("updateDesignation endpoint error:", error?.message);
      return { success: false, message: error?.message, data: null };
    }
  },
  deleteDesignation: async (id: number) => {
    try {
      const res = await apiClient.delete(`/designations/${id}`);
      return res.data;
    } catch (error: any) {
      console.warn("deleteDesignation endpoint error:", error?.message);
      return { success: false, message: error?.message, data: false };
    }
  },
};

export const roleService = {
  getRoles: async () => {
    const res = await apiClient.get('/roles');
    return res.data;
  },
  createRole: async (data: any) => {
    const res = await apiClient.post('/roles', data);
    return res.data;
  },
  updateRole: async (data: any) => {
    const res = await apiClient.put('/roles', data);
    return res.data;
  },
  deleteRole: async (id: number) => {
    const res = await apiClient.delete(`/roles/${id}`);
    return res.data;
  },
  getPermissions: async (roleId: number) => {
    const res = await apiClient.get(`/roles/${roleId}/permissions`);
    return res.data;
  },
  updatePermissions: async (data: any) => {
    const res = await apiClient.put('/roles/permissions', data);
    return res.data;
  },
};

export const enumService = {
  getEnums: async (categoryId: number) => {
    try {
      const response = await apiClient.get(`/enums/${categoryId}`);
      return response.data;
    } catch (error) {
      console.error("Failed to fetch enums", error);
      return { success: false, data: [] };
    }
  }
};
