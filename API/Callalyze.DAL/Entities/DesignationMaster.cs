using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class DesignationMaster
{
    public int DesignationId { get; set; }

    public int CompanyId { get; set; }

    public int DepartmentId { get; set; }

    public string DesignationName { get; set; } = null!;

    public string? Description { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual DepartmentMaster Department { get; set; } = null!;

    public virtual ICollection<EmployeeMaster> EmployeeMasters { get; set; } = new List<EmployeeMaster>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
