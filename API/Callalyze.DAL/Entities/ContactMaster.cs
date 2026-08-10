using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class ContactMaster
{
    public int ContactId { get; set; }

    public int CompanyId { get; set; }

    public int? CustomerId { get; set; }

    public string FirstName { get; set; } = null!;

    public string? LastName { get; set; }

    public string? Email { get; set; }

    public string? Phone { get; set; }

    public string? Designation { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual CustomerMaster? Customer { get; set; }

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
