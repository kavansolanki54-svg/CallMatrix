namespace CallMatrix.DTO.Request.Organization
{
    public class CreateDepartmentRequest
    {
        public int CompanyId { get; set; }
        public string DepartmentName { get; set; } = null!;
        public string? DepartmentCode { get; set; }
    }

    public class UpdateDepartmentRequest : CreateDepartmentRequest
    {
    }
}
