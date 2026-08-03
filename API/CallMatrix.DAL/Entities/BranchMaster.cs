using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class BranchMaster
{
    public int BranchId { get; set; }

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

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<EmployeeBranch> EmployeeBranches { get; set; } = new List<EmployeeBranch>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
