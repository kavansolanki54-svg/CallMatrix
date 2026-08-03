using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class RefreshToken
{
    public int RefreshTokenId { get; set; }

    public int CompanyId { get; set; }

    public int EmployeeId { get; set; }

    public string Token { get; set; } = null!;

    public DateTime ExpiresAt { get; set; }

    public DateTime? RevokedAt { get; set; }

    public bool IsRevoked { get; set; }

    public string? CreatedByIp { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual EmployeeMaster Employee { get; set; } = null!;

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
