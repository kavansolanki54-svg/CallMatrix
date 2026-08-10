using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class ErrorLog
{
    public int ErrorLogId { get; set; }

    public int? CompanyId { get; set; }

    public int? EmployeeId { get; set; }

    public string ErrorMessage { get; set; } = null!;

    public string? StackTrace { get; set; }

    public string? Path { get; set; }

    public string? Method { get; set; }

    public string? QueryString { get; set; }

    public string? Ipaddress { get; set; }

    public string? UserAgent { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster? Company { get; set; }

    public virtual EmployeeMaster? Employee { get; set; }
}
