using System;
using System.Collections.Generic;

namespace CallMatrix.DAL.Entities;

public partial class NoteMaster
{
    public int NoteId { get; set; }

    public int CompanyId { get; set; }

    public int? LeadId { get; set; }

    public int? CustomerId { get; set; }

    public string Content { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual CustomerMaster? Customer { get; set; }

    public virtual LeadMaster? Lead { get; set; }

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }
}
