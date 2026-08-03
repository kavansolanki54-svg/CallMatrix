using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class EmployeeBranch
{
    public int EmployeeBranchId { get; set; }

    public int EmployeeId { get; set; }

    public int BranchId { get; set; }

    public bool IsPrimaryBranch { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual BranchMaster Branch { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual EmployeeMaster Employee { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
