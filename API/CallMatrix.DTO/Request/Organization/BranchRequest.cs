namespace CallMatrix.DTO.Request.Organization
{
    public class CreateBranchRequest
    {
        public int CompanyId { get; set; }
        public string BranchName { get; set; } = null!;
        public string? BranchCode { get; set; }
        public string? Address { get; set; }
        public string? Country { get; set; }
        public string? State { get; set; }
        public string? City { get; set; }
        public string? Pincode { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
    }

    public class UpdateBranchRequest : CreateBranchRequest
    {
    }
}
