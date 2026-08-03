namespace CallMatrix.DTO.Request.Employee
{
    public class CreateEmployeeRequest
    {
        public int CompanyId { get; set; }
        public string EmployeeCode { get; set; } = string.Empty;
        public string FirstName { get; set; } = string.Empty;
        public string? MiddleName { get; set; }
        public string? LastName { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string MobileNo { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public int? DepartmentId { get; set; }
        public int? DesignationId { get; set; }
        public List<int> BranchIds { get; set; } = new();
    }

    public class UpdateEmployeeRequest
    {
        public int EmployeeId { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string? MiddleName { get; set; }
        public string? LastName { get; set; }
        public string Email { get; set; } = string.Empty;
        public string MobileNo { get; set; } = string.Empty;
        public int RoleId { get; set; }
        public int? DepartmentId { get; set; }
        public int? DesignationId { get; set; }
        public List<int> BranchIds { get; set; } = new();
    }

    public class AssignEmployeeBranchesRequest
    {
        public int EmployeeId { get; set; }
        public List<int> BranchIds { get; set; } = new();
    }
}
