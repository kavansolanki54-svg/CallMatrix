namespace Callalyze.DTO.Request.Role
{
    public class CreateRoleRequest
    {
        public int CompanyId { get; set; }
        public string RoleName { get; set; } = string.Empty;
        public int RoleTypeId { get; set; }
        public string? Description { get; set; }
    }

    public class UpdateRoleRequest
    {
        public int RoleId { get; set; }
        public string RoleName { get; set; } = string.Empty;
        public int RoleTypeId { get; set; }
        public string? Description { get; set; }
    }

    public class UpdateRolePermissionsRequest
    {
        public int RoleId { get; set; }
        public List<RolePermissionItemRequest> Permissions { get; set; } = new();
    }

    public class RolePermissionItemRequest
    {
        public int MenuId { get; set; }
        public bool CanView { get; set; }
        public bool CanAdd { get; set; }
        public bool CanEdit { get; set; }
        public bool CanDelete { get; set; }
        public bool CanExport { get; set; }
        public bool CanPrint { get; set; }
        public bool CanApprove { get; set; }
    }
}
