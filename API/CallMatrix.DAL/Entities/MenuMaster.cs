using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class MenuMaster
{
    public int MenuId { get; set; }

    public int? CompanyId { get; set; }

    public string MenuName { get; set; } = null!;

    public string? Icon { get; set; }

    public string? Url { get; set; }

    public int? ParentId { get; set; }

    public int SortOrder { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster? Company { get; set; }

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual ICollection<MenuMaster> InverseParent { get; set; } = new List<MenuMaster>();

    public virtual MenuMaster? Parent { get; set; }

    public virtual ICollection<RolePermission> RolePermissions { get; set; } = new List<RolePermission>();

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
