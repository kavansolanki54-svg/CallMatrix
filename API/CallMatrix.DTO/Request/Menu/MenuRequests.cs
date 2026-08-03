namespace CallMatrix.DTO.Request.Menu
{
    public class CreateMenuRequest
    {
        public int? CompanyId { get; set; }
        public string MenuName { get; set; } = string.Empty;
        public string? Icon { get; set; }
        public string? Url { get; set; }
        public int? ParentId { get; set; }
        public int SortOrder { get; set; }
    }

    public class UpdateMenuRequest
    {
        public int MenuId { get; set; }
        public string MenuName { get; set; } = string.Empty;
        public string? Icon { get; set; }
        public string? Url { get; set; }
        public int? ParentId { get; set; }
        public int SortOrder { get; set; }
        public bool IsActive { get; set; }
    }
}
