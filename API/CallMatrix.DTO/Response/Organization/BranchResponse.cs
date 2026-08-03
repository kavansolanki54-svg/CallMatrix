namespace CallMatrix.DTO.Response.Organization
{
    public class BranchResponse
    {
        public int BranchId { get; set; }
        public int CompanyId { get; set; }
        public string CompanyName { get; set; } = null!;
        public string BranchName { get; set; } = null!;
        public string? BranchCode { get; set; }
        public string? Address { get; set; }
        public string? Country { get; set; }
        public string? State { get; set; }
        public string? City { get; set; }
        public string? Pincode { get; set; }
        public string? Phone { get; set; }
        public string? Email { get; set; }
        public bool IsActive { get; set; }
    }
}
