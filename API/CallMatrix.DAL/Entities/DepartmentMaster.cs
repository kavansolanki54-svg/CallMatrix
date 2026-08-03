using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class DepartmentMaster
{
    public int DepartmentId { get; set; }

    public int CompanyId { get; set; }

    public string DepartmentName { get; set; } = null!;

    public string? DepartmentCode { get; set; }

    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<DesignationMaster> DesignationMasters { get; set; } = new List<DesignationMaster>();

    public virtual ICollection<EmployeeMaster> EmployeeMasters { get; set; } = new List<EmployeeMaster>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
