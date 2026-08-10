namespace Callalyze.DTO.Request.Organization
{
    public class CreateDesignationRequest
    {
        public int CompanyId { get; set; }
        public int DepartmentId { get; set; } // Will default to 0 if not provided
        public string DesignationName { get; set; } = null!;
        public string? Description { get; set; }
    }

    public class UpdateDesignationRequest : CreateDesignationRequest
    {
    }
}
