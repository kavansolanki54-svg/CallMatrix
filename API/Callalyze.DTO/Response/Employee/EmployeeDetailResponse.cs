namespace Callalyze.DTO.Response.Employee
{
    public class EmployeeDetailResponse
    {
        public int EmployeeId { get; set; }
        public int CompanyId { get; set; }
        public string EmployeeCode { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string? MiddleName { get; set; }
        public string? LastName { get; set; }
        public string EmployeeName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string MobileNo { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public string? RoleName { get; set; }
        public int? DepartmentId { get; set; }
        public string? DepartmentName { get; set; }
        public int? DesignationId { get; set; }
        public string? DesignationName { get; set; }
        public int Tenant { get; set; }
        public List<int> AssignedBranchIds { get; set; } = new();
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
    }
}
