namespace CallMatrix.DTO.Response.Role
{
    public class RoleResponse
    {
        public int RoleId { get; set; }
        public int CompanyId { get; set; }
        public string RoleName { get; set; } = string.Empty;
        public int RoleTypeId { get; set; }
        public string? Description { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
    }

    public class RolePermissionMatrixResponse
    {
        public int RoleId { get; set; }
        public string RoleName { get; set; } = string.Empty;
        public List<RolePermissionItemResponse> Permissions { get; set; } = new();
    }

    public class RolePermissionItemResponse
    {
        public int RolePermissionId { get; set; }
        public int MenuId { get; set; }
        public string MenuName { get; set; } = string.Empty;
        public int? ParentId { get; set; }
        public bool CanView { get; set; }
        public bool CanAdd { get; set; }
        public bool CanEdit { get; set; }
        public bool CanDelete { get; set; }
        public bool CanExport { get; set; }
        public bool CanPrint { get; set; }
        public bool CanApprove { get; set; }
    }
}
