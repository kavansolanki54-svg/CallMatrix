using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class RoleMaster
{
    public int RoleId { get; set; }

    public int CompanyId { get; set; }

    public string RoleName { get; set; } = null!;

    public int RoleTypeId { get; set; }

    public string? Description { get; set; }

    public bool IsSystem { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<EmployeeMaster> EmployeeMasters { get; set; } = new List<EmployeeMaster>();

    public virtual ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();

    public virtual EnumMaster RoleType { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
