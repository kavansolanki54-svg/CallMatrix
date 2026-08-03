using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class RolePermission
{
    public int PermissionId { get; set; }

    public int RoleId { get; set; }

    public int MenuId { get; set; }

    public bool CanView { get; set; }

    public bool CanAdd { get; set; }

    public bool CanEdit { get; set; }

    public bool CanDelete { get; set; }

    public bool CanExport { get; set; }

    public bool CanImport { get; set; }

    public bool CanPrint { get; set; }

    public bool CanUpload { get; set; }

    public bool CanDownload { get; set; }

    public bool CanApprove { get; set; }

    public bool CanAssign { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual MenuMaster Menu { get; set; } = null!;

    public virtual RoleMaster Role { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
