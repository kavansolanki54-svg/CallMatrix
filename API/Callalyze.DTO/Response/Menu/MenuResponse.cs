namespace Callalyze.DTO.Response.Menu
{
    public class MenuResponse
    {
        public int MenuId { get; set; }
        public int? CompanyId { get; set; }
        public string MenuName { get; set; } = string.Empty;
        public string? Icon { get; set; }
        public string? Url { get; set; }
        public int? ParentId { get; set; }
        public string? ParentName { get; set; }
        public int SortOrder { get; set; }
        public bool IsActive { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
