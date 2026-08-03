namespace CallMatrix.DTO.Response.Menu
{
    public class MenuTreeResponse
    {
        public int MenuId { get; set; }
        public int? CompanyId { get; set; }
        public string MenuName { get; set; } = string.Empty;
        public string? Icon { get; set; }
        public string? Url { get; set; }
        public int? ParentId { get; set; }
        public int SortOrder { get; set; }
        public MenuPermissionDto Permissions { get; set; } = new();
        public List<MenuTreeResponse> Children { get; set; } = new();
    }

    public class MenuPermissionDto
    {
        public bool CanView { get; set; }
        public bool CanAdd { get; set; }
        public bool CanEdit { get; set; }
        public bool CanDelete { get; set; }
        public bool CanExport { get; set; }
        public bool CanImport { get; set; }
        public bool CanPrint { get; set; }
        public bool CanUpload { get; set; }
        public bool CanDownload { get; set; }
        public bool CanApprove { get; set; }
        public bool CanAssign { get; set; }
    }
}
