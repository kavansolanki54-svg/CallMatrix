namespace CallMatrix.DTO.Response.Organization
{
    public class DesignationResponse
    {
        public int DesignationId { get; set; }
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
        public int DepartmentId { get; set; }
        public string DesignationName { get; set; } = null!;
        public string? Description { get; set; }
        public int EmployeeCount { get; set; }
        public bool IsActive { get; set; }
    }
}
