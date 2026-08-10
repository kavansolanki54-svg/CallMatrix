using System;
using System.Collections.Generic;

namespace Callalyze.DAL.Entities;

public partial class CallRecording
{
    public int CallRecordingId { get; set; }

    public int CompanyId { get; set; }

    public int CallId { get; set; }

    public string FileName { get; set; } = null!;

    public string? FilePath { get; set; }

    public string? FileUrl { get; set; }

    public int? Duration { get; set; }

    public long? FileSize { get; set; }

    public string UploadStatus { get; set; } = null!;

    public DateTime? RecordingDate { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? CreatedBy { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? UpdatedBy { get; set; }

    public bool IsActive { get; set; }

    public Guid Guids { get; set; }

    public virtual CallMaster Call { get; set; } = null!;

    public virtual CompanyMaster Company { get; set; } = null!;

    public virtual EmployeeMaster? CreatedByNavigation { get; set; }

    public virtual EmployeeMaster? UpdatedByNavigation { get; set; }

    public string? AiSummary { get; set; }
}
