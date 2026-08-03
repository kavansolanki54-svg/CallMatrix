using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class AuditLog
{
    public int AuditLogId { get; set; }

    public int? CompanyId { get; set; }

    public string TableName { get; set; } = null!;

    public int? RecordId { get; set; }

    public string Action { get; set; } = null!;

    public string? OldValues { get; set; }

    public string? NewValues { get; set; }

    public int? EmployeeId { get; set; }

    public DateTime Timestamp { get; set; }

    public virtual CompanyMaster? Company { get; set; }

    public virtual EmployeeMaster? Employee { get; set; }
}
