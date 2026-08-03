namespace CallMatrix.DTO.Response.Organization
{
    public class DepartmentResponse
    {
        public int DepartmentId { get; set; }
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
        public string DepartmentName { get; set; } = null!;
        public string? DepartmentCode { get; set; }
        public int EmployeeCount { get; set; }
        public bool IsActive { get; set; }
    }
}
